---
name: refresh-flake-input-comments
description: 核验并更新 flake 输入的上游依赖树和 follows 策略注释。用于输入、锁文件、依赖覆盖、软件包使用方式或相关缓存配置变化，以及用户要求检查或刷新注释时。
---

# 刷新 Flake 输入注释

默认处理仓库根目录的 `flake.nix`，也可使用用户指定的嵌套 flake。
仅修改输入注释；策略不符合下述规则或证据不足时明确指出，不自行改动配置或锁文件。

## 获取上游依赖树

在仓库根目录运行，`--flake` 指向目标 flake 目录：

```console
python3 .agents/skills/refresh-flake-input-comments/scripts/inspect_upstream_inputs.py --flake .
```

脚本按各输入的确切锁定版本独立生成上游树，不能用本仓库经 `follows` 合并的锁定依赖图替代。
它跳过 `flake = false` 源码输入、无上游输入的 nixpkgs 固定版本输入及其别名，无需为它们维护注释。
获取失败时保留对应原注释，并说明无法核实的部分。

## 判断 follows 策略

根据目标 flake 的输入定义和本地覆盖分类；上游自身的共享依赖不计为本地跟随：

- `N/A`：没有上游输入的非 nixpkgs flake。
- `all (alias)`：完全通过 `.follows` 实现的根输入别名。
- `all`：所有直接上游输入都重定向到对应的根输入。
- `partial`：仅重定向部分直接输入，或只重定向嵌套输入，未覆盖完整的上游依赖图。
- `none`：该根输入下的任何层级都不存在本地跟随覆盖。

检查实际使用输入的代码和缓存配置，考虑根输入未来更新后的情况，不能仅凭当前输出路径一致判断：

- 实际使用的软件包构建成本高，且预期上游缓存提供其确切派生结果时，保留影响该派生的上游依赖版本。
- 其他情况优先 `follows`，包括轻量包装、应共享宿主包集的求值或模块依赖，
  以及已确认不参与实际软件包派生的格式化或检查依赖。
- 没有对应根输入的独有依赖可保留上游版本，作为 `partial` 的理由。

## 更新注释

在输入定义上方使用以下格式，依赖树采用脚本输出，不混入本地 `follows`；策略理由简短且基于实际使用和缓存情况。

```nix
# Upstream inputs:
# input-name
# ├── direct-input
# │   └── transitive-input
# └── shared-input (shared with input-name/direct-input)
#
# Follow policy: partial — 基于实际使用和缓存成本的简要理由。
input-name = { };
```

完成后对照脚本输出核对依赖树，并检查 diff 仅包含目标注释，未引入锁文件改动。
