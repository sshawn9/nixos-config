# EasyTier

本 feature 提供 Config Server 客户端、共享中转节点、UDP、TCP、WS/WSS 三种 Web 后端，
以及三个专用前端、可选的默认 API、默认网页入口和统一 Config Server 接入域名。
仓库自动发现 `flake-module.nix`，主机可直接设置下面的选项。
总开关、客户端、中转节点、三个后端和三个前端的开关默认均关闭，可部署在同一台或不同的机器。

## NixOS 与 Home Manager

```text
easytier/
├── flake-module.nix       # 导出 NixOS、HM 两侧入口
├── options.nix            # 两侧共用的选项声明
├── overlay.nix            # 静态注册 overlay，按总开关替换包
├── package.nix            # 官方 2.7.1 x86_64 / ARM64 Linux 预编译包
├── nixos.nix              # NixOS 入口、默认 API 别名和 HTTPS/WSS 统一接入
├── nixos/
│   ├── client.nix         # 连接 Config Server，接受远程组网配置
│   ├── relay.nix          # 七种传输协议的共享中转节点
│   ├── backend/
│   │   ├── udp.nix       # UDP 配置监听、独立 API 和数据库
│   │   ├── tcp.nix       # TCP 配置监听、独立 API 和数据库
│   │   └── ws.nix        # WS 直接接入，以及 Caddy 提供的 WSS
│   └── frontend.nix       # 默认和三个专用前端共用资源，分别生成站点和 API 地址脚本
└── home-manager.nix       # HM 入口，目前只导入共享选项
```

NixOS 侧实际部署客户端、中转节点和 Web 前后端。HM 侧供用户预设填写 `features.easytier.*`，
embedded HM 中的值由仓库组装层传给系统侧，服务仍运行在 NixOS 系统层。
standalone HM 目前只获得这些选项，不会部署服务。

`nixos.nix` 静态导入 `overlay.nix`；启用 feature 时，后者通过原生 `nixpkgs.overlays` 将 `pkgs.easytier` 和
`pkgs.unstable.easytier` 统一为 `package.nix` 提供的官方 Release 二进制包。
客户端、中转、三个 Web 后端，以及其他引用这两个包入口的配置均使用同一版本。
使用系统包集的 embedded HM 也会继承该覆盖。
升级时只需维护 `package.nix` 中的版本、下载地址和哈希。
overlay 函数始终注册，实际包替换仍由 feature 总开关控制；关闭时分别返回两个入口各自的原包。
这样可以在开关来自 embedded HM 时，避免“包集等待 HM、HM 等待包集”的循环求值。

## Config Server 客户端

在受管设备上配置：

```nix
features.easytier = {
  enable = true;
  client = {
    enable = true;
    configServer = "https://et-config.example.com/DEVICE_TOKEN";
  };
};
```

将域名和 `DEVICE_TOKEN` 替换为对应 Config Server 的接入域名及设备凭据。
`configServer` 填写完整 URL，支持 HTTPS 地址发现，也可以直接填写 UDP、TCP、WS、WSS 地址。
HTTPS 入口返回当前默认后端的连接地址，客户端随后直接连接该后端；
以后修改服务端默认协议时，无需逐台修改设备。启用客户端时必须设置该选项。

通过原生 `services.easytier.instances.client.configServer` 启动 `easytier-client.service`，
使用统一覆盖后的官方 EasyTier 包，由 systemd 负责开机自启和故障重启。
EasyTier 持续连接 Config Server，没有组网配置时也保持设备管理连接；
虚拟 IP、peers、监听器等组网设置由 Config Server 下发。
客户端通过出站连接接入管理端，无需在本机部署 Web 前后端或中转节点。
同机运行中转节点时，下发的组网监听端口应避开中转节点占用的端口。

## 中转节点

```nix
features.easytier = {
  enable = true;
  relay = {
    enable = true;
    # port = 11010;
  };
};
```

通过原生 `services.easytier.instances.relay` 启动 `easytier-relay.service`，
使用官方 2.7.1 预编译包，由 `package.nix` 按目标平台选择下载地址及对应哈希，
支持 x86_64 Linux 和 ARM64 Linux（`aarch64-linux`）。
直接下载、解包安装，不在本地编译。通过 `--listeners <port>` 让官方程序自动展开
TCP、UDP、WireGuard、WS、WSS、QUIC、FakeTCP 全部七种协议，覆盖原生模块的 TOML 监听列表。
节点不创建用于组网的 TUN 设备，不配置虚拟网 IP。

`relay.port` 是基准端口，默认 `11010`，范围为 `1..65532`，为后续三个端口留出空间。
按[上游端口定义](https://github.com/EasyTier/EasyTier/blob/v2.7.1/easytier-core/src/connectivity/protocol/mod.rs#L41-L64)，
客户端在组网配置的 peers 中填写其中一个地址：

| 协议      | 默认接入地址                        | 对应基准端口 | 防火墙传输类型 |
| --------- | ----------------------------------- | ------------ | -------------- |
| TCP       | `tcp://relay.example.com:11010`     | port         | TCP            |
| UDP       | `udp://relay.example.com:11010`     | port         | UDP            |
| WireGuard | `wg://relay.example.com:11011`      | port + 1     | UDP            |
| WS        | `ws://relay.example.com:11011`      | port + 1     | TCP            |
| QUIC      | `quic://relay.example.com:11012`    | port + 2     | UDP            |
| WSS       | `wss://relay.example.com:11012`     | port + 2     | TCP            |
| FakeTCP   | `faketcp://relay.example.com:11013` | port + 3     | TCP            |

对应端口自动加入 NixOS 防火墙；云平台安全组仍需按表放行。
原生 WSS 由 EasyTier 自行生成自签名证书，EasyTier 客户端使用上游的 TLS 验证策略，
无需 Caddy 或另行配置域名证书。FakeTCP 使用原始套接字；原生 NixOS 服务以 root 运行，提供所需权限。

IPv6 监听沿用上游默认规则：TCP、UDP、WireGuard、WS、WSS 自动尝试增加 IPv6 监听，
QUIC、FakeTCP 不自动增加。EasyTier 2.7.1 的 FakeTCP 拨号路径仍固定使用 IPv4 socket，
因此不宣称 FakeTCP 支持完整 IPv6 接入。
参见[上游 IPv6 监听规则](https://github.com/EasyTier/EasyTier/blob/v2.7.1/easytier-core/src/listener/plan.rs#L141-L163)
和[FakeTCP 拨号实现](https://github.com/EasyTier/EasyTier/blob/v2.7.1/easytier/src/socket/fake_tcp/mod.rs#L429-L446)。

域名直接解析到中转服务器，不经过 HTTP 反代。此服务负责组网发现和数据中转，
与 Web 后端的配置下发相互独立，不需要启用 Web 前后端，连接地址也不填入 `--config-server`。

按[上游共享节点机制](https://easytier.cn/guide/network/host-public-server.html)，
同一个中转节点可为多个虚拟网络提供服务，不限制网络名称，新增网络时无需修改中转节点配置。
不配置虚拟 IP、DHCP 或 `no_tun`，由上游按无虚拟 IP 的节点运行中转。

中转性能相关设置：

- 使用 EasyTier 2.7.1 的原生 `--shared-runtime` 参数，启用进程共享的多线程运行时，
  默认按运行机器的可用 CPU 数分配工作线程。需要指定数量时，在
  `services.easytier.instances.relay.extraArgs` 中追加 `[ "--multi-thread-count" "2" ]`。
  不应用源码补丁，也不依赖 Nixpkgs 中的 EasyTier 是否已更新到 2.7.1。
- 允许转发其他网络的 KCP、QUIC 代理数据包，让客户端能够按链路情况使用这些传输方式。
  这两项控制代理数据包的转发，与上表的 QUIC 传输入口分别配置，两者均已启用。
- 按共享节点的官方建议，将服务的 `LimitNOFILE` 提高到 `1048576`，避免连接增长时耗尽文件描述符。

客户端与中转节点使用 UDP 可避免外层 TCP 重传带来的队头阻塞；TCP 入口供 UDP 不通时使用。
压缩、加密算法、KCP/QUIC 代理和路径选择由实际通信节点配置；共享中转不会解密、压缩其他网络的业务数据。
TUN 队列、虚拟网卡 MTU 和内核子网转发参数不属于此节点的中转路径。

## 三个后端

上游 `easytier-web` 每个进程只能选择一种配置监听协议，因此三个后端分别运行服务。
各自的账号、设备、组网配置及在线会话彼此独立，三个专用前端分别连接对应后端的 API。

| 选项分组      | systemd 服务       | API 端口（回环） | 原生配置端口 |
| ------------- | ------------------ | ---------------- | ------------ |
| `backend.udp` | `easytier-web-udp` | TCP 11211        | UDP 22020    |
| `backend.tcp` | `easytier-web-tcp` | TCP 11212        | TCP 22021    |
| `backend.ws`  | `easytier-web-ws`  | TCP 11213        | TCP 22022    |

每组分别提供 `enable`、`apiDomain`、`apiPort`、`configPort`、`environmentFile`。
`backend.default.configDomain` 是共用的 Config Server 域名，同时提供 HTTPS 地址发现和 WSS 接入。
UDP、TCP、原生 WS 仍通过 DNS 解析该域名后，直接连接各自监听端口。
三个后端可以同时开启：

```nix
features.easytier = {
  enable = true;
  backend = {
    default = {
      type = "tcp";
      apiDomain = "et-api.example.com";
      configDomain = "et-config.example.com";
    };
    udp = {
      enable = true;
      apiDomain = "et-api-udp.example.com";
    };
    tcp = {
      enable = true;
      apiDomain = "et-api-tcp.example.com";
    };
    ws = {
      enable = true;
      apiDomain = "et-api-ws.example.com";
      environmentFile = config.sops.secrets.easytier-web-env.path;
    };
  };
};
```

后端通过统一覆盖后的 `pkgs.unstable.easytier` 使用官方 Release 中的 `easytier-web`。
`package` 机制只负责是否将程序加入全局环境，不参与后端服务的软件包选择。
systemd 负责服务重启和状态目录，数据库均为对应目录内的 `et.db`：

- UDP：`/var/lib/easytier-web-udp/et.db`
- TCP：`/var/lib/easytier-web-tcp/et.db`
- WS：`/var/lib/easytier-web-ws/et.db`

`backend.default.type` 同时选择默认 Config Server 协议及默认 API 对应的后端，
可选 `udp`、`tcp`、`ws`、`wss`，默认 `tcp`。`ws` 和 `wss` 都使用 WS 后端的 API 和数据库。
设置 `backend.default.apiDomain` 后，在所选后端所在的机器上，将该域名加入对应 API 站点的
Caddy `serverAliases`，复用反代配置，不增加服务进程或 HTTP 跳转。
所选后端仍由自己的 `enable` 控制；选择默认类型不会自动开启它。
未设置默认 API 域名时，各后端仍通过各自的 API 域名提供服务。

命令行和默认前端都使用这个固定 API 域名。修改 `backend.default.type` 后，域名指向新选中的后端。
账号、设备、组网配置和管理令牌仍属于各自后端，切换默认入口不会合并或迁移这些数据。
默认 API 域名也可以填写所选后端已有的 API 域名，此时无需添加域名别名；
使用独立域名可以在后续切换默认后端时保持调用地址不变。
该域名需要在 DNS 服务商处解析到默认后端所在服务器。

## 设备接入

设置 `backend.default.configDomain` 后，设备统一使用：

```sh
easytier-core --daemon --config-server 'https://et-config.example.com/DEVICE_TOKEN'
```

Caddy 根据 `backend.default.type` 返回一条连接地址：

| 默认类型 | HTTPS 入口返回的地址                |
| -------- | ----------------------------------- |
| `udp`    | `udp://et-config.example.com:22020` |
| `tcp`    | `tcp://et-config.example.com:22021` |
| `ws`     | `ws://et-config.example.com:22022`  |
| `wss`    | `wss://et-config.example.com`       |

端口使用所选后端的 `configPort`，上表展示默认值。该后端必须已启用，选择类型不会自动启用后端。
HTTPS 发现仅返回目标地址，接入令牌仍由客户端从原 URL 的末段读取并用于身份验证，
响应内容不包含令牌。EasyTier 2.7.1 会先提取令牌，再将 HTTPS 查询路径清空，因此发现响应位于站点根路径。
参见[客户端 URL 处理](https://github.com/EasyTier/EasyTier/blob/v2.7.1/easytier-core/src/management/full/web_client.rs#L112-L145)
和[原生 HTTP 地址发现](https://github.com/EasyTier/EasyTier/blob/v2.7.1/easytier-core/src/connectivity/manual/discovery/implementation.rs#L367-L401)。

普通 HTTPS 请求取得默认地址；WebSocket 升级请求转发到 WS 后端，二者共用一个域名和证书。
关闭 WS 后端时仍可通过同一 HTTPS 入口发现 UDP 或 TCP 地址。
发现响应设置 `Cache-Control: no-store`；每次重连重新查询当前目标，已有连接不会因切换默认类型而立即迁移。
三个后端的账号、设备和配置仍彼此独立，统一入口不合并这些数据，也不随机分配后端。

UDP、TCP 直接连接对应监听端口。WS 后端同时提供原生 WS 和经 Caddy 转发的 WSS：

```text
UDP → udp://et-config.example.com:22020/DEVICE_TOKEN → UDP 后端
TCP → tcp://et-config.example.com:22021/DEVICE_TOKEN → TCP 后端
WS  → ws://et-config.example.com:22022/DEVICE_TOKEN  → WS 后端
WSS → wss://et-config.example.com/DEVICE_TOKEN → Caddy 443 → WS 后端 22022
```

Caddy 负责 TLS 和证书管理，EasyTier 的原生参数保持 `--config-server-protocol ws`；
不能将该参数改为 `wss`，上游配置监听不支持这个取值。
三个原生配置监听端口按对应协议自动加入 NixOS 防火墙，WS 的 TCP 端口也直接开放。
云平台安全组需要另外放行这些端口。配置域名使用灰云解析。

各后端 HTTP API 仅监听回环地址，通过自己的 `apiDomain` 由 Caddy 提供 HTTPS。
API 与 HTTPS 发现/WSS 入口复用现有 Caddy 的 443 监听；UDP/TCP 配置连接不经过 Caddy。

`environmentFile` 是运行时文件路径，不能把密钥明文写入 Nix 配置。
要通过命令行使用内部管理 API，文件应包含：

```dotenv
ET_INTERNAL_AUTH_TOKEN=替换为管理令牌
```

请求使用 `X-Internal-Auth` 请求头。这个管理令牌与设备接入凭据用途不同。
使用 SOPS 时，按对应后端给 secret 设置 `restartUnits`，例如 WS 使用
`[ "easytier-web-ws.service" ]`，TCP 使用 `[ "easytier-web-tcp.service" ]`。
凭据更新后对应服务重新读取文件。

设备通过 WSS 地址连接，省略端口时使用 443，例如：

```sh
easytier-core --daemon --config-server 'wss://et-config.example.com/DEVICE_TOKEN'
```

将 `DEVICE_TOKEN` 替换为设备接入凭据。设备上的 Core 常驻运行，
没有网络实例时也继续接受管理；Web 后端自身不需要先加入网络。
迁移后端时保留数据库和接入凭据，再更新配置域名的 DNS。

## 前端

```nix
features.easytier = {
  enable = true;
  backend = {
    default = {
      type = "tcp";
      apiDomain = "et-api.example.com";
    };
    udp.apiDomain = "et-api-udp.example.com";
    tcp.apiDomain = "et-api-tcp.example.com";
    ws.apiDomain = "et-api-ws.example.com";
  };
  frontend = {
    default.domain = "et.example.com";
    udp = {
      enable = true;
      domain = "et-udp.example.com";
    };
    tcp = {
      enable = true;
      domain = "et-tcp.example.com";
    };
    ws = {
      enable = true;
      domain = "et-ws.example.com";
    };
  };
};
```

三个前端分别通过 `frontend.udp`、`frontend.tcp`、`frontend.ws` 的 `enable` 和 `domain` 配置。
它们由 Caddy 托管，共用同一份 2.7.1 静态资源，没有单独的应用进程。
各站点通过自己的 `api_meta.js` 告诉浏览器应该请求哪个后端：

| 前端               | 使用的管理 API              | 管理的设备                              |
| ------------------ | --------------------------- | --------------------------------------- |
| `frontend.default` | `backend.default.apiDomain` | 默认 API 所指向后端管理的设备           |
| `frontend.udp`     | `backend.udp.apiDomain`     | 通过 UDP Config Server 接入的设备       |
| `frontend.tcp`     | `backend.tcp.apiDomain`     | 通过 TCP Config Server 接入的设备       |
| `frontend.ws`      | `backend.ws.apiDomain`      | 通过 WS 或 WSS Config Server 接入的设备 |

WS 和 WSS 共用一个后端和一份数据库，因此共用 `frontend.ws`，无需额外的 WSS 前端。
每个前端从对应的 `backend.<协议>.apiDomain` 生成 HTTPS API 地址，不再单独维护一份 API 域名。
入口页面和 API 地址脚本禁止缓存，避免继续使用旧前端或错误的后端地址。

`frontend.default.domain` 是可选的默认网页入口，设置后必须填写 `backend.default.apiDomain`。
它使用同一份静态资源，单独生成指向默认 API 域名的 `api_meta.js`；
无需开启三个专用前端，也不再提供 `frontend.default.type`。
默认后端只在 `backend.default.type` 选择一次，统一 Config Server 入口和默认 API 跟随同一选择；
默认前端和命令行使用同一个 API 地址。
未设置 `frontend.default.domain` 时，只提供各自的前端入口。
主入口域名也需要在 DNS 服务商处解析到托管前端的服务器。

前后端可以跨服务器部署。使用同一主域下的 HTTPS 子域，兼容后端当前的登录 Cookie 策略。
分开部署时，两台服务器填写对应后端相同的 `apiDomain`；前端所在主机无需启用该后端。
默认前端只需填写远端的 `backend.default.apiDomain`，不依赖本机的默认后端类型。
各管理 API、Config Server 入口和各前端站点使用不同域名；HTTPS 地址发现与 WSS 共用 Config Server 域名。

前端的下载地址和哈希固定在 `nixos/frontend.nix`，与后端版本无关。
更新前端时同时修改下载地址和哈希，并确认与后端 API 兼容。

## Caddy 接入

本 feature 使用 `services.caddy.virtualHosts` 声明默认和三个专用前端、每个后端的 API 和统一 Config Server 站点，
站点内部配置写在各自的 `extraConfig` 中，由组装层启用 Caddy。
它不设置其他 feature 的总开关。
访问日志沿用原生 `virtualHosts` 的默认配置，按站点写入 Caddy 日志目录。
后端站点由各自的 feature 开关声明，反代规则跟随对应的 `systemd.services.<服务名>.enable`；
单独关闭该单元时保留站点声明，移除反代规则。
使用 NixOS 默认 Caddy 配置入口时无需额外接线。
若主机自行设置了 `services.caddy.configFile`，原生模块将不再自动生成这些站点。
