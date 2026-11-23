# 安装系统

安装介质是运行安装程序的 Live 系统，目标是最终安装到硬盘的普通 NixOS 配置。
两者分别求值，只有目标配置与机器数据参与最终系统的组装。

```text
compositions/installers/<平台>/<名称>/
├── live.nix                 # Live 环境、安装功能与联网／离线选择
└── target/
    ├── nixos.nix            # 目标的软件、账户和系统策略
    └── home-manager.nix     # 目标的用户预设与 feature 选择

features/installer/
├── options.nix              # enable、target、source、offline.enable
├── nixos.nix                # feature 入口、模板生成与安装器配置
├── calamares/               # 完整的 Calamares 集成
│   ├── default.nix         # 唯一入口，组合配套的程序与配置
│   ├── package.nix         # 程序补丁和启动包装
│   ├── extensions.nix      # 对 Nixpkgs 安装扩展的局部覆盖
│   ├── flake.nix.in        # 安装后的 flake 入口模板
│   └── patches/            # 目标接入、flake 安装和离线设置
├── prebuild-machine.nix     # 为安装目标预构建提供占位机器配置
└── offline.nix              # 内部 NixOS 模块，准备目标与离线载荷

outputs-refactor/installers.nix  # 发现 live.nix、求值并导出 ISO
```

## 使用

```sh
nix build .#installer-offline
ls result/iso/
```

新文件尚未纳入 Git 时可用 `nix build 'path:.#installer-offline'`。
完整出口为 `packages.x86_64-linux.installer-offline`，Live 配置可从
`installerConfigurations.x86_64-linux.installer-offline` 查看。

当前组合使用 GNOME Live 环境；安装目标使用 Star 的 HM 预设、Niri 和 Noctalia，
关闭 SOPS。Star 的系统账户预设不参与安装目标；向导中的用户名才是实际账户名。
具体 ISO 在 `live.nix` 中选择安装功能和目标：

```nix
features.installer = {
  enable = true;
  target = ./target;
  offline.enable = true;
};
```

`target` 指向仓库内包含 `nixos.nix` 和 `home-manager.nix` 的目录。
feature 内部将其转换为仓库相对路径，复制到目标系统后仍能定位。
目标中需要增加功能，修改同目录的 `target/`；它们使用现有的 feature 和共享选项机制。
需要调整 Live 系统、镜像压缩等介质设置，修改 `live.nix`。
`features.installer.offline.enable` 默认关闭，当前介质显式开启。
Live 显式关闭项目的 SSH 和 system-base feature，沿用官方 Live 的原生配置；
这些开关不影响独立求值的安装目标。

## 配置和数据的流向

```text
target/ ＋ prebuild-machine.nix → 普通系统构造 → 为镜像准备预构建结果
target/ ＋ 上游生成的机器配置 → 同一系统构造 → 实际安装结果
```

普通主机、Live 和安装目标共用 `lib.mkNixosSystem`，Live 与安装目标分别求值。
该公共接口由 `framework/nixos-system/` 定义并注册，统一接入框架、HM 和共享选项传递；
根入口加载它，主机输出和 installer feature 都只调用这个接口。
具体 ISO 通过 `target` 选项选择目标，feature 负责预构建和入口生成。
通用输出层只发现 `live.nix` 并发布结果，不读取 feature 内部文件或目标目录。

`prebuild-machine.nix` 只提供预构建所需的占位机器配置，不处理离线模式或载荷收集。
当前由 `offline.nix` 调用；正式安装使用 Calamares 根据实际机器生成的配置。

安装程序将以下内容放进目标磁盘：

```text
/etc/nixos/
├── flake.nix                   # 所选目标、实际用户名、密码哈希及 HM 接线
├── flake.lock                  # 安装时锁定相对路径输入
├── configuration.nix           # 上游安装任务生成的机器配置
├── hardware-configuration.nix  # nixos-generate-config 生成
└── config/                     # 可编辑的仓库快照，不含 Git 元数据
```

Calamares 的 Nixpkgs 扩展生成普通的 `configuration.nix` 和硬件配置。
构建镜像时确定模板中的平台和目标路径，安装时仅填入实际用户名和密码哈希。
用户名在求值前已知，用来建立 HM 用户键和共享选项来源，避免反向依赖。
软件和用户预设由 `target/` 决定；向导负责主机名、用户、语言、键盘、磁盘和自动登录选择。
密码通过 stdin 交给 `mkpasswd`，仅持久化 yescrypt 哈希；未设置 root 密码时锁定 root。
后续维护使用普通的 `nixosConfigurations.installed`：

```sh
nixos-rebuild build --flake /etc/nixos#installed
```

## Calamares 的边界

`nixos.nix` 通过 `pkgs.callPackage ./calamares` 调用唯一入口，传入仓库来源、
目标 flake 模板和离线模式，取得可运行的安装程序。程序、扩展、模板和补丁
加载路径都在 `calamares/` 内配套；外层不直接导入内部文件。

执行顺序沿用上游：分区 → 挂载 → `nixos` → 卸载。`nixos` 仍是 Nixpkgs 的安装任务，
其引导、LUKS、Btrfs、硬件配置、语言键盘及安装进度逻辑没有另行实现。
上游 `settings.conf` 和模块配置直接沿用，只移除软件选择页及安装后的密码修改任务；
离线模式另外移除联网检查和 GeoIP 请求。

`target-profile.patch` 将软件、内核和网络服务选择交给目标，将自动登录选择交给目标的显示管理器，
并保留包集合对 unfree 软件的决定，避免再次声明 `nixpkgs.config`。
`install-flake.patch` 在上游生成配置后复制仓库、填入 flake、锁定输入，再用
`nix flake archive --to` 交付输入源码；安装命令增加 `--flake` 等参数，进度仍由上游处理。

目标使用 `users.mutableUsers = false`，所以密码要进入 NixOS 声明，不能仅在安装后修改 shadow。
上游只将主用户密码导出到 Global Storage；`export-root-password.patch` 补充 root 的相同接口。
该接口与密码哈希持久化配套，不能只删除接口补丁而保留读取它的代码。
启动器保留 Wayland 环境。配置通过原生 XDG 查找路径接入，不注册全局包覆盖。

## 离线载荷

离线与联网使用相同的目标和安装过程。离线组合额外携带锁定输入源码、
UEFI／BIOS 目标的运行闭包，以及重新生成配置所需的构建输入。
`nixos.nix` 静态导入内部的 `offline.nix` 模块；后者在总开关和离线开关都启用时，
独立构造预构建目标、收集输入源码并设置 `isoImage.storeContents`。
这些依赖不会附加到安装后系统的运行闭包。

`offline.nix` 集中说明构建依赖的来源。采用预构建包和少量配置构建工具，
避免携带完整编译工具链。它不保证安装后离线添加任意新软件；更改目标或升级 Nixpkgs 时，
仍需检查新增的构建依赖。安装任务关闭远程替代源，同时保留从介质本地 store 复制结果的能力。

`checks.<平台>.installer-<名称>` 构建 ISO，预构建目标作为离线 ISO 的依赖参与构建。
