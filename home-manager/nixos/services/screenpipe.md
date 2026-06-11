# Screenpipe 终端测试手册

本手册描述在**不改动 NixOS 生产配置**的前提下，通过 `nix shell` 在终端完整验证 screenpipe 捕获能力、a11y 树接入、MCP stdio 交互的流程。测试通过后再把 [screenpipe.nix](./screenpipe.nix) 模块启用落盘。

## 目标

- 在隔离的数据目录中运行 `screenpipe record`，避免污染生产 `~/.screenpipe/`
- 复刻 [screenpipe.nix](./screenpipe.nix) 中 `screenpipeLibs` / `runtimeInputs` / `uiMonitoring.extraEnvironment` 的全部依赖与环境注入
- 验证 AT-SPI2 (a11y 树)、OCR、REST API、MCP stdio 握手四条路径
- 测试完成后无残留（数据目录可删，无系统级改动）

## 前置依赖一次性就绪

### 1. 启动 AT-SPI2 DBus 总线

AT-SPI2 的 bus launcher 在 nixpkgs 的 `at-spi2-core` 中位于 `libexec/` 下，**不会进入 `nix shell` 的 `PATH`**，必须用绝对路径调起。但通常情况下无需手动启动：只要 DBus session 能找到 `org.a11y.Bus` 服务定义，任意 DBus 调用都会触发自动激活。

**快速检查 bus 是否已经存在**（可能已被其他应用激活过）：

```bash
busctl --user call org.a11y.Bus /org/a11y/bus org.a11y.Bus GetAddress
```

- 返回形如 `s "unix:path=/run/user/1000/at-spi/bus_0,guid=..."` → bus 正常，跳到下一步
- 返回 `Unknown service` / `Could not activate` → 继续执行手动启动

**手动启动**（仅当自动激活失败时）：

```bash
ATSPI=$(nix build --print-out-paths --no-link nixpkgs#at-spi2-core)
"$ATSPI/libexec/at-spi-bus-launcher" --launch-immediately &

# 再次验证
busctl --user call org.a11y.Bus /org/a11y/bus org.a11y.Bus GetAddress
ls -la /run/user/$(id -u)/at-spi/      # 应看到 bus_0 socket
```

### 2. 开启 GTK toolkit-accessibility 全局开关

即使非 GNOME 桌面，GTK 应用也读这个 gsettings key 来决定是否把自己挂到 AT-SPI bus。

```bash
gsettings set org.gnome.desktop.interface toolkit-accessibility true

# 确认
gsettings get org.gnome.desktop.interface toolkit-accessibility     # 应输出 true
```

> 此设置是用户级 dconf 持久化项，设一次即可。落盘配置后通过 `dconf.settings` 声明式管理。

## 进入测试 shell

一条命令拉齐 [screenpipe.nix](./screenpipe.nix) 声明的全部依赖，加上 `at-spi2-core`（busctl 验证用）与 `bun`（screenpipe 的 pi agent 可选运行时）：

```bash
nix shell \
  nixpkgs#nodejs nixpkgs#ffmpeg nixpkgs#tesseract \
  nixpkgs#alsa-lib nixpkgs#libpulseaudio nixpkgs#pipewire nixpkgs#dbus \
  nixpkgs#openssl nixpkgs#lame nixpkgs#openblas nixpkgs#xz \
  nixpkgs#libgbm nixpkgs#libxcb nixpkgs#wayland nixpkgs#libxkbcommon \
  nixpkgs#at-spi2-core nixpkgs#bun
```

## 在 shell 内注入运行时环境

以下三段必须在同一 shell 会话内依序执行；退出 shell 后需重做。

### LD_LIBRARY_PATH（复刻包装脚本）

```bash
export LD_LIBRARY_PATH="$(nix eval --impure --raw --expr '
  with import <nixpkgs> {};
  lib.makeLibraryPath [
    stdenv.cc.cc.lib ffmpeg alsa-lib libpulseaudio pipewire dbus
    openssl lame openblas tesseract xz libgbm libxcb wayland libxkbcommon
  ]
')"
```

### AT-SPI 环境变量（复刻 `uiMonitoring.extraEnvironment`）

```bash
export GTK_MODULES=gail:atk-bridge
export GNOME_ACCESSIBILITY=1
export QT_ACCESSIBILITY=1
export QT_LINUX_ACCESSIBILITY_ALWAYS_ON=1
```

### 测试数据目录

```bash
export SCREENPIPE_TEST_DIR="$HOME/.screenpipe-test"
mkdir -p "$SCREENPIPE_TEST_DIR"
```

## 启动 screenpipe（对应模块默认 ExecStart）

```bash
npx -y --prefer-offline screenpipe@latest record \
  --data-dir "$SCREENPIPE_TEST_DIR" \
  --port 3030 \
  --retention-days 14 \
  --language english \
  --language chinese \
  --video-quality max \
  --transcription-mode batch \
  --audio-transcription-engine parakeet \
  --audio-chunk-duration 30 \
  --use-all-monitors \
  --disable-audio \
  --pause-on-drm-content \
  --use-pii-removal \
  --disable-telemetry
```

旗标与 [screenpipe.nix](./screenpipe.nix) 中 `recordArgs` 的默认展开一一对应。局部改参即可验证分支：

| 目标           | 调整                                                  |
| -------------- | ----------------------------------------------------- |
| 测音频 + 转写  | 去掉 `--disable-audio`，可附加 `--filter-music`       |
| 切换到实时转写 | `--transcription-mode realtime`                       |
| 仅单显示器     | `--use-all-monitors` → `--monitor-id <ID>`            |
| 窗口白名单     | 追加 `--included-windows "Firefox"`                   |
| 最高画质       | `--video-quality max`                                 |
| 启用 API 鉴权  | 追加 `--api-auth`，并 `export SCREENPIPE_API_KEY=...` |

## 运行时验证（另开一个终端）

新终端同样需先 `nix shell` 和 `export LD_LIBRARY_PATH=...`，否则 `screenpipe pipe list` 等 CLI 调用会找不到共享库。

### REST API

```bash
curl -s http://127.0.0.1:3030/health | jq
curl -s "http://127.0.0.1:3030/search?q=nixos&limit=5" | jq
```

### 捕获入库情况

```bash
sqlite3 "$HOME/.screenpipe-test/db.sqlite" '.tables'
sqlite3 "$HOME/.screenpipe-test/db.sqlite" 'select count(*) from frames;'
sqlite3 "$HOME/.screenpipe-test/db.sqlite" 'select count(*) from ocr_text;'
```

### a11y 树是否被采集

首先确认 screenpipe 日志**不再**出现：

```
WARN screenpipe_a11y::platform::linux: AT-SPI2 accessibility service not available
ERROR screenpipe_engine::ui_recorder: UI capture permissions denied
```

若 warning 消失且日志转为正常 tree walk，再看 DB：

```bash
sqlite3 "$HOME/.screenpipe-test/db.sqlite" '.schema' | grep -iE 'ui|a11y|accessibility'
# 若包含 ui_monitoring / accessibility 相关表且行数随使用增长 → AT-SPI 接入成功
```

### pHash 帧去重是否生效（间接观察）

锁屏或静置 5 分钟不操作，理论上帧增长率应**远低于** fps × 300：

```bash
sqlite3 "$HOME/.screenpipe-test/db.sqlite" \
  "select count(*) from frames where timestamp > strftime('%s','now','-5 minutes');"
```

### MCP stdio 握手

```bash
# 直接跑包，等待 JSON-RPC stdin 输入；按 Ctrl+C 退出即可证明二进制可拉起
npx -y --prefer-offline screenpipe-mcp
```

如需端到端验证 MCP，临时在 Claude Code / openfang 的 MCP 配置里加一条：

```json
{
  "mcpServers": {
    "screenpipe-test": {
      "command": "npx",
      "args": ["-y", "--prefer-offline", "screenpipe-mcp"]
    }
  }
}
```

重启客户端后尝试调用 screenpipe 的 search 工具。

### Pipes CLI

```bash
screenpipe pipe list
screenpipe pipe --help
```

## 验证清单

| 能力         | 期望                                                    |
| ------------ | ------------------------------------------------------- |
| REST 健康    | `/health` 返回 200                                      |
| 屏幕捕获     | `frames` 表行数持续增长                                 |
| OCR          | `ocr_text` 表有内容                                     |
| a11y 树      | 启动日志无 AT-SPI warning；DB 含 ui/a11y 表且随操作增长 |
| pHash 去重   | 静置期帧增长率远低于 fps × 时长                         |
| DRM 暂停     | 播 Netflix 时帧入库暂停                                 |
| MCP          | `screenpipe-mcp` 能握手                                 |
| pipes 子命令 | `screenpipe pipe list` 返回空列表或已装 pipe            |

## 清理

```bash
# 停 screenpipe: 在主终端 Ctrl+C

# 删测试数据
rm -rf "$HOME/.screenpipe-test"

# 退出 nix shell
exit

# 若手动启过 at-spi-bus-launcher 且不希望保留
kill %1   # 或 pkill at-spi-bus-launcher
```

`gsettings` 的 `toolkit-accessibility` 为用户级 dconf 项，测试通过后建议保留 —— 落盘的 home-manager 配置也依赖它。

## 从测试过渡到生产配置

终端测试通过后，按以下三处落盘：

### 1. 系统层 —— AT-SPI2 总线由 systemd 管理

在 [../../../modules/nixos/desktop/niri/default.nix](../../../modules/nixos/desktop/niri/default.nix) 的 `config = lib.mkIf isNiri { ... }` 块内追加：

```nix
# Screenpipe 与其它屏幕阅读器/语音工具依赖 AT-SPI2 DBus bus。
# services.gnome.at-spi2-core 虽挂 gnome 命名空间，实际在任何 Linux 桌面
# 都能工作 —— 启用后 systemd user 管理 at-spi-dbus-bus.service，应用才能
# 通过 org.a11y.Bus 暴露 accessibility 树。
services.gnome.at-spi2-core.enable = true;
```

### 2. home 层 —— toolkit-accessibility 声明式化

在 [../../../homes/x86_64-linux/star@x.nix](../../../homes/x86_64-linux/star@x.nix) 的 `users.star` 块内追加：

```nix
dconf.settings."org/gnome/desktop/interface".toolkit-accessibility = true;
```

### 3. 启用 screenpipe 模块

同文件 `my.services` 块下 `screenpipe.enable = true;` 已在 base line，确认无误即可。如需覆盖默认参数，例如：

```nix
my.services.screenpipe = {
  enable = true;
  videoQuality = "low";          # 测试发现 balanced 太占盘
  ignoredWindows = [ "1Password" "Bitwarden" ];
  pipes.daily-summary = {
    text = ''
      ---
      schedule: "0 22 * * *"
      allow-apps: ["*"]
      ---
      # 每日屏幕摘要
      ...
    '';
  };
};
```

### 4. 应用与验证

```bash
just fmt
just dry-build x
just test x                       # 非持久，失败 reboot 即回滚

# 确认 AT-SPI bus 由 systemd 管理
systemctl --user status at-spi-dbus-bus.socket
busctl --user call org.a11y.Bus /org/a11y/bus org.a11y.Bus GetAddress

# 确认 screenpipe 由 umbrella target 管理
systemctl --user status screenpipe.target screenpipe.service
journalctl --user -u screenpipe -n 50

# 确认 MCP 注入成功
grep -A3 screenpipe ~/.config/openfang/config.toml

just switch x                     # 满意后落盘
```

## 常见问题

### `at-spi-bus-launcher: command not found`

`at-spi2-core` 的二进制在 `libexec/` 而非 `bin/`，`nix shell` 不会把 `libexec` 加入 `PATH`。用 `"$(nix build --print-out-paths --no-link nixpkgs#at-spi2-core)/libexec/at-spi-bus-launcher"` 全路径调用。通常更好的做法是让 DBus 自动激活（见"前置依赖"章节）。

### `Failed to get property Address on interface org.a11y.Bus: No such property`

命令写错：`Address` 是**方法**不是**属性**。必须用 `busctl --user call ... GetAddress`，不能用 `get-property`。能返回这条错误本身就说明 bus 已在响应 DBus 请求，换句话说 bus 已存活。

### `libgbm.so.1: cannot open shared object file`

`LD_LIBRARY_PATH` 未导出。确认已执行本手册"注入运行时环境"章节的 `export LD_LIBRARY_PATH=...`，且**每开一个新终端都要重做**。

### `pi agent install failed: bun not found`

可选警告。若不使用 screenpipe pi agent 功能可忽略；若要用则确认 `nix shell` 命令中包含 `nixpkgs#bun`。

### `UI capture permissions denied` 持续出现

按顺序排查：

1. `gsettings get org.gnome.desktop.interface toolkit-accessibility` 必须返回 `true`
2. `busctl --user call org.a11y.Bus /org/a11y/bus org.a11y.Bus GetAddress` 必须返回 bus socket 路径
3. 启动 screenpipe 的 shell 必须已 `export` 本手册四个 `*_ACCESSIBILITY*` 变量
4. 被采集的目标应用本身必须在同一 session 启动；已运行的应用改环境变量后**必须重启**才会重新挂到 AT-SPI
