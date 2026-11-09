# 腾讯云轻量服务器从 Ubuntu 全新安装 NixOS：完整复现记录

本文记录 **2026-11-09** 在腾讯云轻量应用服务器 Lighthouse 上，将 Ubuntu 26.04 全新安装为 NixOS 26.05 的实际过程。安装后已经执行普通重启，并验证从系统盘启动、`star` 用户 SSH 登录、免密 sudo、DHCP、DNS 和 swap 均正常。

目标是先装好最基础、可远程维护的 NixOS。此次采用独立的最小 flake，没有导入本仓库的桌面、Home Manager 或业务服务配置。本文给出完整配置和锁文件，以便以后即使服务器又重装成 Ubuntu，也能重新执行。

**这是清空整个系统盘的安装。执行 `disko,install` 阶段后，`/dev/vda` 上的旧系统、分区和数据都会被替换。本次明确确认无旧数据需要保留。以后重做时，需要重新检查数据和目标磁盘。**

正文按修正后的成功操作顺序编排；实际遇到的失败、原因判断和修复集中记录在后面的“问题与恢复”章节。固定版本和校验值用于复现这次成功结果，不代表以后安装新机器时无需检查硬件，也不代表应该长期停留在这些软件版本。

## 1. 本次机器、版本与安装结果

### 1.1 实际机器信息

| 项目                | 安装时实测值                                    |
| ------------------- | ----------------------------------------------- |
| 腾讯云产品          | 轻量应用服务器 Lighthouse                       |
| 本地 SSH 别名       | `tencent`                                       |
| 公网 IPv4（已脱敏） | `203.0.113.10`（文档示例地址）                  |
| 原 SSH 用户         | `ubuntu`，支持 `sudo -n`                        |
| 原主机名            | `VM-0-10-ubuntu`                                |
| 原系统              | Ubuntu 26.04 LTS                                |
| 原内核              | `7.0.0-30-generic`                              |
| 虚拟化              | KVM                                             |
| 架构、CPU           | `x86_64`，2 个 vCPU                             |
| 物理内存            | `2009720 kB`，约 1.92 GiB                       |
| 原系统 swap         | 2 GiB；进入临时安装环境后不会自动沿用           |
| 固件启动方式        | Legacy BIOS                                     |
| 系统盘              | `/dev/vda`，40 GiB，GPT                         |
| 网卡驱动            | `virtio_net`                                    |
| 原网卡名称          | `eth0`；可预测名称为 `ens3`，另有 `enp0s3` 名称 |
| 内网 IPv4           | `10.7.0.10/22`，DHCP 获取                       |
| 网关                | `10.7.0.1`                                      |
| DHCP 下发 DNS       | `183.60.83.19`、`183.60.82.98`                  |
| 网卡 MAC            | `52:54:00:76:7a:bd`                             |
| 新主机名            | `tencent-tokyo-2c2g`                            |
| 新普通用户          | `star`，UID 1000，属于 `wheel`                  |
| 本地 SSH 私钥路径   | `/home/star/.ssh/id_ed25519`                    |

本文中的服务器公网 IPv4 统一替换为文档示例地址 `203.0.113.10`，复现时需换成实际公网地址。其余 IP、设备名和用户信息保留本次记录。网络配置使用 DHCP 和驱动匹配，不把上述内网 IP、网关、MAC 或 DNS 写死。再次安装前仍应确认公网地址、登录用户和磁盘。

原磁盘虽然有挂载在 `/boot/efi` 的 FAT 分区，但 `/sys/firmware/efi` 不存在，内核支持 EFI，启动日志显示 Bochs BIOS。**磁盘有 EFI 分区，不等于这一次实际通过 UEFI 启动。** 本次最终采用 BIOS + GRUB。

`dmesg` 中的 `DMI: Tencent Cloud CVM` 是虚拟硬件信息，不据此把控制台中的 Lighthouse 实例当作另一产品的 CVM 实例调用 API。

### 1.2 固定的软件版本

| 项目                 | 本次版本或提交                                    |
| -------------------- | ------------------------------------------------- |
| 本地 Nix             | `2.34.9`                                          |
| 原 Ubuntu 上已有 Nix | Determinate Nix 3.24.2 / Nix 2.35.3；不是安装前提 |
| 目标 NixOS           | `26.05.20261105.c56a87d`，Yarara                  |
| 目标 Linux 内核      | `6.18.60`                                         |
| Nixpkgs 提交         | `c56a87d8e41ce69bd2af57eb35dcc117a9dfca33`        |
| Disko 提交           | `cedd626e11b635470fa6f9fdb8ad79b0075dd7f9`        |
| nixos-anywhere 版本  | `1.13.0`                                          |
| nixos-anywhere 提交  | `58132e1d1f813b845382a2aeca4203b18d2ac807`        |
| 临时安装镜像发布标签 | `nixos-25.11`，文件名包含 `x86_64-linux`          |
| 临时环境实际内核     | `7.0.9`                                           |

临时环境显示 NixOS 25.11，最终安装的是 NixOS 26.05；安装介质版本和目标系统版本不必相同。临时环境只负责分区、联网和执行安装。

镜像文件为 `nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz`：

- 下载地址：[本次使用的 kexec 安装镜像](https://github.com/nix-community/nixos-images/releases/download/nixos-25.11/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz)。
- 文件大小：`439211794` 字节，约 419 MiB。
- SHA-256：`64020c75b021a2e3f72418d1f1bfa975fcd391f57dee38ab3aef639991edc860`。

发布标签下的附件未来可能被替换或删除。**如果校验值不一致，不要直接改成新摘要继续执行。** 应找回归档的镜像，或对新镜像重新完成验证。锁文件固定了源码输入，不能保证第三方下载地址永久保留；长期复现需要同时保存安装镜像。

## 2. 安装原理与执行位置

本次不调用腾讯云重装 API，而是通过 SSH 操作虚拟机内部。Lighthouse 的镜像制作接口主要从已有实例制作镜像；CVM 到 Lighthouse 的共享还有外部导入镜像和操作系统范围限制，不能把它当作任意上传 NixOS ISO 的入口。参见[腾讯云共享镜像限制](https://cloud.tencent.com/document/product/1207/63264)。

安装路径如下：

```text
本地电脑：准备配置、固定输入、构建系统、进行 KVM 测试
    │ SSH
    ▼
Ubuntu：下载 kexec 安装镜像，把临时内核和安装环境载入内存
    │ kexec -c
    ▼
临时 NixOS：在内存中运行，恢复网络与 SSH，释放原系统盘
    │ disko + nixos-install
    ▼
/dev/vda：新 GPT 分区、ext4 根分区、swap、NixOS、GRUB
    │ 普通重启
    ▼
虚拟 BIOS → GRUB → 磁盘上的 NixOS → DHCP → SSH
```

KVM 提供独立的虚拟 CPU、内存和磁盘；`kexec` 替换的是这台虚拟机内部的内核。此过程不需要腾讯云宿主机权限。临时安装环境不依赖原系统盘上的 Ubuntu 根文件系统，因此可以重新格式化该盘。

`nixos-anywhere` 的工作可以按 `kexec`、`disko`、`install`、`reboot` 分阶段执行。本次将阶段分开，先验证临时环境，再清盘安装，最后单独重启。工具的阶段定义可查阅[本次固定版本的源码](https://github.com/nix-community/nixos-anywhere/blob/58132e1d1f813b845382a2aeca4203b18d2ac807/src/nixos-anywhere.sh)。

| 阶段                     | 从哪里执行命令 | SSH 目标用户                               | 对服务器的影响                                       |
| ------------------------ | -------------- | ------------------------------------------ | ---------------------------------------------------- |
| 本地准备、构建和 VM 测试 | 本地电脑       | 无                                         | 不改变服务器系统                                     |
| Ubuntu 检查、镜像预下载  | 本地发起 SSH   | `ubuntu@tencent`                           | 检查信息、在家目录保存安装材料                       |
| `--phases kexec`         | 本地电脑       | 初始为 `ubuntu@tencent`，工具随后切到 root | 当前 Ubuntu 停止运行，进入临时系统；不执行磁盘格式化 |
| 临时环境核验             | 本地发起 SSH   | `root@tencent`                             | 只读检查                                             |
| `--phases disko,install` | 本地电脑       | `root@tencent`                             | **清空目标盘并安装系统**                             |
| 重启及验收               | 本地发起 SSH   | 重启前 root，重启后 `star@tencent`         | 从新系统盘启动并检查                                 |

下文的 Bash 代码块均在**本地电脑**执行；代码中的 `ssh ... <<'REMOTE_...'` 会把其中的命令交给服务器。不要先登录服务器，再把本地的构建命令整段粘进去。

如果通过 Codex 执行，SSH 和需要访问宿主机 Nix daemon、KVM 的命令使用沙箱外执行。本次沙箱内遇到过 SSH 系统配置权限检查错误，以及无法连接 Nix daemon socket；这些不是服务器故障。在普通终端里不需要添加所谓“沙箱外参数”。

## 3. 本地准备和 SSH 连接

### 3.1 本地所需环境

本次本地机器是 x86_64 Linux，已经安装 Nix。需要 Bash、OpenSSH、`jq`、`curl`、`sha256sum` 等命令；本地虚拟机测试还需要可用的 `/dev/kvm`。如果本地没有 Nix，先按 [Nix 安装说明](https://nix.dev/install-nix) 准备好本地环境。

**Ubuntu 服务器不需要预先安装 Nix 或 Home Manager。** 本次恰好已有 Determinate Nix，但进入临时环境和安装新系统并不依赖保留它。本地构建完成后，服务器会从二进制缓存下载可获取的软件包，配置专属的构建结果通过 SSH 复制过去。

先进入 Bash，后续代码使用 Bash 的变量和语法：

```bash
bash
```

在这个 Bash 会话中初始化变量：

```bash
set -euo pipefail

# 仅影响当前终端及其子进程，保留已有的其他 Nix 配置。
export NIX_CONFIG="${NIX_CONFIG-}"$'\nextra-experimental-features = nix-command flakes\n'

export TENCENT_SSH_HOST=tencent
export TENCENT_SOURCE_USER=ubuntu
export TENCENT_SSH_KEY="$HOME/.ssh/id_ed25519"
export TENCENT_HOSTNAME=tencent-tokyo-2c2g
export TENCENT_WORK="$(mktemp -d /tmp/tencent-nixos-install.XXXXXX)"
export TENCENT_FLAKE="path:$TENCENT_WORK"
export TENCENT_KEXEC_URL='https://github.com/nix-community/nixos-images/releases/download/nixos-25.11/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz'
export TENCENT_KEXEC_SHA256='64020c75b021a2e3f72418d1f1bfa975fcd391f57dee38ab3aef639991edc860'

printf '本次本地工作目录：%s\n' "$TENCENT_WORK"
command -v nix ssh jq curl sha256sum
nix --version
test -r "$TENCENT_SSH_KEY"

# 保存变量，便于换终端后继续。这里只包含路径和参数，不包含私钥内容。
declare -p NIX_CONFIG TENCENT_SSH_HOST TENCENT_SOURCE_USER TENCENT_SSH_KEY \
  TENCENT_HOSTNAME TENCENT_WORK TENCENT_FLAKE TENCENT_KEXEC_URL \
  TENCENT_KEXEC_SHA256 > "$TENCENT_WORK/session.env"
```

记下打印出来的目录。换终端后，进入 Bash，再执行 `source /实际工作目录/session.env`。不要重新初始化一个新目录后，误以为前面构建的文件仍在里面。

本次历史目录是 `/tmp/tencent-nixos-install.UIbnjf`，但复现**不依赖该目录继续存在**。下文会重新生成所需的所有配置文件。`/tmp` 可能被清理，安装完成后应另行保存配置和锁文件。

这里的主机名变量必须与第 6 节 flake 属性名和系统配置一致。如果只是复现这台机器，保持给出的名称即可；若要换名称或用户，需要同时修改配置文件，不能只改终端变量。

### 3.2 检查 SSH 别名和密钥

本次别名的关键配置等价于：

```ssh-config
Host tencent
    HostName 203.0.113.10
    User ubuntu
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

这段用于说明配置内容；如果别名已经由现有配置管理，不要再重复追加同名条目。可以这样检查最终生效值：

```bash
ssh -G "$TENCENT_SSH_HOST" \
  | awk '/^(hostname|user|port|identityfile|identitiesonly|stricthostkeychecking|userknownhostsfile) /'

ssh -i "$TENCENT_SSH_KEY" \
  -o IdentitiesOnly=yes \
  -o ConnectTimeout=15 \
  "$TENCENT_SOURCE_USER@$TENCENT_SSH_HOST" \
  'id; hostname; sudo -n true'
```

要求：连接到正确的服务器，登录用户是 `ubuntu`，并且 `sudo -n true` 成功。这里显式指定用户，所以即使本地别名以后改成了 `User star`，重装回 Ubuntu 后仍能按正确账号连接。

首次连接或重装后遇到主机密钥提示，应先确认目标实例和主机身份，再继续。不要把主机密钥问题误判成密码错误。本文后面记录了此次 `/dev/null` known_hosts 配置带来的特殊现象。

如果使用加密的 SSH 私钥，先确保 SSH agent 已能使用它；后续安装命令使用非交互登录。本文中的公钥是这次实际使用的公钥，私钥始终留在本地。

## 4. 检查 Ubuntu 是否符合条件

先确认腾讯云控制台仍可以访问该实例的 VNC/管理终端、重启和重装入口。SSH 是安装期间的主要通道；如果新环境无法联网，控制台用于看启动输出和恢复。本次没有通过 API 自动创建快照，用户已明确选择无数据保留的全新安装；不能把本文理解为已经有一份可回滚的云快照。

### 4.1 只读检查

```bash
ssh -i "$TENCENT_SSH_KEY" \
  -o BatchMode=yes \
  -o ConnectTimeout=15 \
  "$TENCENT_SOURCE_USER@$TENCENT_SSH_HOST" 'bash -s' <<'REMOTE_PREFLIGHT'
set -euo pipefail

id
sudo -n true
uname -a
cat /etc/os-release
systemd-detect-virt
getconf _NPROCESSORS_ONLN
free -h
awk '/^(MemTotal|MemAvailable|SwapTotal):/ { print }' /proc/meminfo

if [ -d /sys/firmware/efi ]; then
  printf 'boot_mode=UEFI\n'
else
  printf 'boot_mode=BIOS_or_EFI_not_exposed\n'
fi
cat /proc/cmdline
sudo -n dmesg | grep -Ei 'efi:|EFI v|BIOS-provided|DMI:|Hypervisor detected' || true

cat /proc/sys/kernel/kexec_load_disabled
if [ -r /sys/kernel/security/lockdown ]; then
  cat /sys/kernel/security/lockdown
fi
grep -E 'CONFIG_(KEXEC|EFI=|SECURITY_LOCKDOWN|LOCK_DOWN|IMA_APPRAISE)' "/boot/config-$(uname -r)"
sudo -n sh -c 'grep -E "^(CapEff|CapBnd|NoNewPrivs|Seccomp):" /proc/self/status'

lsblk -o NAME,PATH,SIZE,TYPE,FSTYPE,PARTTYPE,MOUNTPOINTS
findmnt -rn -o SOURCE,TARGET,FSTYPE | grep -E '^/dev/'
df -hT / /tmp
ip -brief address
ip -4 route show
networkctl status eth0 --no-pager --lines=0 || true

for tool_name in bash tar gzip xz cpio curl wget setsid sudo; do
  command -v "$tool_name" || printf 'MISSING=%s\n' "$tool_name"
done
setsid --help | grep -- --wait
REMOTE_PREFLIGHT
```

本次通过的关键条件：

- `x86_64`、KVM，SSH 正常，普通用户有免密 sudo。
- 约 1.92 GiB 物理内存，满足项目文档中至少 1.5 GB 的要求。swap 不计入该物理内存条件。
- `CONFIG_KEXEC=y`，`CONFIG_KEXEC_FILE=y`，`kexec_load_disabled=0`。
- lockdown 输出为 `[none] integrity confidentiality`，`CONFIG_KEXEC_SIG_FORCE` 未启用。
- sudo 后有效权限和权限上限均包含 `CAP_SYS_BOOT`；此次 `CapEff` 和 `CapBnd` 为 `000001ffffffffff`，`NoNewPrivs=0`、`Seccomp=0`。
- 目标盘明确为唯一的 40 GiB 系统盘 `/dev/vda`。
- 当前实际通过 BIOS 启动；后面的分区和 GRUB 配置以此为前提。
- 网卡为 VirtIO，IPv4 和默认路由通过 DHCP 获取。

如果再次检查发现机器改为 UEFI、架构不同、目标盘变更或 `kexec` 被禁用，应先调整安装方案，不要直接沿用这里的磁盘配置。只读检查通过表示具备前提；真正切入安装环境仍要在后续阶段验证。

### 4.2 检查数据与补齐必要工具

此次只发现基础系统服务、SSH、Nix daemon 和腾讯云 TAT；`/opt`、`/srv` 为空，`/home/ubuntu` 约 140 KiB。再次安装时，仍要重新盘点：

```bash
ssh -i "$TENCENT_SSH_KEY" \
  -o BatchMode=yes \
  "$TENCENT_SOURCE_USER@$TENCENT_SSH_HOST" 'bash -s' <<'REMOTE_DATA_CHECK'
systemctl list-units --type=service --state=running --no-pager --no-legend
sudo -n ss -lntup
sudo -n ls -la /home/ubuntu /root /opt /srv
sudo -n du -xhd1 /home /opt /srv /var/lib
REMOTE_DATA_CHECK
```

这些检查不能自动证明所有目录都没有重要数据；本次清盘依据还包括用户明确确认“无需保留旧数据，全新安装”。如果需要保留数据，先备份到服务器之外。

若前面的检查显示缺少 `cpio`、下载工具等，可在 Ubuntu 上补齐：

```bash
ssh -i "$TENCENT_SSH_KEY" \
  "$TENCENT_SOURCE_USER@$TENCENT_SSH_HOST" 'bash -s' <<'REMOTE_INSTALL_TOOLS'
set -euo pipefail
sudo -n apt-get update
sudo -n apt-get install -y curl wget ca-certificates tar gzip xz-utils cpio util-linux
REMOTE_INSTALL_TOOLS
```

本次这些工具已具备，没有执行上面的补装。安装镜像自带 `kexec` 可执行文件，因此 Ubuntu 上有没有系统级 `kexec-tools`，与内核是否支持 `kexec` 是两件事；不要仅因 `command -v kexec` 无输出，就断定不能安装。

## 5. 在服务器预下载并校验安装镜像

服务器到 GitHub 的下载速度本次约 23 MiB/s，419 MiB 镜像约 18 秒下载完成。先在 Ubuntu 的家目录准备文件并做校验：

```bash
ssh -i "$TENCENT_SSH_KEY" \
  -o BatchMode=yes \
  "$TENCENT_SOURCE_USER@$TENCENT_SSH_HOST" \
  bash -s -- "$TENCENT_KEXEC_URL" "$TENCENT_KEXEC_SHA256" <<'REMOTE_DOWNLOAD'
set -euo pipefail
installer_url="$1"
installer_sha256="$2"
installer_name=nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz

install -d -m 700 "$HOME/nixos-install-prep"
cd "$HOME/nixos-install-prep"
curl --fail --location --retry 3 --connect-timeout 15 \
  --output "$installer_name.part" "$installer_url"
printf '%s  %s\n' "$installer_sha256" "$installer_name.part" | sha256sum --check -
mv "$installer_name.part" "$installer_name"
wc -c "$installer_name"
REMOTE_DOWNLOAD
```

应看到校验 `OK` 和 `439211794` 字节。

**这次正式执行 `nixos-anywhere --kexec URL` 时，工具仍然在服务器重新下载并解压镜像到 `~/kexec`，不会自动复用 `~/nixos-install-prep` 里的预下载文件。** 预下载用于确认连通性和核对版本，不能描述成工具已经强制校验其第二次下载。工具的 `--kexec URL` 本身没有传入上述 SHA-256 的选项。

如果要长期保留这份已校验镜像，可在清盘前复制到本地独立的归档目录。大镜像不放进 flake 目录，避免每次求值都把它当成 flake 源文件复制：

```bash
export TENCENT_ARCHIVE_DIR="$(mktemp -d /tmp/tencent-nixos-archive.XXXXXX)"
declare -p TENCENT_ARCHIVE_DIR >> "$TENCENT_WORK/session.env"
scp -i "$TENCENT_SSH_KEY" \
  "$TENCENT_SOURCE_USER@$TENCENT_SSH_HOST:nixos-install-prep/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz" \
  "$TENCENT_ARCHIVE_DIR/"

printf '%s  %s\n' "$TENCENT_KEXEC_SHA256" \
  "$TENCENT_ARCHIVE_DIR/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz" \
  | sha256sum --check -
```

这一步是为以后复现补充的归档步骤，本次实际安装未将镜像归档到本地。归档目录仍在 `/tmp`，需要复制到长期保存的位置。工具也支持把本地 tarball 路径传给 `--kexec`，由本地上传该文件；那样可以直接使用已校验的字节，但上传会经过本地网络。下面的主流程保留这次使用的服务器直接下载方式。

## 6. 创建完整的最小 NixOS 配置

下面四个文件是实际安装成功的配置。写入刚才创建的本地工作目录，不依赖本仓库的根 flake。

### 6.1 `flake.nix`

```bash
cat > "$TENCENT_WORK/flake.nix" <<'NIX_FLAKE'
{
  description = "Minimal NixOS installation for tencent-tokyo-2c2g";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/c56a87d8e41ce69bd2af57eb35dcc117a9dfca33";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, disko, ... }: {
    nixosConfigurations.tencent-tokyo-2c2g = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./configuration.nix
        ./disk-config.nix
      ];
    };
  };
}
NIX_FLAKE
```

### 6.2 `flake.lock`

必须保存这份锁文件。虽然 `flake.nix` 里的 Disko URL 没有直接写提交号，但锁文件已经固定了它。本次安装工具会使用 `--no-write-lock-file`，复现时不需要更新输入。

```bash
cat > "$TENCENT_WORK/flake.lock" <<'NIX_LOCK'
{
  "nodes": {
    "disko": {
      "inputs": {
        "nixpkgs": [
          "nixpkgs"
        ]
      },
      "locked": {
        "lastModified": 1792526520,
        "narHash": "sha256-3hSJlv8mUVnZPMWK2+CM7a9O+nR6Z4mCh27NfLCmTPc=",
        "owner": "nix-community",
        "repo": "disko",
        "rev": "cedd626e11b635470fa6f9fdb8ad79b0075dd7f9",
        "type": "github"
      },
      "original": {
        "owner": "nix-community",
        "repo": "disko",
        "type": "github"
      }
    },
    "nixpkgs": {
      "locked": {
        "lastModified": 1793865203,
        "narHash": "sha256-/cpdPHaySDIyCgZI6EWngiM6jK3YLUNzv1b7lTzy6Bk=",
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "c56a87d8e41ce69bd2af57eb35dcc117a9dfca33",
        "type": "github"
      },
      "original": {
        "owner": "NixOS",
        "repo": "nixpkgs",
        "rev": "c56a87d8e41ce69bd2af57eb35dcc117a9dfca33",
        "type": "github"
      }
    },
    "root": {
      "inputs": {
        "disko": "disko",
        "nixpkgs": "nixpkgs"
      }
    }
  },
  "root": "root",
  "version": 7
}
NIX_LOCK
```

### 6.3 `configuration.nix`

`loginKey` 是本次实际使用的 SSH 公钥。若换了私钥，必须同时替换这里的公钥，并在构建前确认匹配。这里只保存公钥，不把私钥复制到服务器或写进 Nix 配置。

```bash
cat > "$TENCENT_WORK/configuration.nix" <<'NIX_CONFIGURATION'
{ modulesPath, ... }:
let
  loginKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRIktF2OSYpPnCDt4hEJl2KcQMSWKhVu0ZKGf8bSwz2 star";
in
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  networking.hostName = "tencent-tokyo-2c2g";

  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "virtio_pci"
    "virtio_scsi"
    "virtio_blk"
    "sd_mod"
  ];
  boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty0" ];

  # Match the virtual NIC independently of eth0/ens3 naming.
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.networks."10-uplink" = {
    matchConfig.Driver = "virtio_net";
    networkConfig.DHCP = "ipv4";
    dhcpV4Config.ClientIdentifier = "mac";
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  networking.firewall.allowedTCPPorts = [ 22 ];

  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = [ loginKey ];
  users.users.star = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ loginKey ];
  };
  security.sudo.wheelNeedsPassword = false;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = 1;
    cores = 2;
  };

  system.stateVersion = "26.05";
}
NIX_CONFIGURATION
```

这份配置有几处需要保持一致：

- 主机名为 `tencent-tokyo-2c2g`，普通用户为 `star`。
- `star` 和 root 均使用指定公钥登录；SSH 密码认证和键盘交互认证关闭。`PermitRootLogin = "prohibit-password"` 允许 root 使用密钥登录。
- `star` 属于 `wheel`，sudo 不要求密码。这里没有设置一个可用于控制台密码登录的已知用户密码。
- `users.mutableUsers = false`，账号由配置管理。以后更改密码、用户或密钥时，应同步维护声明式配置。
- 使用 `systemd-networkd`，按 `virtio_net` 驱动匹配网卡。因此 Ubuntu 中叫 `eth0`、NixOS 中叫 `ens3` 都可以匹配，不依赖旧接口名。
- IPv4 通过 DHCP 获取，使用基于 MAC 的 DHCPv4 客户端标识。DNS 和网关不写死。
- GRUB 使用 BIOS 模式。**这里没有手动设置 `boot.loader.grub.device`**，因为本次 Disko 的 BIOS 分区配置会提供目标设备；重复设置会触发断言，见后文。
- 设置串口和普通控制台输出，便于云控制台观察引导。
- 本次固定 `system.stateVersion = "26.05"`；以后更新软件版本时，不应机械地跟着修改它。

可以从本地私钥导出公钥，只比较算法和公钥主体，忽略末尾注释：

```bash
TENCENT_PRIVATE_PUBLIC="$(ssh-keygen -y -f "$TENCENT_SSH_KEY" | awk '{print $1 " " $2}')"
TENCENT_CONFIG_PUBLIC="$(sed -n 's/^  loginKey = "\(.*\)";/\1/p' "$TENCENT_WORK/configuration.nix" | awk '{print $1 " " $2}')"
test "$TENCENT_PRIVATE_PUBLIC" = "$TENCENT_CONFIG_PUBLIC"
printf '配置中的公钥与本地私钥匹配\n'
```

### 6.4 `disk-config.nix`

```bash
cat > "$TENCENT_WORK/disk-config.nix" <<'NIX_DISKS'
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        bios = {
          priority = 1;
          size = "1M";
          type = "EF02";
        };
        swap = {
          priority = 2;
          size = "2G";
          content.type = "swap";
        };
        root = {
          priority = 3;
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
NIX_DISKS
```

最终布局：

| 分区        | 大小                | 类型和用途                                            |
| ----------- | ------------------- | ----------------------------------------------------- |
| `/dev/vda1` | 1 MiB               | GPT `EF02`，BIOS Boot Partition，供 GRUB 嵌入引导代码 |
| `/dev/vda2` | 2 GiB               | swap，分区标签 `disk-main-swap`                       |
| `/dev/vda3` | 剩余空间，约 38 GiB | ext4 根分区，标签 `disk-main-root`，挂载 `/`          |

`priority` 明确分区顺序，避免把占满剩余空间的根分区放到 swap 前面。`device = "/dev/vda"` 是清盘范围，必须与前面核验一致。最终文件系统配置使用分区标签，重新格式化后生成的 UUID 不需要写进本文。

## 7. 固定安装工具，构建并验证配置

### 7.1 构建本次版本的 nixos-anywhere

```bash
nix build --no-write-lock-file \
  github:nix-community/nixos-anywhere/58132e1d1f813b845382a2aeca4203b18d2ac807 \
  --out-link "$TENCENT_WORK/nixos-anywhere"

export TENCENT_ANYWHERE="$TENCENT_WORK/nixos-anywhere/bin/nixos-anywhere"
declare -p TENCENT_ANYWHERE >> "$TENCENT_WORK/session.env"
"$TENCENT_ANYWHERE" --help
```

本次当时执行的是未写提交号的 `github:nix-community/nixos-anywhere`，实际解析到表中的提交，构建出的版本为 1.13.0。这里将提交号补进命令，避免以后主分支更新影响复现。

### 7.2 配置求值检查

```bash
nix eval --json --no-write-lock-file \
  "$TENCENT_FLAKE#nixosConfigurations.$TENCENT_HOSTNAME.config" \
  --apply 'c: {
    hostname = c.networking.hostName;
    release = c.system.nixos.release;
    stateVersion = c.system.stateVersion;
    disk = c.disko.devices.disk.main.device;
    grubDevices = c.boot.loader.grub.devices;
    systemdBoot = c.boot.loader.systemd-boot.enable;
    ssh = c.services.openssh.enable;
    user = c.users.users.star.name;
    swapDevices = map (s: s.device) c.swapDevices;
  }' > "$TENCENT_WORK/evaluated-plan.json"

jq . "$TENCENT_WORK/evaluated-plan.json"
```

本次结果：

```json
{
  "disk": "/dev/vda",
  "grubDevices": ["/dev/vda"],
  "hostname": "tencent-tokyo-2c2g",
  "release": "26.05",
  "ssh": true,
  "stateVersion": "26.05",
  "swapDevices": ["/dev/disk/by-partlabel/disk-main-swap"],
  "systemdBoot": false,
  "user": "star"
}
```

### 7.3 构建系统和 Disko 脚本

```bash
nix build --no-link --json --no-write-lock-file \
  "$TENCENT_FLAKE#nixosConfigurations.$TENCENT_HOSTNAME.config.system.build.toplevel" \
  "$TENCENT_FLAKE#nixosConfigurations.$TENCENT_HOSTNAME.config.system.build.diskoScript" \
  > "$TENCENT_WORK/build-results.json" \
  2> "$TENCENT_WORK/build.log"

export TENCENT_SYSTEM="$(jq -er '.[] | select(.outputs.out | contains("-nixos-system-")) | .outputs.out' "$TENCENT_WORK/build-results.json")"
export TENCENT_DISKO="$(jq -er '.[] | select(.outputs.out | endswith("-disko")) | .outputs.out' "$TENCENT_WORK/build-results.json")"
test -d "$TENCENT_SYSTEM"
test -x "$TENCENT_DISKO"
declare -p TENCENT_SYSTEM TENCENT_DISKO >> "$TENCENT_WORK/session.env"

printf '系统：%s\n分区脚本：%s\n' "$TENCENT_SYSTEM" "$TENCENT_DISKO"
nix path-info -Sh "$TENCENT_SYSTEM" "$TENCENT_DISKO"
```

本次生成的路径及闭包大小如下，供核对历史记录；后面的命令使用刚生成的变量，不直接假定这些旧路径在另一台电脑上存在：

```text
系统：
/nix/store/2kfs45gkyf2k3ndq0d6p6jcxsqycd67r-nixos-system-tencent-tokyo-2c2g-26.05.20261105.c56a87d
约 1.2 GiB

Disko：
/nix/store/437whb5bvqz1m9vfc9g62lxxn63cw0m8-disko
约 439 MiB
```

这是构建，不会执行分区脚本，更不会激活本地系统。不要直接在本地执行 `$TENCENT_DISKO`，它里面指定了 `/dev/vda`，执行位置错误会操作错误的磁盘。

### 7.4 本地 KVM 安装和启动测试

```bash
ls -l /dev/kvm

"$TENCENT_ANYWHERE" \
  --flake "$TENCENT_FLAKE#$TENCENT_HOSTNAME" \
  --build-on local \
  --vm-test \
  > "$TENCENT_WORK/vm-test.log" 2>&1

tail -n 20 "$TENCENT_WORK/vm-test.log"
```

这是在本地隔离的测试虚拟机中验证分区、安装和引导，没有指定腾讯云 SSH 目标。测试会将磁盘配置适配到测试磁盘，因此日志里出现 `/dev/vdb` 是正常的，不代表真实目标改成了 `/dev/vdb`。

本次测试成功，日志包含 `Installation finished. No error reported.`、新系统启动输出和 `test script finished in 37.28s`，整个命令退出码为 0。37.28 秒是测试脚本的执行时间，不包含前面的依赖下载和构建。

如果本地缺少 KVM 或权限不足，应先解决本地测试条件；跳过这一步就少了一项验证，不能把历史上的测试成功当作新配置已经通过测试。不要为了这个步骤在 2 GiB 的目标服务器里再运行一层测试虚拟机。

### 7.5 准备安装后保留的配置文件

`--extra-files` 的目录内容会相对于新系统的 `/` 复制，因此应准备 `extra-files/etc/nixos`：

```bash
install -d "$TENCENT_WORK/extra-files/etc/nixos"
for config_name in flake.nix flake.lock configuration.nix disk-config.nix; do
  install -m 0644 "$TENCENT_WORK/$config_name" \
    "$TENCENT_WORK/extra-files/etc/nixos/$config_name"
done
sha256sum "$TENCENT_WORK/extra-files/etc/nixos/"*
```

如果之后修改配置，需要重新构建、重新验证，并重新复制这四个文件，避免实际安装的系统与 `/etc/nixos` 保存的源码不一致。

## 8. 切入临时安装环境：只执行 kexec

**此步骤会停止当前 Ubuntu，已有 SSH 会话会断开。该阶段不执行分区和格式化。**

本次 Ubuntu 26.04 / Linux 7.0 必须加入 `--kexec-extra-flags '-c'` 才成功。下面直接采用成功的参数，不要求先重现一次失败。

```bash
"$TENCENT_ANYWHERE" \
  --flake "$TENCENT_FLAKE#$TENCENT_HOSTNAME" \
  --target-host "$TENCENT_SOURCE_USER@$TENCENT_SSH_HOST" \
  --build-on local \
  --phases kexec \
  -i "$TENCENT_SSH_KEY" \
  --ssh-option BatchMode=yes \
  --ssh-option ConnectTimeout=15 \
  --ssh-option LogLevel=ERROR \
  --kexec "$TENCENT_KEXEC_URL" \
  --kexec-extra-flags '-c' \
  > "$TENCENT_WORK/kexec-compat.log" 2>&1

tail -n 20 "$TENCENT_WORK/kexec-compat.log"
```

正常过程中会看到：

```text
### Switching system into kexec ###
machine will boot into nixos in 6s...
...
### Gathering machine facts ###
### Done! ###
```

中途可能有一次 SSH `Connection timed out`，但工具随后仍可能连上临时环境并正常结束。本次就是如此。应结合最终退出状态和下面的实际连接检查判断，不能只看一条中间超时。

安装器会将必要的 SSH 授权信息和网络信息带入临时环境。切入之后使用 **root** 登录，不再使用 Ubuntu 的普通用户：

```bash
ssh -i "$TENCENT_SSH_KEY" \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  "root@$TENCENT_SSH_HOST" 'bash -s' <<'REMOTE_VERIFY_INSTALLER'
set -euo pipefail
cat /etc/os-release
. /etc/os-release
test "$ID" = nixos
test "${VARIANT_ID:-}" = installer
uname -r
free -h
ip -brief address
ip -4 route show
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS
curl --fail --silent --show-error --connect-timeout 10 --max-time 20 \
  https://cache.nixos.org/nix-cache-info
REMOTE_VERIFY_INSTALLER
```

本次实测：

- `/etc/os-release` 为 NixOS 25.11，`VARIANT_ID=installer`，内核 `7.0.9`。
- 内存约 701 MiB 已用、1.2 GiB 可用，尚未启用 swap。
- 网卡变为 `ens3`，仍获取 `10.7.0.10/22` 和 `10.7.0.1` 默认网关。
- `/nix/.ro-store` 来自内存中的压缩镜像；原 `/dev/vda1`、`/dev/vda2`、`/dev/vda3` 没有挂载。
- root SSH 和 Nix 缓存访问正常。

**只有确认进入临时 NixOS，目标盘正确且不再作为当前根文件系统使用，才继续下一节。** 如果仍是 Ubuntu，或 root SSH 不通，先查后面的恢复说明。

## 9. 清空系统盘并安装：disko + install

再次确认：本节会清空 `/dev/vda`，新的文件系统会替换整个旧系统。本次安装前用户已确认不保留任何旧数据；以后重复执行时仍需要自行确认这一点。

先在终端显示将要使用的目标和构建结果：

```bash
printf 'SSH 目标：root@%s\n新主机名：%s\n目标磁盘：/dev/vda\n' \
  "$TENCENT_SSH_HOST" "$TENCENT_HOSTNAME"
printf '系统：%s\nDisko：%s\n' "$TENCENT_SYSTEM" "$TENCENT_DISKO"
cat "$TENCENT_WORK/disk-config.nix"
```

确认无误后，从本地执行：

```bash
"$TENCENT_ANYWHERE" \
  --store-paths "$TENCENT_DISKO" "$TENCENT_SYSTEM" \
  --extra-files "$TENCENT_WORK/extra-files" \
  --target-host "root@$TENCENT_SSH_HOST" \
  --build-on local \
  --phases disko,install \
  -i "$TENCENT_SSH_KEY" \
  --ssh-option BatchMode=yes \
  --ssh-option ConnectTimeout=15 \
  --ssh-option LogLevel=ERROR \
  > "$TENCENT_WORK/install.log" 2>&1

tail -n 30 "$TENCENT_WORK/install.log"
```

这里故意没有包含 `reboot` 阶段，安装后保留临时环境，先检查磁盘上的结果。

本次执行的主要动作：

1. 把 Disko 脚本及依赖提供给临时环境。
2. 清理旧磁盘结构，创建新的 GPT、BIOS 引导分区、swap 和 ext4。
3. 将新根分区挂载到 `/mnt`。
4. 把目标系统闭包写入新根分区的 Nix store。
5. 将四个配置文件复制到 `/mnt/etc/nixos`。
6. 执行 `nixos-install --no-root-passwd --no-channel-copy --system ...`。
7. 安装 BIOS 模式的 GRUB 到 `/dev/vda`。

默认启用的目标端替代下载会让服务器从可用缓存获取软件包；配置专属结果通过 SSH 传输。系统闭包写入 `/mnt` 对应的磁盘存储，不要求把完整的约 1.2 GiB 目标系统全部放进临时环境的可写内存文件系统。

本次成功日志末尾为：

```text
### Copying extra files ###
### Installing NixOS ###
installing the boot loader...
setting up /etc...
Not checking switch inhibitors (action = boot)
updating GRUB 2 menu...
installing the GRUB 2 boot loader on /dev/vda...
Installing for i386-pc platform.
Installation finished. No error reported.
installation finished!
### Done! ###
```

`i386-pc` 是 GRUB 的 BIOS 平台名称，不表示安装了 32 位 NixOS。目标系统仍为 `x86_64-linux`。

## 10. 重启前检查磁盘上的系统

检查配置摘要、GRUB、内核、initrd、用户和文件系统：

```bash
sha256sum "$TENCENT_WORK/extra-files/etc/nixos/"*

ssh -i "$TENCENT_SSH_KEY" \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  "root@$TENCENT_SSH_HOST" \
  bash -s -- "$TENCENT_SYSTEM" <<'REMOTE_VERIFY_DISK'
set -euo pipefail
installed_system="$1"

sha256sum /mnt/etc/nixos/*
test -d "/mnt$installed_system"
test -f /mnt/boot/grub/grub.cfg
test -f /mnt/boot/grub/i386-pc/core.img
ls -lh /mnt/boot/grub/i386-pc/core.img

grep -E 'menuentry|linux |initrd |search.*fs-uuid' /mnt/boot/grub/grub.cfg
awk -F: '$1 == "star" {print $1, $3, $4, $6, $7}' /mnt/etc/passwd
ls -l /mnt/nix/var/nix/profiles/system*

# 在目标根目录内读取绝对符号链接，避免解析到临时环境的 /nix/store。
chroot /mnt "$installed_system/sw/bin/cat" /etc/fstab
chroot /mnt "$installed_system/sw/bin/test" -f "$installed_system/kernel"
chroot /mnt "$installed_system/sw/bin/test" -f "$installed_system/initrd"

blkid /dev/vda2 /dev/vda3
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS
REMOTE_VERIFY_DISK
```

应确认：

- 本地和远端四个配置文件的摘要一致。
- GRUB 菜单中的内核和 `init=` 指向本次目标系统。
- `/mnt/etc/passwd` 中已有 `star`，家目录为 `/home/star`。
- 目标系统 profile 指向本次构建的 `nixos-system-tencent-tokyo-2c2g-...`。
- 根分区使用 `/dev/disk/by-partlabel/disk-main-root`，swap 使用 `disk-main-swap`。

本次目标 `fstab` 的有效内容为：

```fstab
/dev/disk/by-partlabel/disk-main-root / ext4 x-initrd.mount,defaults 0 1
/dev/disk/by-partlabel/disk-main-swap none swap defaults
```

本次四个文件的 SHA-256：

```text
30e6582b1b755e6c05d687e07a57fbe36a3af1365bcd60c66cfeb6af5f3f1d72  configuration.nix
99ad9f4204cd4eca29830afd267a8b0d55e66b7ce767d20badc60c4632c807c6  disk-config.nix
ffeb56efe333d58f9ea280c50179e3b10129dc652e6763cbb5a0ff16cccf97b9  flake.lock
5872017378b226420862ba408cf2294245c4dd1401f7ee38f9715638e3b31dd2  flake.nix
```

如果改了公钥、配置内容或格式，文件摘要变化是正常的；应比较自己此次准备的文件与服务器上的副本，而不是强行追求与历史记录相同。

## 11. 普通重启并验收

### 11.1 从临时环境重启

```bash
ssh -i "$TENCENT_SSH_KEY" \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  "root@$TENCENT_SSH_HOST" 'bash -s' <<'REMOTE_REBOOT'
set -euo pipefail
sync
systemctl reboot
REMOTE_REBOOT
```

这是普通重启，接下来由虚拟 BIOS 从系统盘上的 GRUB 启动 NixOS。SSH 连接可能正常返回，也可能因重启被关闭，应以随后能否连上新系统为准。

新系统的普通用户是 `star`。即使本地 `tencent` 别名仍写着 `User ubuntu`，也可以显式指定新用户：

```bash
ssh -i "$TENCENT_SSH_KEY" "star@$TENCENT_SSH_HOST"
```

首次连接新系统如出现主机密钥变化提示，先核对实例身份，再处理 known_hosts。这里的 SSH 命令不要求新增名为 `star` 的云平台账号。

### 11.2 完整验收命令

回到本地 Bash 会话执行：

```bash
ssh -i "$TENCENT_SSH_KEY" \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  "star@$TENCENT_SSH_HOST" \
  bash -s -- "$TENCENT_SYSTEM" "$TENCENT_HOSTNAME" <<'REMOTE_ACCEPTANCE'
set -euo pipefail
expected_system="$1"
expected_hostname="$2"

hostname
id
sudo -n id
nixos-version
uname -r
readlink -f /run/current-system
test "$(hostname)" = "$expected_hostname"
test "$(readlink -f /run/current-system)" = "$expected_system"

findmnt -n -o SOURCE,FSTYPE,OPTIONS /
test "$(findmnt -n -o FSTYPE /)" = ext4
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS
swapon --show
free -h

systemctl is-active sshd systemd-networkd systemd-resolved nix-daemon.socket
systemctl --failed --no-pager

ip -brief address
ip -4 route show
getent ahostsv4 cache.nixos.org
curl --fail --silent --show-error --connect-timeout 10 --max-time 20 \
  https://cache.nixos.org/nix-cache-info

ls -l /etc/nixos
sha256sum /etc/nixos/*
nix --version
REMOTE_ACCEPTANCE
```

`systemctl --failed` 要检查具体输出，不能仅因命令退出码为 0 就认定没有失败单元。本次结果为 `0 loaded units listed.`。

本次普通重启后的实际结果：

| 检查项                              | 结果                                      |
| ----------------------------------- | ----------------------------------------- |
| 主机名                              | `tencent-tokyo-2c2g`                      |
| 普通用户                            | `uid=1000(star)`，属于 `users` 和 `wheel` |
| sudo                                | `sudo -n id` 返回 root                    |
| NixOS                               | `26.05.20261105.c56a87d (Yarara)`         |
| 内核                                | `6.18.60`，已经不是临时环境的 `7.0.9`     |
| 根文件系统                          | `/dev/vda3`，ext4，读写挂载               |
| swap                                | `/dev/vda2`，2 GiB，已启用                |
| 网卡                                | `ens3`，DHCP 地址 `10.7.0.10/22`          |
| 默认路由                            | 经 `10.7.0.1`                             |
| SSH、networkd、resolved、Nix socket | 全部 active                               |
| 失败单元                            | 0                                         |
| DNS 和 HTTPS                        | 能解析并访问 `cache.nixos.org`            |
| 启动后内存占用                      | 此次采样约 261 MiB                        |
| 配置                                | `/etc/nixos` 四个文件与本地副本摘要一致   |

`lsblk` 中 `/dev/vda3` 同时显示 `/` 和 `/nix/store`，是同一磁盘文件系统上的挂载关系，不表示又安装了一套系统或仍运行在安装镜像中。

到这里才算完成：既验证了安装器成功，也验证了独立的磁盘启动。以后普通 `reboot` 或腾讯云控制台“重启”会继续从该盘启动 NixOS；“重装系统”、格式化或销毁实例则是另外的操作。

## 12. 本次遇到的问题与分阶段恢复

### 12.1 Ubuntu 26.04 的 `kexec_file_load failed: Address not available`

第一次未加兼容参数时，安装器实际执行的加载命令包含：

```text
kexec --load .../bzImage --kexec-syscall-auto ...
kexec_file_load failed: Address not available
```

检查确认旧 Ubuntu 仍运行、`/sys/kernel/kexec_loaded` 为 `0`，磁盘尚未格式化。附近还出现过 `PEFILE: Unsigned PE binary` 日志，但不能仅凭这条信息断定失败就是强制签名检查；本次主错误是上述加载调用失败。

上游已有 Ubuntu 26.04、Linux 7.0 的同类报告，并记录了 `--kexec-extra-flags '-c'` 的成功案例。`-c` 指定使用兼容的 `kexec_load` 接口。本次加上该参数后成功进入临时 NixOS。参见[上游 issue #651](https://github.com/nix-community/nixos-anywhere/issues/651)和 [kexec 手册](https://man7.org/linux/man-pages/man8/kexec.8.html)。

本次没有通过修改 lockdown、关闭 AppArmor 或升级云服务器规格解决问题。复现时先按本文使用 `-c`；如果仍失败，需要保留错误日志检查，不能据此直接格式化磁盘。

### 12.2 GRUB 设备重复：`You cannot have duplicated devices in mirroredBoots`

初稿同时设置了：

```nix
boot.loader.grub.device = "/dev/vda";
```

以及 Disko 的 `EF02` BIOS 引导分区。当前固定版本的 Disko 已自动提供 GRUB 设备，最终求值变成：

```json
{ "grubDevices": ["/dev/vda", "/dev/vda"] }
```

系统构建因此被断言拦截。删除手写的 `boot.loader.grub.device` 后，结果只剩一个 `/dev/vda`，构建和本地 BIOS 启动测试通过。本文给出的完整配置已经包含该修正。

### 12.3 求值整个 `swapDevices` 时提示 `label` 未定义

这是本次编写检查表达式时遇到的问题：直接把 `c.swapDevices` 整个子模块转成 JSON，会尝试读取未赋值的可选字段。该报错不能直接解释为 swap 配置无效。

本文改为只读取需要核验的字段：

```nix
swapDevices = map (s: s.device) c.swapDevices;
```

最终安装后的 2 GiB swap 已实际启用。

### 12.4 `/mnt/etc/fstab` 显示不存在，但安装已经完成

本次安装成功后，从临时环境直接执行 `cat /mnt/etc/fstab` 曾返回 `No such file or directory`。NixOS 的 `/etc` 文件可能经过绝对符号链接引用 Nix store；在临时系统里直接解析，可能走到临时系统自己的 `/nix/store`。

正确做法是进入目标根目录后读取：

```bash
ssh -i "$TENCENT_SSH_KEY" \
  "root@$TENCENT_SSH_HOST" \
  "chroot /mnt '$TENCENT_SYSTEM/sw/bin/cat' /etc/fstab"
```

本次这样读取成功，随后核实目标内核、initrd、GRUB 和分区标签均存在。这个命令用于重启前仍在安装环境的阶段；已经正常启动 NixOS 后，直接读取 `/etc/fstab`，不再使用 `/mnt`。

### 12.5 SSH 的 known_hosts 和用户切换

此次本地别名还配置了：

```ssh-config
UserKnownHostsFile /dev/null
StrictHostKeyChecking no
```

因此临时加上 `-o StrictHostKeyChecking=yes` 会提示 `No ED25519 host key is known`。即使用 `accept-new` 看到“已加入 known hosts”，记录也写向 `/dev/null`，下一次严格检查仍不知道该密钥。这是原有本地配置的效果，不是服务器反复丢失主机密钥。

上面的两项仅记录本次环境，不要求为安装而全局关闭主机身份检查。另外，此次固定版本的 nixos-anywhere 内部也有自己的 SSH 主机密钥选项，不能把其行为与手动 `ssh` 的默认行为混为一谈。

使用正常 known_hosts 文件时，重装可能产生新的主机密钥。确认控制台中的实例身份和指纹后，才移除对应旧记录并重新连接。例如（将示例地址替换为实际公网地址）：

```bash
# 仅在已经确认新主机身份后执行。
ssh-keygen -R 203.0.113.10
```

如果报错指向别名 `tencent` 的记录，还需要处理相应别名记录。不要删除整个 known_hosts 文件。

三种登录用户要分清：

```text
Ubuntu 原系统：ubuntu@tencent
临时安装环境：root@tencent
最终 NixOS：star@tencent
```

如果安装后直接执行 `ssh tencent` 仍尝试 `ubuntu`，显式使用 `ssh star@tencent`，或在自己的 SSH 配置来源中把该别名的用户改为 `star`。

### 12.6 kexec 后 SSH 不通

先确认工具是否仍在等待重连，并检查日志。不要因为中间一次超时就启动第二个并行安装进程。

如果仅执行过 `--phases kexec`：

- `ubuntu@tencent` 仍能登录，说明可能未完成切换，先检查旧系统和 kexec 日志。
- `root@tencent` 能登录且 `VARIANT_ID=installer`，说明切换成功，按第 8 节核验后继续。
- 两者都不通时，通过腾讯云 VNC/管理终端看启动输出，确认是否卡在内核、内存或网络初始化。
- **尚未执行 Disko 时，磁盘上的 Ubuntu 仍在。** 通过云平台进行普通重启，可以尝试重新从原磁盘系统启动。执行过清盘后，这条恢复路径就不再成立。

### 12.7 分区完成后，安装或连接中断

先重新以 root 连接临时环境，检查 `/mnt` 是否仍挂载在正确的新根分区、配置是否一致、已有下载是否保留。确认分区和挂载正确后，可以只重试 `install` 阶段：

```bash
# 前提：仍在临时安装环境，且 /mnt 已正确挂载新根分区。
"$TENCENT_ANYWHERE" \
  --store-paths "$TENCENT_DISKO" "$TENCENT_SYSTEM" \
  --extra-files "$TENCENT_WORK/extra-files" \
  --target-host "root@$TENCENT_SSH_HOST" \
  --build-on local \
  --phases install \
  -i "$TENCENT_SSH_KEY" \
  --ssh-option BatchMode=yes \
  --ssh-option ConnectTimeout=15 \
  > "$TENCENT_WORK/install-retry.log" 2>&1
```

**不要为了重试下载，就再次运行 `disko,install`。** 重新运行 Disko 的清盘模式会再次格式化新分区。若已经重启、临时环境消失而新系统无法启动，应先通过控制台诊断；必要时重新装回 Ubuntu，再从本文开头重做。只有在确认需要重新清盘时，才重复完整安装阶段。

### 12.8 本地检查程序或沙箱报错

此次本地 `python3` 被 mise shim 接管，但没有设置 Python 版本，曾报 `No version is set for shim: python3`。安装不依赖在本地配置 Python，本流程使用 `jq` 读取构建结果即可。

Codex 沙箱内还遇到过：

```text
Bad owner or permissions on .../30-libvirt-ssh-proxy.conf
cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Operation not permitted
```

本次在沙箱外执行相同的 SSH、Nix 和 KVM 检查后正常。不应为了这些执行环境错误去修改服务器的 SSH 配置，也没有必要更改 Nix store 内文件的权限。

## 13. 完成后应保存的材料与后续维护

服务器上的 `/etc/nixos` 已保留四个源文件；本地应另外保存：

- `flake.nix`、`flake.lock`、`configuration.nix`、`disk-config.nix`。
- 本次安装镜像的 URL、字节数和 SHA-256；需要长期复现时同时归档镜像文件。
- nixos-anywhere 的固定提交号。
- `evaluated-plan.json`、`build-results.json`、构建日志、VM 测试日志、kexec 日志和安装日志。

完整日志可能包含公网地址、SSH 公钥、临时下载链接和机器信息。本文保留了复现所需的平台参数，但没有写入本地 SSH 私钥内容。

本次原始工作目录与日志名称如下，便于审查现有记录；以后应使用自己的新工作目录：

```text
/tmp/tencent-nixos-install.UIbnjf/
├── flake.nix
├── flake.lock
├── configuration.nix
├── disk-config.nix
├── evaluated-plan.json
├── build-results.json
├── vm-test.log
├── kexec.log          # 第一次未加 -c 的失败记录
├── kexec-compat.log   # 加 -c 后成功的记录
├── install.log
└── extra-files/etc/nixos/
```

可以把四个配置文件打包保存到自己指定的本地目录：

```bash
tar -C "$TENCENT_WORK" -czf "$TENCENT_WORK/tencent-tokyo-2c2g-config.tar.gz" \
  flake.nix flake.lock configuration.nix disk-config.nix
```

这仍放在临时目录里，需要自行复制到长期保存的位置。服务器自己的 `/etc/nixos` 不能代替外部备份，因为以后在腾讯云控制台重装 Ubuntu 时，它也会被清除。

此后日常修改系统使用 NixOS 的配置和重建流程，不再重新运行安装器清盘。例如，在已安装的 NixOS 上可以先只构建检查：

```bash
# 在已安装的服务器上执行；这里只构建，不激活配置。
sudo nixos-rebuild build --flake /etc/nixos#tencent-tokyo-2c2g
```

本次最小配置没有部署 Home Manager、业务服务、cloud-init 或腾讯云 TAT。SSH、sudo、网络和磁盘启动已经验证；依赖云助手的控制台功能不是本次验收范围。控制台上保存的原镜像信息也不应代替对服务器实际运行系统的检查。

## 14. 参考资料

- [nixos-anywhere 快速入门](https://nix-community.github.io/nixos-anywhere/quickstart.html)：配置、磁盘定义、本地 VM 测试和远程安装。
- [nixos-anywhere 系统要求](https://nix-community.github.io/nixos-anywhere/)：架构、内存、SSH 和 kexec 前提。
- [本次固定版本的 nixos-anywhere 源码](https://github.com/nix-community/nixos-anywhere/blob/58132e1d1f813b845382a2aeca4203b18d2ac807/src/nixos-anywhere.sh)：阶段控制、目标端下载、闭包复制和安装命令。
- [Ubuntu 26.04 / Linux 7.0 的 kexec 问题记录](https://github.com/nix-community/nixos-anywhere/issues/651)：`Address not available` 和 `-c` 兼容参数。
- [Disko BIOS + GPT 示例](https://github.com/nix-community/disko/blob/cedd626e11b635470fa6f9fdb8ad79b0075dd7f9/example/gpt-bios-compat.nix)：BIOS 引导分区的基础配置。
- [NixOS kexec 安装镜像](https://github.com/nix-community/nixos-images/releases/tag/nixos-25.11)：本次使用的临时安装介质。
- [kexec 手册](https://man7.org/linux/man-pages/man8/kexec.8.html)：加载和执行新内核，以及不同加载接口。
- [腾讯云轻量服务器共享自定义镜像限制](https://cloud.tencent.com/document/product/1207/63264)：说明为何没有采用导入 CVM 镜像再共享的安装路径。
