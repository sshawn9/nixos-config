# REALITY 部署说明

本目录由主机组装器递归加载，不需要再添加 `imports`。
下文使用 `hello.example.com` 作为示例域名。

- `xray.nix`：VLESS + RAW/TCP + REALITY + XTLS Vision，仅监听 `127.0.0.1:24443`。
- `../caddy.nix`：固定 caddy-l4 插件版本及构建哈希，连接 Caddy 配置入口和只读目录绑定，并通过环境变量提供网页目录。
- `file-sources/tokyo01/.config/caddy/Caddyfile`：主入口，在公网 TCP 443 的 TLS 握手前按 SNI 分流，并导入 `sites/hello.caddy`。
- `sites/hello.caddy`：位于上述配置目录内，声明公网 HTTPS 入口、HTTP 跳转和 `127.0.0.1:8443` 的回落网站。
- `site/index.html`：普通浏览器访问域名时看到的页面。
- `secrets/tokyo01/xray.enc.json`：完整的 Xray 服务端 JSON 配置，由 SOPS 加密保存。

## 更换域名

在仓库根目录执行 `sops secrets/tokyo01/xray.enc.json`，修改 `inbounds[0].streamSettings.realitySettings.serverNames`。
同步修改 `file-sources/tokyo01/.config/caddy/Caddyfile` 中的 L4 域名匹配、`sites/hello.caddy` 中的域名和 `mihomo.yaml` 的 `servername`。
域名是公开配置，直接写在 Caddyfile 中，不需要域名环境变量或单独的 SOPS 配置。
网页目录通过 `REALITY_SITE_ROOT` 指向 `site/` 的 Nix store 快照，服务器无需本地 checkout。

在 Cloudflare 为该子域名建立指向服务器公网 IPv4 的 A 记录，选择 **DNS only**。
客户端的 `server` 填写服务器公网地址，`servername` 用于 TLS SNI。

主机防火墙通过 `services.caddy.openFirewall = true` 自动放行 TCP 80、443 和 UDP 443；
云平台安全组也需要放行这些端口。
80 供 Caddy 完成 HTTP-01 证书验证和续期，并将普通 HTTP 访问重定向到 HTTPS。
Caddy 监听公网 TCP 443，Xray 的 24443 和回落网站的 8443 仅监听本机；
公网 HTTPS 保留 Caddy 默认的 HTTP/1.1、HTTP/2 和 HTTP/3，UDP 443 由 Caddy 原生处理。
只有 `127.0.0.1:8443` 的 TCP 回落入口限制为 HTTP/1.1、HTTP/2，避免宣告不可从公网访问的 HTTP/3 端口。
客户端仍然连接公网 TCP 443，不需要修改端口或凭据。

```text
公网 TCP 443 → Caddy L4
                ├─ SNI 匹配 hello.example.com → Xray 127.0.0.1:24443
                │                                  ├─ REALITY 认证通过 → 代理
                │                                  └─ 普通 TLS 握手 → Caddy 127.0.0.1:8443
                └─ 其他 SNI → Caddy 原生 HTTPS 网站
```

L4 分流不终止 TLS；通过 PROXY protocol v2 将客户端地址传给 Xray。
回落目标必须保持独立的 `127.0.0.1:8443`，不能指回带有同一条 L4 规则的公网 443。
以后增加普通网站时，在 `sites/` 下创建文件并由主 Caddyfile 导入即可，它们不经过 Xray。

Caddy 使用 ACME 自动签发和续期公开可信证书，禁用 TLS-ALPN 验证，避免依赖
已被 L4 转入 Xray 的代理域名握手。首次签发完成前，HTTPS 和 REALITY 暂时无法使用。
证书只在公网域名站点管理；8443 回落入口按 SNI 复用同一张证书，不重复声明证书策略。

更新 caddy-l4 插件版本或 Caddy 版本后，需要重新构建并核对插件依赖的 `hash`。
Xray 可能因本机监听 24443 输出非 443 警告；这里的公网入口仍为 443，本机端口不会暴露给客户端。

## 客户端

将 `mihomo.yaml` 中的节点加入现有 `proxies`，并加入需要使用它的策略组。
使用支持 `reality-opts.support-x25519mlkem768` 和现代 Chrome 指纹的 Mihomo 版本。
节点启用了该选项、XTLS Vision 和 XUDP，没有关闭证书校验。

## 更换凭据

通过 `sops secrets/tokyo01/xray.enc.json` 编辑完整配置，UUID 位于 `inbounds[0].settings.users[0].id`，私钥和 short ID 位于对应入站的 `streamSettings.realitySettings`。
修改后应同步更新 `mihomo.yaml` 对应的 UUID、公钥和 short ID。
公钥与私钥必须是一对；公钥对应客户端的 `reality-opts.public-key`，继续保存在客户端节点配置中。

## 运行时解密

SOPS feature 由主机组装配置统一启用，解密身份和接收公钥通过 SOPS 配置管理。

`xray.nix` 只声明 `xrayConfig` 一个 secret，以 `format = "json"`、`key = ""` 在运行时解密整份文件。
Xray 通过原生 `settingsFile` 和 systemd `LoadCredential` 读取解密结果，不再使用模板或逐字段拼装配置。
解密后的 JSON 不进入 Nix store；配置变更由 secret 的 `restartUnits` 自动重启 Xray。
现有 SOPS 预切换检查也会验证这些 secret 能否解密。
