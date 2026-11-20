# Caddy

系统服务使用 NixOS 原生配置生成逻辑。各 feature 可以分别声明
`services.caddy.globalConfig`、`extraConfig` 和 `virtualHosts`，无需自行拼接主配置文件。

## 运行时配置

导入文件使用 `<名称>.<范围>-<位置>.caddy`，全部位于
`config.home-manager.users.${config.common.primaryUser}.xdg.configHome` 下的 `caddy/` 目录。
Star 默认使用 `/home/star/.config/caddy/`。

| 文件匹配规则            | 插入位置                 | 示例                        |
| ----------------------- | ------------------------ | --------------------------- |
| `*.global-before.caddy` | 普通 `globalConfig` 之前 | `local.global-before.caddy` |
| `*.global-after.caddy`  | 普通 `globalConfig` 之后 | `local.global-after.caddy`  |
| `*.extra-before.caddy`  | 普通 `extraConfig` 之前  | `demo.extra-before.caddy`   |
| `*.extra-after.caddy`   | 普通 `extraConfig` 之后  | `demo.extra-after.caddy`    |

例如在服务器上创建 `/home/star/.config/caddy/demo.extra-after.caddy`：

```caddyfile
demo.example.com {
    reverse_proxy 127.0.0.1:8081
}
```

然后执行 `sudo systemctl reload caddy`。不需要重新构建 NixOS 配置。
通配符没有匹配文件时会跳过，不要求预先创建四个文件。
当前 Caddy 会为没有匹配文件的通配符输出 warning，但不会因此拒绝加载或 reload。

`*.global-before.caddy`、`*.global-after.caddy` 写全局块内部的选项，不写外层 `{ ... }`。
`*.extra-before.caddy`、`*.extra-after.caddy` 写完整站点块或顶层片段。
前后顺序由 `mkBefore`、`mkAfter` 控制；`virtualHosts` 仍位于整段 `extraConfig` 之后。
这些位置不提供同名站点或全局选项的覆盖语义。

## 文件与服务可见性

Home Manager 递归、逐文件链接仓库中的 `caddy/` 配置，保留目录中额外手工创建的文件。
仓库提供的文件仍受 Nix 或本地来源管理；运行时配置直接在主用户的实际 Caddy 目录中新建。
用户级 Caddy 服务仍使用该目录内的 `Caddyfile`。

系统 Caddy 排在主用户的 Home Manager 激活服务之后启动，并只读绑定该 Caddy 目录。
服务内外使用相同路径，主用户仍可在服务外修改和添加手工文件。
本地 checkout 中的来源目录也按 file-sources 的解析结果只读绑定，确保现有链接可以解析。
