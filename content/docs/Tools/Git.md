---
title: "Git Tips"
date: 2024-01-20T22:26:51+08:00
lastmod: 2024-01-20T22:26:51+08:00
tags: [git]
author: "bwangel"
---

## Git ssh push 超时

修改 `~/.git/config` 文件

```
# Add section below to it
Host github.com
  Hostname ssh.github.com
  Port 443
```

将 push 的端口从 22 改成 443，有可能绕过 GFW

## 测试

22 端口超时

```
$ ssh -T git@github.com
ssh: connect to host github.com port 22: Connection timed out
```

443 端口能联通

```
ø> ssh -T -p 443 git@github.com
Hi bwangelme! You've successfully authenticated, but GitHub does not provide shell access.
```
