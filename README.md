# GitHub Hosts 加速

一个 KernelSU 模块：合并多个 GitHub 加速 hosts 源，自动更新，并提供 WebUI 图形界面管理。

用于解决 GitHub 网页访问慢、头像和图片加载不出来的问题。通过把 GitHub 相关域名直接解析到可用 IP，绕开不稳定的 DNS。

## 特性

- **多源合并**：内置多个源，下载后按行去重，互补取长。
- **自动更新**：开机先更新一次，之后默认每 12 小时更新一次，间隔可改。
- **手动更新**：WebUI 里一键更新。
- **源可管理**：内置源可单独开关，也可添加、删除自定义源。
- **图形界面**：基于 KernelSU 的 WebUI，无需额外 App。
- **失败保护**：新内容不合法（行数过少或不含 github.com）时不予写入，保留原有 hosts。
- **自动备份**：每次更新前备份旧文件，保留最近 10 份。

## 安装

1. 在 KernelSU 管理器中安装 **meta-overlayfs** metamodule。
   本模块需要把 `system/etc/hosts` 挂载到系统，KernelSU 通过 metamodule 完成挂载，缺少它 hosts 不会生效。
2. 在 KernelSU 管理器「从存储安装」中选择 `github-hosts-v1.0.2.zip`。
3. 重启设备。

> KernelSU 模块不能在 Recovery 中安装。

## 使用

重启后打开模块的 WebUI（KernelSU 管理器里的模块入口）：

- **状态**：最后更新时间、hosts 条目数、github.com 连通性。
- **立即更新**：手动执行一次合并更新。
- **测试连通性**：探测当前是否能连通 `github.com:443`。
- **源**：开关每个源（关闭的源不参与合并），或删除。
- **添加源**：填入名称和 hosts 格式的 URL。
- **设置**：修改自动更新间隔（小时），重启后生效。
- **日志**：查看每次更新结果。

## 内置源

| 名称 | 地址 | 说明 |
| --- | --- | --- |
| GitHub520 | https://raw.hellogithub.com/hosts | 最主流，CDN 直连，无需访问 GitHub 即可更新 |
| ineo6/hosts | https://gitlab.com/ineo6/hosts/-/raw/master/hosts | GitLab 镜像，图片与网页加速 |
| ittuann/GitHub-IP-hosts | https://cdn.jsdelivr.net/gh/ittuann/GitHub-IP-hosts@main/hosts | 每周 Actions 更新，返回响应最快的 IP |
| Fetch GitHub Hosts | https://hosts.gitcdn.top/hosts.txt | 服务器自行测速，含 JSON 版本 |
| ittuann 精简版 | https://cdn.jsdelivr.net/gh/ittuann/GitHub-IP-hosts@main/hosts_single | 每个域名只保留单一 IP，条目更少 |
| ineo6 DNS 方案 | https://gitlab.com/ineo6/hosts/-/raw/master/next-hosts | 基于 DNS 解析获取的新方案 |

默认全部启用。多数取的是 CDN / GitLab 镜像地址，所以即使当前连不上 GitHub，也仍能拉到需要的数据。

## 配置与数据

运行时数据位于 `/data/adb/github_hosts/`：

| 文件 | 说明 |
| --- | --- |
| `sources.json` | 源列表 |
| `disabled.list` | 被关闭的源 URL，每行一个 |
| `config.conf` | `INTERVAL=43200`，单位秒 |
| `backup/` | hosts 历史备份，保留最近 10 份 |
| `log.txt` | 更新日志 |

生成的 hosts 写在模块的 `system/etc/hosts`，由 KernelSU 挂载到 `/system/etc/hosts`。

## 构建

```sh
bash build.sh
```

产物在 `dist/github-hosts-<版本>.zip`。构建只依赖 `python3`（用于打包 zip）。

## 工作原理

1. 从 `sources.json` 取出启用中的源，逐个下载（curl 优先，回退到 busybox wget）。
2. 从每个源中提取 `IP 域名` 记录行，合并后按行去重。
3. 校验：结果行数不少于 5 且包含 `github.com`，否则放弃本次写入。
4. 备份现有 hosts，再用重定向覆盖写入（保持 inode 不变，否则已挂载的 hosts 仍指向旧文件）。

## 注意

- hosts 只优化 DNS 解析，解决网页访问慢和图片裂图；`git pull` / `git push` 超时是链路问题，需要把 SSH 切到 `ssh.github.com:443`。
- 更新后的连通性检查做成了手动按钮，没有做成自动回滚条件：本模块的用户通常本来就直连不上 GitHub，自动回滚会导致每次更新都被判定失败而失效。
- 关闭其它会写 hosts 的模块（如 AD-hosts），避免互相覆盖。

## 致谢

数据来自以下开源项目：

- [521xueweihan/GitHub520](https://github.com/521xueweihan/GitHub520)
- [ineo6/hosts](https://github.com/ineo6/hosts)
- [ittuann/GitHub-IP-hosts](https://github.com/ittuann/GitHub-IP-hosts)
- [Fetch GitHub Hosts](https://hosts.gitcdn.top/)
