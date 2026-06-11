{ pkgs, ... }:

# ── Phase D：context-summarizer 的 Nix 包装层 ────────────────────────
# 这是 AI 认知上下文恢复系统"最上层"的小工具：每小时从 ActivityWatch /
# Atuin / 可选 Screenpipe 拉最近一段时间的事件，塞给本地 Ollama 模型
# 总结成 Markdown，追加到 ~/.local/share/claude-context/_Current_Context.md。
# 用户被打断后回来打开这份文件就能快速回忆"刚才在干嘛"。
#
# 为什么用 writePython3Bin 而非 buildPythonApplication：
#   - 业务逻辑只有 221 行、零第三方依赖（纯 stdlib + urllib + subprocess
#     调 atuin），用 buildPythonApplication 要写 setup.py/pyproject.toml，
#     overhead 远大于脚本本身。writePython3Bin 吃一个字符串直接出 bin。
#   - 自带 flake8 静态检查（构建时执行），写错了构建失败，catch bug 早。

pkgs.writers.writePython3Bin "context-summarizer" {
  # libraries：不注入任何第三方库。所有 HTTP 调用用 stdlib urllib，
  # 和 atuin 通讯用 subprocess 跑 CLI。保持零依赖 = 零 npmDepsHash /
  # cargoHash 这类外部哈希要维护。
  libraries = [ ];

  # flakeIgnore：告诉 writePython3Bin 构建时跑的 flake8 跳过这两条规则。
  #   E501 = line too long（允许 >79 字符，prompt 里长行不想折）
  #   W503 = line break before binary operator（现代 PEP8 允许，老规则过时）
  # 其他规则（unused import、未定义变量等）都保留，有误会构建失败。
  flakeIgnore = [
    "E501"
    "W503"
  ];
} (builtins.readFile ./summarize.py)
# ↑ builtins.readFile 在 eval 时把 summarize.py 当字符串读入，作为
# writePython3Bin 的第二个参数（脚本主体）。用单文件 readFile 而不是
# let body = ''...''; 的好处：脚本可独立 lint / pytest / 编辑器语法高亮，
# 不会被 Nix 字符串转义污染（比如不用担心 ${} 冲突）。
