---
title: "利用 VirtualBox 和 Ubuntu 22 重现抓包实验"
date: 2023-08-23T10:07:25+08:00
lastmod: 2023-08-23T10:07:25+08:00
weight: 4
tags: [wireshark, blog]
---

## 实验介绍

在 [《Wireshark网络分析就这么简单》](https://book.douban.com/subject/26268767/) 第一章，讲述了一道面试题。

HostA 和 HostB 在同一个局域网中，它们的 IP 配置如下，请问这两台机器能否 ping 通?

```
HostA: 
    IP: 192.168.26.129/24
    Gateway: 192.168.26.2
HostB: 
    IP: 192.168.26.3/27
    Gateway: 192.168.26.2
```

答案是能够 ping 同，HostA 和 HostB 连同网关最终会形成一个奇怪的网络

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2023-08-23-103426.png)

具体通信过程如下:

- HostA(`192.168.26.129`) 发送 ping 请求给 HostB(`192.168.26.3`)
    - HostA 将 HostB 的 IP 和自己的掩码计算，发现 `192.168.26.3` 和自己是处于同一子网
    - HostA 通过 ARP 协议广播寻找 `192.168.26.3` 的 MAC 地址，由于 `192.168.26.3` 和它在同一局域网中，`192.168.26.3` 会应答自己的 MAC 地址
    - HostA 将 ping 请求直接发送给 `192.168.26.3`, 目的 MAC 地址使用的就是 `192.168.26.3` 的地址
- HostB(`192.168.26.3`) 收到 ping 请求，给 HostA 发送 ping 响应
    - HostB 将 HostA 的 IP 和自己的掩码计算，发现 `192.168.26.129` 和自己不是同一子网
        - 192.168.26.3 & 255.255.255.224 == 192.168.26.0
        - 192.168.26.129 & 255.255.255.224 == 192.168.26.128
    - HostB 将 ping 响应发送给网关，由网关进行路由发送
        - HostB 通过 APR 协议广播寻找网关 `192.168.26.2` 的 MAC 地址，网关 `192.168.26.2` 告诉 HostB 自己的 MAC
        - HostB 发送 ping 响应包，目的 IP 是 `192.168.26.129`, 目的 MAC 是网关的 MAC 地址
    - 网关将 ping 响应发送给了 HostA

## 开始实验

读完这个实验后，感觉这个测试挺好玩，就尝试在本地复现了一下。

我的环境如下，3台安装了 Ubuntu 22.04 Vitualbox 虚拟机, 它们分别充当 HostA, HostB 和 网关

图

### 下载并添加 Vagrant box

### 启动并配置 VBox

### 设置 VBox 网络

## 问题1: 192.168.26.3 地址存在两个

## 问题2: 网关没有转发

## 参考链接

- [How to clear the ARP cache on Linux?](https://linux-audit.com/how-to-clear-the-arp-cache-on-linux/)
- [6.4. Network Address Translation Service](https://www.virtualbox.org/manual/ch06.html#network_nat_service)
