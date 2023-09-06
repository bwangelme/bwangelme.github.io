---
title: "在 Ubuntu 22.04 上搭建 NFS Server"
date: 2023-09-06T08:51:39+08:00
lastmod: 2023-09-06T08:51:39+08:00
tags: [nfs, linux, blog]
author: "bwangel"
---

## 环境准备

我准备了两台机器

name|ip|user|user_id
---|---|---|---
server|191.168.58.11|vagrant|1000
client|192.168.58.1|xuyundong|1000

## 安装组件

- 服务端安装 nfs server

```
sudo apt update
sudo apt install nfs-kernel-server
```

- 客户端安装 nfs-common

```
sudo apt update
sudo apt install nfs-common
```

## 服务端创建目录并导出

### 在服务端上创建挂载目录，并设置权限

```
sudo mkdir -p /mnt/share
sudo chown vagrant:vagrant /mnt/share
sudo chmod 755 /mnt/share
```

### 服务端上配置 nfs export 目录

修改 `/etc/exports` 文件, 加入以下内容

```
/mnt/share       *(rw,async,no_subtree_check)
```

关于 export 选项的解释

- `rw`: 客户端具有读和写的权限
- `sync`: 强制 nfs 在回复 client 之前将更改写入磁盘，这保证了 nfs server 的可靠性，但也降低了写入速度
- `no_subtree_check`: 此选项可防止子树检查，在子树检查过程中，主机必须为每个请求检查文件在导出的树中是否仍然可用。当客户端打开文件时重命名文件时，这可能会导致许多问题。__通常建议禁用子树检查__。
- `no_root_squash`: 当客户端以 root 权限写入文件时，nfs server 会将文件 owner 改成普通用户，当此选项开启时，nfs server 不修改 root 写入文件的 woner

修改完以后执行以下命令载入配置

```
sudo systemctl restart nfs-kernel-server
```

## 客户端挂载

客户端执行以下命令挂载

```bash
# 将服务端的 nfs 目录挂载到了客户端的 /home/xuyundong/tmp/nfs_exmaple 中
sudo mount 192.168.58.11:/mnt/share /home/xuyundong/tmp/nfs_exmaple
```

修改 `/etc/fstab` 文件，将以下内容写入可以让 client 在开机启动时自动挂载

```
192.168.58.11:/mnt/share   /home/xuyundong/tmp/nfs_exmaple   nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
```


## 测试访问

在客户端的目录中，__以 uid=1000 的用户执行__

```
echo "abc" > test.txt
```

可以看到文件正常写入了。

这是因为 client 的写入的用户的 uid 是 1000, server 中目录的 owner 的 uid 也是 1000, owner 相同就能正常写入。

## 取消挂载

客户端执行以下命令可以取消挂载

```
sudo umount ~/tmp/nfs_exmaple
```

## 参考链接

- [How To Set Up an NFS Mount on Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-22-04)
