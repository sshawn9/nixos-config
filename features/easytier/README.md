# EasyTier

本 feature 提供 UDP、TCP、WS/WSS 三种 Web 后端，以及分别连接它们的三个静态前端入口，后续组网配置也放在这里。
仓库自动发现 `flake-module.nix`，主机可直接设置下面的选项。
总开关、三个后端和三个前端的开关默认均关闭，可部署在同一台或不同的服务器。

## NixOS 与 Home Manager

```text
easytier/
├── flake-module.nix       # 导出 NixOS、HM 两侧入口
├── options.nix            # 两侧共用的选项声明
├── nixos.nix              # NixOS 入口
├── nixos/
│   ├── backend/
│   │   ├── udp.nix       # UDP 配置监听、独立 API 和数据库
│   │   ├── tcp.nix       # TCP 配置监听、独立 API 和数据库
│   │   └── ws.nix        # WS 直接接入，以及 Caddy 提供的 WSS
│   └── frontend.nix       # 三个前端共用资源，分别生成站点和 API 地址脚本
└── home-manager.nix       # HM 入口，目前只导入共享选项
```

NixOS 侧实际部署 Web 前后端。HM 侧供用户预设填写 `features.easytier.*`，
embedded HM 中的值由仓库组装层传给系统侧，服务仍运行在 NixOS 系统层。
standalone HM 目前只获得这些选项，不会部署 Web 服务。

## 三个后端

上游 `easytier-web` 每个进程只能选择一种配置监听协议，因此三个后端分别运行服务。
各自的账号、设备、组网配置及在线会话彼此独立，每个前端固定连接对应后端的 API。

| 选项分组      | systemd 服务       | API 端口（回环） | 原生配置端口 |
| ------------- | ------------------ | ---------------- | ------------ |
| `backend.udp` | `easytier-web-udp` | TCP 11211        | UDP 22020    |
| `backend.tcp` | `easytier-web-tcp` | TCP 11212        | TCP 22021    |
| `backend.ws`  | `easytier-web-ws`  | TCP 11213        | TCP 22022    |

每组分别提供 `enable`、`apiDomain`、`apiPort`、`configPort`、`environmentFile`。
WS 组另外提供 `wssDomain`，仅用于 Caddy 的 WSS 站点和证书。
UDP、TCP、原生 WS 的接入域名由客户端通过 DNS 解析，不依赖这个选项。
三个后端可以同时开启：

```nix
features.easytier = {
  enable = true;
  backend = {
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
      wssDomain = "et-config.example.com";
      environmentFile = config.sops.secrets.easytier-web-env.path;
    };
  };
};
```

后端直接使用 `pkgs.unstable.easytier` 中已有的 `easytier-web`。
`package` 机制只负责是否将程序加入全局环境，不参与后端服务的软件包选择。
systemd 负责服务重启和状态目录，数据库均为对应目录内的 `et.db`：

- UDP：`/var/lib/easytier-web-udp/et.db`
- TCP：`/var/lib/easytier-web-tcp/et.db`
- WS：`/var/lib/easytier-web-ws/et.db`

## 设备接入

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
API 与 WSS 入口复用现有 Caddy 的 443 监听；UDP/TCP 配置连接不经过 Caddy。

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
    udp.apiDomain = "et-api-udp.example.com";
    tcp.apiDomain = "et-api-tcp.example.com";
    ws.apiDomain = "et-api-ws.example.com";
  };
  frontend = {
    default = {
      type = "tcp";
      domain = "et.example.com";
    };
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

| 前端           | 使用的管理 API          | 管理的设备                              |
| -------------- | ----------------------- | --------------------------------------- |
| `frontend.udp` | `backend.udp.apiDomain` | 通过 UDP Config Server 接入的设备       |
| `frontend.tcp` | `backend.tcp.apiDomain` | 通过 TCP Config Server 接入的设备       |
| `frontend.ws`  | `backend.ws.apiDomain`  | 通过 WS 或 WSS Config Server 接入的设备 |

WS 和 WSS 共用一个后端和一份数据库，因此共用 `frontend.ws`，无需额外的 WSS 前端。
每个前端从对应的 `backend.<协议>.apiDomain` 生成 HTTPS API 地址，不再单独维护一份 API 域名。
入口页面和 API 地址脚本禁止缓存，避免继续使用旧前端或错误的后端地址。

`frontend.default.domain` 是可选的固定主入口，`frontend.default.type` 选择它使用的前端，
可选 `udp`、`tcp`、`ws`，默认 `tcp`。所选前端必须已经启用。
主入口通过 Caddy 的 `serverAliases` 复用所选站点，页面和 API 地址保持一致，
浏览器地址保留主域名。修改 `frontend.default.type` 即可切换主入口对应的前端。
未设置 `frontend.default.domain` 时，只提供各自的前端入口。
主入口域名也需要在 DNS 服务商处解析到托管前端的服务器。

前后端可以跨服务器部署。使用同一主域下的 HTTPS 子域，兼容后端当前的登录 Cookie 策略。
分开部署时，两台服务器填写对应后端相同的 `apiDomain`；前端所在主机无需启用该后端。
各管理 API、WSS 入口和各前端站点使用不同域名。

前端的下载地址和哈希固定在 `nixos/frontend.nix`，与后端版本无关。
更新前端时同时修改下载地址和哈希，并确认与后端 API 兼容。

## Caddy 接入

本 feature 使用 `services.caddy.virtualHosts` 声明三个前端、每个后端的 API 和 WS 后端的 WSS 站点，
站点内部配置写在各自的 `extraConfig` 中，由组装层启用 Caddy。
它不设置其他 feature 的总开关。
访问日志沿用原生 `virtualHosts` 的默认配置，按站点写入 Caddy 日志目录。
后端站点由各自的 feature 开关声明，反代规则跟随对应的 `systemd.services.<服务名>.enable`；
单独关闭该单元时保留站点声明，移除反代规则。
使用 NixOS 默认 Caddy 配置入口时无需额外接线。
若主机自行设置了 `services.caddy.configFile`，原生模块将不再自动生成这些站点。
