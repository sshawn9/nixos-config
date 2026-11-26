# System Manager + embedded Home Manager

这是与原有两种模式并列的第三种组装方式：

| 模式                                   | 配置目录                      | 原生构造入口               | 输出                  |
| -------------------------------------- | ----------------------------- | -------------------------- | --------------------- |
| standalone Home Manager                | `compositions/homes`          | `homeManagerConfiguration` | `homeConfigurations`  |
| NixOS + embedded Home Manager          | `compositions/hosts`          | `nixosSystem`              | `nixosConfigurations` |
| System Manager + embedded Home Manager | `compositions/system-manager` | `makeSystemConfig`         | `systemConfigs`       |

在 Ubuntu、Debian 等非 NixOS Linux 上，由 System Manager 管理系统配置，
Home Manager 管理用户配置。两者在同一个 `systemConfigs.<主机名>` 中求值和部署。
原有纯 standalone Home Manager 入口继续保留。

## 主机接入

```text
compositions/system-manager/x86_64-linux/ubuntu01/
├── system.nix
└── users.nix
```

组装器扫描 `compositions/system-manager/<平台>/<主机>`，通过 `moduleFiles.list`
递归加载主机目录中的全部 Nix 模块，沿用忽略下划线开头文件和目录的规则。
文件名只表达配置内容，新增文件和子目录中的模块都会自动参与组装。
上述示例同时生成 `systemConfigs.ubuntu01` 和 `systemConfigs."ubuntu01@x86_64-linux"`；
跨平台主机重名时只提供带平台的名字。

`system.nix` 示例：

```nix
{
  # 本例选择让 System Manager 管理 Nix 和声明的账户。
  # 账号管理策略由具体主机决定，构造器不覆盖上游默认值。
  nix.enable = true;
  services.userborn.enable = true;
}
```

`users.nix` 示例：

```nix
{ self, ... }:
{
  # 这是选择共享选项来源的用户名，必须在系统侧明确填写。
  sharedOptionsUser = "star";

  # 描述发行版中已存在的账户，填写该机器实际的 UID、GID、组名和家目录。
  users.groups.star.gid = 1000;
  users.users.star = {
    isNormalUser = true;
    uid = 1000;
    group = "star";
    home = "/home/star";
    createHome = true;
  };

  home-manager.users.star = {
    imports = [ self.homeModules.star ];

    # Star 预设默认使用用户的 checkout；此例明确选择 store 快照。
    fileSources.localRoot = null;
    features.terminal.enable = true;
  };
}
```

主机目录内的文件都作为系统层模块加载，HM 配置通过 `home-manager.users.<用户名>` 声明。
组装器统一导入两侧框架工具和对应的 `allFeatures`，主机无需重复列出 feature。
这里使用 Star 的 HM 预设；系统账户及权限在具体主机或其系统侧模块中声明。
没有 System Manager 出口时，只加载该 feature 的 HM 实现，不警告、不自动导入其 NixOS 实现。

## 共享选项与 context

[shared-options.nix](./shared-options.nix) 属于本模式的组装接线，
将 `sharedOptionsUser` 指定用户的 `features`、`common`、`fileSources` 定义传给系统侧。
继续复制原始定义、跳过最终值为 `null` 的来源，并保留原有优先级和覆盖规则；
不先复制最终值，也不在 feature 内增加参数转发。
System Manager 系统侧仅接收自己已声明的选项，不会自动加载 NixOS 实现。
NixOS 组装继续使用其原有的共享选项模块，两种 embedded 模式遵守同一传递约定。

`self.lib.evaluationContext` 新增 `isSystemManager`、`inSystemManager`。
System Manager 内的 HM 满足 `isEmbeddedHome` 和 `inSystemManager`，不满足 `inNixOS`；
因此可以分辨它和 NixOS embedded HM、纯 standalone HM。

## 新增 feature 实现

`nixosModules`、`homeModules`、`systemManagerModules` 各自独立。
现有 feature 可以保持不变；只有需要提供 System Manager 配置时，才增加第三个出口：

```nix
{
  flake.systemManagerModules.example = ./system-manager.nix;
}
```

该入口自行导入选项声明，用 System Manager 的原生选项实现系统配置。
feature 总开关仍包裹配置。本次仅增加框架接线，现有 feature 的系统实现留待逐项添加。

## 构建与应用

宿主需已有支持 flakes 的多用户 Nix 和 systemd。
在仓库中构建，不改变运行中的系统：

```sh
nix build .#systemConfigs.ubuntu01
```

确认配置后，在目标 Ubuntu / Debian 主机上应用：

```sh
nix run .#system-manager -- switch --flake .#ubuntu01 --sudo
```

这里的命令会应用 System Manager 与对应的 HM 配置。
已有 standalone HM 若也管理同一用户，应停止对同一批文件使用原入口部署。

构造器统一接入框架工具和 embedded HM，Nix、账号管理等策略由具体主机或对应模块决定。
HM 获得生成用户 `nix.conf` 和运行激活所需的 Nix 客户端默认包。

构造器将项目包集的配置默认值和 overlay 列表交给 `makeSystemConfig`，
由 System Manager 原生创建 `pkgs`；主机仍可设置 `nixpkgs.config` 和 `nixpkgs.overlays`。
HM 默认共用这个包集。
