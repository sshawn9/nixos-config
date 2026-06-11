"""Hourly context summarizer.

Pulls the last hour of events from ActivityWatch, Atuin, and Screenpipe
(optional), asks a local Ollama model to write a Markdown timeline, and
appends the result to `_Current_Context.md` in a configurable output dir.

All data sources are best-effort: missing/unreachable sources are skipped
with a diagnostic line in the generated Markdown rather than aborting.

Configuration is read from environment variables (set by the systemd unit):

    CONTEXT_SUMMARIZER_OUTPUT_DIR      Directory to write _Current_Context.md
    CONTEXT_SUMMARIZER_LOOKBACK_SEC    Seconds of history to summarize (3600)
    CONTEXT_SUMMARIZER_AW_URL          ActivityWatch base URL
    CONTEXT_SUMMARIZER_OLLAMA_URL      Ollama base URL
    CONTEXT_SUMMARIZER_OLLAMA_MODEL    Ollama model name
    CONTEXT_SUMMARIZER_SCREENPIPE_URL  Optional Screenpipe base URL
    CONTEXT_SUMMARIZER_SCREENPIPE_BIN  Optional Screenpipe CLI path
    CONTEXT_SUMMARIZER_SCREENPIPE_TOKEN
                                      Optional Screenpipe Bearer token
    CONTEXT_SUMMARIZER_ATUIN_BIN       Path to atuin binary
"""

# ── Phase D：context-summarizer 主体逻辑（中文补注）─────────────────
# 架构决策：
#   1. 仅用 stdlib（urllib/subprocess/json），零第三方依赖。这样 Nix 包
#      装层 libraries = [ ]，不需要维护 pyproject / requirements / lock。
#   2. 所有外部数据源 best-effort：网络失败、服务未起、返回非 JSON 都
#      用一条诊断字符串替代正常数据，整个脚本仍能跑完、写出 markdown。
#      不 abort 的理由：如果 ollama 挂了但 AW + Atuin 正常，用户至少
#      应该能从 markdown 里看到原始事件列表（即便没 LLM 总结）。
#   3. 配置走环境变量而非命令行参数：跟 systemd Environment= 天然契合，
#      改 nix 配置后不用动 Python 代码。

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path


# HTTP_TIMEOUT: GET 请求统一 10 秒 hard timeout。ActivityWatch / Screenpipe
# 本地服务应该几十 ms 响应，10s 是极度宽容的上限；超时多半说明服务挂了。
# Ollama 生成走单独的 60s timeout（见 http_post_json），因为 LLM 生成时
# 间长，7B 模型 CPU 推理可能要十几秒，10s 不够。
HTTP_TIMEOUT = 10


def http_get_json(url: str) -> object | None:
    # 捕获三类错误："连不上"(URLError 含 ConnectionRefused / DNS 失败)、
    # "读超时"(TimeoutError)、"返回非 JSON"(JSONDecodeError)。
    # 一律返回 None 让调用方知道"这个源没拿到数据"，调用方再把这个状
    # 态转换成 markdown 里的诊断字符串。
    data, _ = http_get_json_with_details(url)
    return data


def http_get_json_with_details(
    url: str, headers: dict[str, str] | None = None
) -> tuple[object | None, str | None]:
    # Screenpipe 的 /search 可能要求 Authorization 头；这里单独做一个
    # 带细节的 GET helper，让调用方区分 "连不上" 和 "403 未授权"。
    req = urllib.request.Request(url, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as resp:
            raw = resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        detail = f"HTTP {exc.code} {exc.reason}"
        if body.strip():
            detail += f"; body={shorten_for_log(body)}"
        return None, detail
    except urllib.error.URLError as exc:
        return None, f"URL error: {exc.reason}"
    except TimeoutError:
        return None, "timed out waiting for response"

    try:
        return json.loads(raw), None
    except json.JSONDecodeError:
        body = shorten_for_log(raw)
        if body:
            return None, f"non-JSON response body={body}"
        return None, "non-JSON empty response"


def shorten_for_log(text: str, limit: int = 400) -> str:
    # 错误正文可能带换行、堆栈或整段 HTML；压成单行并截断，避免 journal
    # 被大块错误页刷屏，同时保留最关键的头部上下文。
    compact = " ".join(text.split())
    if len(compact) <= limit:
        return compact
    return compact[: limit - 3] + "..."


def http_post_json(url: str, payload: dict) -> tuple[object | None, str | None]:
    # 手动构造 Request 对象：stdlib urllib 的 urlopen(url, data=...) 默认
    # 会发 POST，但不会自动加 Content-Type: application/json。Ollama
    # 的 /api/generate 要求这个 header，否则会 400。
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
    )
    # timeout=600：总结 prompt 比单句问答大很多，模型冷启动或显存紧张时
    # 可能明显更慢。10 分钟上限是为了区分"真的挂了"和"只是慢"。
    try:
        with urllib.request.urlopen(req, timeout=600) as resp:
            raw = resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        detail = f"HTTP {exc.code} {exc.reason}"
        if body.strip():
            detail += f"; body={shorten_for_log(body)}"
        return None, detail
    except urllib.error.URLError as exc:
        return None, f"URL error: {exc.reason}"
    except TimeoutError:
        return None, "timed out waiting for response"

    try:
        return json.loads(raw), None
    except json.JSONDecodeError:
        body = shorten_for_log(raw)
        if body:
            return None, f"non-JSON response body={body}"
        return None, "non-JSON empty response"


def fetch_activitywatch(base_url: str, since: datetime, until: datetime) -> str:
    # ── ActivityWatch REST API 流程 ──────────────────────────────────
    # 1. GET /api/0/buckets/ → 返回 {bucket_id: bucket_meta} 字典
    # 2. 过滤出 aw-watcher-window-* 和 aw-watcher-afk-* 两类 bucket
    #    （忽略 aw-watcher-web-* 因为没装浏览器扩展；见 activitywatch.nix）
    # 3. 对每个 bucket GET /api/0/buckets/<id>/events?start=...&end=...&limit=N
    # 4. 把每条 event 格式化成一行 markdown 列表项
    buckets = http_get_json(f"{base_url}/api/0/buckets/")
    if not isinstance(buckets, dict) or not buckets:
        return "_ActivityWatch: unreachable or no buckets._"

    # urlencode 会自动 URL-escape ISO timestamp 里的冒号等符号。直接拼
    # f-string 也能跑但不 robust，未来有其他参数要传时 urlencode 是对的。
    q = urllib.parse.urlencode(
        {"start": since.isoformat(), "end": until.isoformat(), "limit": 200}
    )
    lines = []
    for bucket_id in buckets:
        # 只关心窗口聚焦 + AFK，排除其他 watcher（web, stopwatch, 自定义
        # 等）。startswith 而非精确匹配：bucket id 形如
        # "aw-watcher-window_hostname"，后缀每台机器不同。
        if not (
            bucket_id.startswith("aw-watcher-window")
            or bucket_id.startswith("aw-watcher-afk")
        ):
            continue
        events = http_get_json(f"{base_url}/api/0/buckets/{bucket_id}/events?{q}")
        if not isinstance(events, list):
            continue
        for ev in events:
            # AW event schema：{timestamp, duration, data: {app, title, ...}}
            # data.title 是 window bucket 的字段，data.status 是 afk bucket
            # 的字段（值为 "afk" / "not-afk"）。三个 or 兜底拿一个非空值。
            data = ev.get("data", {})
            title = data.get("title") or data.get("app") or data.get("status")
            app = data.get("app", "")
            ts = ev.get("timestamp", "")
            dur = ev.get("duration", 0)
            if title:
                # 单行格式 `- [时间戳] (N秒) app: 标题`
                # :.0f 去掉小数（duration 返回 float 秒，0 位小数够用）
                lines.append(f"- [{ts}] ({dur:.0f}s) {app}: {title}")
    if not lines:
        return "_ActivityWatch: no events in window._"
    # 150 行上限：防止极端情况下（比如一小时内切了几百次窗口）塞爆
    # Ollama context。7B 模型的 context window 通常 8K-32K token，150 行
    # × 平均 100 char 约 15K char ≈ 4K token，安全。
    return "\n".join(lines[:150])


def fetch_atuin(atuin_bin: str, lookback_sec: int) -> str:
    # Atuin 没有 REST API（是纯本地 SQLite），只能通过 CLI 读。
    # shutil.which 检查 atuin 是否可执行（路径是绝对路径也要检查，
    # 防止二进制不存在 / 权限丢失）。
    if not shutil.which(atuin_bin):
        return "_Atuin: binary not found._"
    try:
        # atuin search 用法：
        #   --after "3600s ago"  过滤最近 N 秒
        #   --format "..."       自定义输出（tab 分隔便于后续解析）
        #   --limit 200          硬限制条数（同 AW 的防爆理由）
        # 输出字段：time / directory / command / exit_code
        # time 是 atuin 内部时间戳格式，不是 UTC ISO，LLM 会看懂上下文
        # 关系即可，用户实际读 markdown 时也够用。
        result = subprocess.run(
            [
                atuin_bin,
                "search",
                "--format",
                "{time}\t{directory}\t{command}\t{exit}",
                "--after",
                f"{lookback_sec}s ago",
                "--limit",
                "200",
            ],
            capture_output=True,
            text=True,
            # timeout=15s：atuin 本地 SQLite 查询应该亚秒级，15s 极宽裕。
            timeout=15,
            # check=False：不让非零 exit 抛异常，我们在下面手动处理。
            # atuin 在 sync 未完成或 DB lock 等场景会返回非零。
            check=False,
        )
    except (subprocess.TimeoutExpired, OSError) as exc:
        # OSError：atuin_bin 被 which 认出来但执行失败（极罕见，比如
        # binary 坏了）。TimeoutExpired：15s 还没出结果（SQLite 锁？）
        return f"_Atuin: {exc}._"
    if result.returncode != 0:
        # atuin 非零退出，把 stderr 拼进诊断字符串方便用户调试。
        return f"_Atuin: exit {result.returncode}: {result.stderr.strip()}._"
    # splitlines + strip 过滤空行。atuin 偶尔输出末尾有空行。
    lines = [line for line in result.stdout.splitlines() if line.strip()]
    if not lines:
        return "_Atuin: no commands in window._"
    # 加 "- " 前缀让 LLM 容易识别为 markdown list。150 行同 AW。
    return "\n".join(f"- {line}" for line in lines[:150])


def resolve_screenpipe_token(
    explicit_token: str | None, screenpipe_bin: str | None
) -> tuple[str | None, str | None]:
    # 显式 token 优先：适合远端 Screenpipe 或想跳过本地 CLI 探测的场景。
    if explicit_token:
        return explicit_token.strip(), None

    # 没有 CLI 路径时不报错，直接让调用方尝试无鉴权请求；这样 auth 关闭
    # 的 Screenpipe 仍然可用。
    if not screenpipe_bin:
        return None, None
    if not shutil.which(screenpipe_bin):
        return None, f"screenpipe auth helper not found: {screenpipe_bin}"
    try:
        result = subprocess.run(
            [screenpipe_bin, "auth", "token"],
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )
    except (subprocess.TimeoutExpired, OSError) as exc:
        return None, f"screenpipe auth token: {exc}"
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        if detail:
            return (
                None,
                f"screenpipe auth token exit {result.returncode}: {shorten_for_log(detail)}",
            )
        return None, f"screenpipe auth token exit {result.returncode}"
    lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    if not lines:
        return None, "screenpipe auth token returned empty output"
    return lines[-1], None


def fetch_screenpipe(
    base_url: str | None,
    since: datetime,
    until: datetime,
    screenpipe_token: str | None,
    screenpipe_bin: str | None,
) -> str:
    # None = 未配置，跳过。和 empty string 区分（空串也视为未配置）。
    if not base_url:
        return "_Screenpipe: disabled._"

    # Screenpipe /search API 的查询参数（参考上游 README）：
    #   start_time / end_time —— ISO 时间窗
    #   limit                —— 返回条数
    #   content_type         —— "ocr" | "audio" | "ui" | "all"
    # "all" 拿全部三类，让 LLM 看屏幕上文字 + 语音 + UI 元素。
    q = urllib.parse.urlencode(
        {
            "start_time": since.isoformat(),
            "end_time": until.isoformat(),
            "limit": 50,
            "content_type": "all",
        }
    )
    token, token_error = resolve_screenpipe_token(screenpipe_token, screenpipe_bin)
    headers = {"Authorization": f"Bearer {token}"} if token else None
    if token_error is not None:
        print(f"screenpipe token resolution failed: {token_error}", file=sys.stderr)

    data, error = http_get_json_with_details(f"{base_url}/search?{q}", headers=headers)
    if error is not None:
        short_error = error.split("; ", 1)[0]
        if short_error.startswith("HTTP 401") or short_error.startswith("HTTP 403"):
            return "_Screenpipe: auth failed. See journalctl --user -u context-summarizer._"
        return f"_Screenpipe: {short_error}._"
    if not isinstance(data, dict):
        return "_Screenpipe: malformed response._"
    # Screenpipe 返回 {data: [...], pagination: {...}} 结构
    items = data.get("data", [])
    if not items:
        return "_Screenpipe: no items in window._"
    lines = []
    # 30 条上限（比 AW/Atuin 的 150 少）：因为 Screenpipe 每条 OCR 文本
    # 可能很长，30 × 160 char = 4800 char，已经挺占 token。
    for item in items[:30]:
        content = item.get("content", {})
        # text 是 OCR 字段，transcription 是音频转写字段。二者只会有一个
        # 非空（取决于 content_type）。
        text = content.get("text") or content.get("transcription") or ""
        app = content.get("app_name", "")
        ts = content.get("timestamp", "")
        # strip + replace \n + 截断 160 char：OCR 经常包一整屏幕的文字，
        # 留完整塞给 LLM 会爆 token。160 char 约能保留一段有意义的上下文。
        text = text.strip().replace("\n", " ")[:160]
        if text:
            lines.append(f"- [{ts}] {app}: {text}")
    # 全部条目都没文本（比如只是 UI 元素快照）时返回诊断。
    return "\n".join(lines) if lines else "_Screenpipe: items had no text._"


def build_prompt(
    since: datetime, until: datetime, aw: str, atuin: str, screenpipe: str
) -> str:
    # ── Prompt 设计要点 ──────────────────────────────────────────────
    # 1. "terse assistant"：要求简洁，避免 LLM 写一堆客套开场白。
    # 2. 三段式结构（Active tasks / Key commands / Open threads）：
    #    - Active tasks：用户在做什么（最重要，恢复认知上下文的锚点）
    #    - Key commands：有哪些关键操作（可精确复现）
    #    - Open threads：未完成/被打断的事（这是"恢复"的关键——
    #      用户被打断前正在处理什么 bug？哪个分支写到一半？）
    # 3. "Use only evidence... Do not speculate" —— 明确反幻觉指令。
    #    小模型（7B）容易脑补，强约束能显著降低编造率。
    # 4. 三个 ##-section 把不同数据源分开，模型看得出"这是屏幕内容"
    #    还是"这是命令"还是"这是窗口记录"。
    return f"""You are a terse assistant writing a session log entry in Markdown
for an engineer who may have been interrupted. Summarize the user's activity
from {since.isoformat()} to {until.isoformat()}.

Sections required:
- Active tasks (2-5 bullet points; what the user was most likely working on)
- Key commands (notable shell commands, one line each)
- Open threads (anything that looks unfinished or interrupted)

Use only evidence from the data below. If a section has no evidence, write "(none)".
Do not speculate beyond the data.

## ActivityWatch events
{aw}

## Atuin commands
{atuin}

## Screenpipe text
{screenpipe}
"""


def call_ollama(base_url: str, model: str, prompt: str) -> str:
    # Ollama /api/generate 同步接口：
    #   stream=False 禁用 chunked response，一次性拿完整 JSON。
    #   返回格式 { model, response, done, total_duration, ... }
    # 对 cron 风格脚本用非流式更简单；用户又不看生成过程。
    resp, error = http_post_json(
        f"{base_url}/api/generate",
        {"model": model, "prompt": prompt, "stream": False},
    )
    if error is not None:
        print(
            f"ollama generate failed for model {model} at {base_url}: {error}",
            file=sys.stderr,
        )
        short_error = error.split("; ", 1)[0]
        return f"_Ollama: {short_error}. See journalctl --user -u context-summarizer._"
    # resp 为非 dict 或缺 "response" 字段都走降级，并把实际响应摘要写进
    # journalctl，避免下次只看到一条含糊的 malformed response。
    if not isinstance(resp, dict):
        print(
            f"ollama generate returned non-dict payload: {type(resp).__name__}",
            file=sys.stderr,
        )
        return "_Ollama: malformed response shape. See journalctl --user -u context-summarizer._"
    if "response" not in resp:
        payload = shorten_for_log(json.dumps(resp, ensure_ascii=False))
        print(
            f"ollama generate response missing 'response' field: {payload}",
            file=sys.stderr,
        )
        return "_Ollama: response missing response field. See journalctl --user -u context-summarizer._"
    # strip 去掉 LLM 生成常见的前后空行。
    return str(resp["response"]).strip()


def main() -> int:
    env = os.environ
    # 所有默认值都和 context-summarizer.nix 里的默认 option 对齐。这样
    # 在 systemd unit 之外手动跑 `context-summarizer`（用于调试）也能
    # 走默认路径跑通。
    output_dir = Path(
        env.get(
            "CONTEXT_SUMMARIZER_OUTPUT_DIR",
            str(Path.home() / ".local/share/claude-context"),
        )
    )
    lookback = int(env.get("CONTEXT_SUMMARIZER_LOOKBACK_SEC", "3600"))
    aw_url = env.get("CONTEXT_SUMMARIZER_AW_URL", "http://127.0.0.1:5600")
    ollama_url = env.get("CONTEXT_SUMMARIZER_OLLAMA_URL", "http://127.0.0.1:11434")
    ollama_model = env.get("CONTEXT_SUMMARIZER_OLLAMA_MODEL", "qwen2.5-coder:7b")
    # `or None`：env.get 返回 None 或空串都算未配置，避免下游把 "" 当
    # base_url 拼出 http:// 然后实际去请求。
    screenpipe_url = env.get("CONTEXT_SUMMARIZER_SCREENPIPE_URL") or None
    screenpipe_token = env.get("CONTEXT_SUMMARIZER_SCREENPIPE_TOKEN") or None
    screenpipe_bin = env.get("CONTEXT_SUMMARIZER_SCREENPIPE_BIN") or None
    atuin_bin = env.get("CONTEXT_SUMMARIZER_ATUIN_BIN", "atuin")

    # 全用 UTC 避免跨时区歧义。ISO 8601 格式带 +00:00 后缀，AW/Screenpipe
    # 都接受；markdown 里 LLM 和人类读的时候都能识别出绝对时间。
    until = datetime.now(timezone.utc)
    since = until - timedelta(seconds=lookback)

    # 三个数据源串行拉：并行化也能做（threading/asyncio），但每个源都
    # 只是一两次 HTTP/subprocess 调用，总耗时秒级，串行足够简单清晰。
    aw = fetch_activitywatch(aw_url, since, until)
    atuin = fetch_atuin(atuin_bin, lookback)
    screenpipe = fetch_screenpipe(
        screenpipe_url,
        since,
        until,
        screenpipe_token,
        screenpipe_bin,
    )
    prompt = build_prompt(since, until, aw, atuin, screenpipe)
    summary = call_ollama(ollama_url, ollama_model, prompt)

    # parents=True exist_ok=True：目录不存在就递归建，已存在不报错。
    output_dir.mkdir(parents=True, exist_ok=True)
    target = output_dir / "_Current_Context.md"
    # header 用 "---" 水平线分隔每次 append，h3 header 带时间戳和 lookback
    # 窗口长度。这样一个月后回看这份 markdown，能精确定位到某个时段。
    header = f"\n\n---\n\n### {until.isoformat()} (lookback {lookback}s)\n\n"
    # 模式 "a" = append，不是 "w"（每次覆盖）。_Current_Context.md 是
    # 滚动日志，不断往下加。
    # ⚠️ 需用户决策：长期运行这个文件会无限增长。一年大约 8760 次追加，
    # 单次 ~1-2KB，总量 10-20 MB，不算大但不可控。想要限制大小，可在
    # 这里加 logrotate 逻辑（比如超过 10MB 就归档到
    # _Current_Context.<date>.md）。目前保持简单，等用户觉得太长再切。
    with target.open("a", encoding="utf-8") as fh:
        fh.write(header)
        fh.write(summary)
        fh.write("\n")
    # 进度信息写 stderr 不写 stdout：oneshot service 不需要 stdout，
    # journalctl 会自动记录 stderr 方便查看"上次写了多少字"。
    print(f"wrote {len(summary)} chars to {target}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
