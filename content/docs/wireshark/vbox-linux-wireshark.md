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

答案是能够 ping 通，HostA 和 HostB 连同网关最终会形成一个奇怪的网络

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

读完以后，感觉这个测试挺好玩，就尝试在本地复现了一下。

我的环境如下，3台安装了 Ubuntu 22.04 Vitualbox 虚拟机, 它们分别充当 HostA, HostB 和 网关

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2023-08-23-224057.png)

### 配置 Vagrant

我的 VirtualBox 是通过 Vagrant 启动的

- 首先我们需要在 Vagrant 官网上下载 Ubuntu 22.04 的 Box

[ubuntu/jammy64 Vagrant box 下载地址](https://app.vagrantup.com/ubuntu/boxes/jammy64)

下载完成之后通过如下命令添加 Vagrant Box

```
vagrant box add ~/Downloads/jammy-server-cloudimg-amd64-vagrant.box --name ubuntu/jammy
```

添加完成后使用 `vagrant box list` 可以看到我们添加的 box 名字了

- 接着我们再来安装 `vagrant-disksize` 插件

```bash
# 建议在执行命令前挂上 http 代理
vagrant plugin install vagrant-disksize
```

### 启动并配置 VBox

这是我的 Vagrantfile, 它启动了三个 virtualbox 虚拟机，分别命名为 vbox1, vbox2, vbox3。完整代码见 [github/bwangelme/DockerVbox.git](https://github.com/bwangelme/DockerVbox.git)

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

# Verify whether required plugins are installed.
required_plugins = [ "vagrant-disksize" ]
required_plugins.each do |plugin|
  if not Vagrant.has_plugin?(plugin)
    raise "The vagrant plugin #{plugin} is required. Please run `vagrant plugin install #{plugin}`"
  end
end

Vagrant.configure("2") do |config|
  config.vm.box_check_update = false

  $num_instances = 3
  (1..$num_instances).each do |i|
    config.vm.define "vbox#{i}" do |node|
      node.vm.box = "ubuntu/jammy"
      node.vm.hostname = "vbox#{i}"
      node.vm.provider "virtualbox" do |vb|
        vb.memory = "1024"
        vb.cpus = 1
        vb.name = "vbox#{i}"
      end
      # 单独执行 vagrant provision 也会执行一遍 install.sh 脚本
      node.vm.provision "shell", path: "install.sh"
    end
  end
end
```

将 [github/bwangelme/DockerVbox.git](https://github.com/bwangelme/DockerVbox.git) 克隆到本地，进入目录中执行

```
vagrant up
```

就可以创建并启动三个 Ubuntu 22.04 的 VirtualBox 虚机了

启动完成后，我们执行

```
vagrant halt
```

将虚拟机先停止，接着我们来手动设置网络。

### 设置 VBox 网络

- 第一步，打开 VirtualBox 的 __管理 -> 全局设定__ ，打开网络 Tab, 添加一个 Nat 网络，设置名字为 `NatNetwork`，设置网段为 `192.168.26.0/24`

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2023-08-23-225440.png)

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2023-08-23-225556.png)

- 第二步，分别在每个虚拟机上执行，在 __虚拟机设置 -> 网络__ 中添加网卡，__连接方式__ 选 `Nat网络`, __界面名称__ 选择我们刚刚创建的 `NatNetwork`

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2023-08-23-225755.png)

- 第三步，手动启动三个虚拟机。

__注意:__ 不能使用 `vagrant up` 启动, 否则我们创建的网卡就被关闭了

### 手动设置机器的 IP

虚拟机启动后，使用如下命令可以登陆到对应的虚机上

```
vagrant ssh vbox1
```

接着我们修改 `/etc/netplan/50-cloud-init.yaml` 文件，加入我们 Nat 网卡 `enp0s8` 的配置

```diff
 vagrant@vbox1:~$ cat /etc/netplan/50-cloud-init.yaml
 # This file is generated from information provided by the datasource.  Changes
 # to it will not persist across an instance reboot.  To disable cloud-init's
 # network configuration capabilities, write a file
 # /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
 # network: {config: disabled}
 network:
     ethernets:
         enp0s3:
             dhcp4: true
             match:
                 macaddress: 02:20:c0:fe:1f:a9
             set-name: enp0s3
+        enp0s8:
+            dhcp4: no
+            addresses:
+                - 192.168.26.129/24
+            gateway4: 192.168.26.2
+            nameservers:
+                addresses: [223.5.5.5]
     version: 2
```

三台主机的配置如下

Hostname|网卡名称|IP/掩码|MAC 地址|网关
---|---|---|---|---
vbox1|enp0s8|192.168.26.129/24|08:00:27:4c:f0:52|192.168.26.2
vbox2|enp0s8|192.168.26.3/27|08:00:27:69:22:ae|192.168.26.2
vbox3|enp0s8|192.168.26.2/24|08:00:27:d5:b5:13|192.168.26.1

修改完配置文件后，使用以下命令将配置生效

```
sudo netplan apply
```

至此，所有的网络环境都配置成功了，我们可以开始抓包了。

## 问题1: 192.168.26.3 地址存在两个

我在 vbox1 上执行以下抓包命令

```
sudo tcpdump -i enp0s8 --print -en -w vbox1_ping src host 192.168.26.3 or dst host 192.168.26.3
```

在另一个终端中执行 ping 发送 ICMP 包

```
ping -c 3 192.168.26.3
```

此时，很奇怪的问题出现了

`192.168.26.3` 能够 ping 通，但请求不是从 vbox2 发回来的，而是从一个 MAC 地址为 `08:00:27:ae:84:b6` 的网卡发回来的。

```
01:26:47.254731 08:00:27:4c:f0:52 > 08:00:27:ae:84:b6, ethertype IPv4 (0x0800), length 98: 192.168.26.129 > 192.168.26.3: ICMP echo request, id 9, seq 1, length 64
01:26:47.254885 08:00:27:ae:84:b6 > 08:00:27:4c:f0:52, ethertype IPv4 (0x0800), length 98: 192.168.26.3 > 192.168.26.129: ICMP echo reply, id 9, seq 1, length 64
01:26:48.275239 08:00:27:4c:f0:52 > 08:00:27:ae:84:b6, ethertype IPv4 (0x0800), length 98: 192.168.26.129 > 192.168.26.3: ICMP echo request, id 9, seq 2, length 64
01:26:48.275415 08:00:27:ae:84:b6 > 08:00:27:4c:f0:52, ethertype IPv4 (0x0800), length 98: 192.168.26.3 > 192.168.26.129: ICMP echo reply, id 9, seq 2, length 64
01:26:49.298910 08:00:27:4c:f0:52 > 08:00:27:ae:84:b6, ethertype IPv4 (0x0800), length 98: 192.168.26.129 > 192.168.26.3: ICMP echo request, id 9, seq 3, length 64
01:26:49.299089 08:00:27:ae:84:b6 > 08:00:27:4c:f0:52, ethertype IPv4 (0x0800), length 98: 192.168.26.3 > 192.168.26.129: ICMP echo reply, id 9, seq 3, length 64
01:26:52.370038 08:00:27:4c:f0:52 > 08:00:27:ae:84:b6, ethertype ARP (0x0806), length 42: Request who-has 192.168.26.3 tell 192.168.26.129, length 28
01:26:52.370156 08:00:27:ae:84:b6 > 08:00:27:4c:f0:52, ethertype ARP (0x0806), length 60: Reply 192.168.26.3 is-at 08:00:27:ae:84:b6, length 46

# 这个抓包更奇怪，vbox1 询问 192.168.26.3 的 MAC 地址，有两个地址发来了响应
vagrant@vbox1:~$ sudo tcpdump -i enp0s8 --print src host 192.168.26.3 or dst host 192.168.26.3 -w vbox1_ping
tcpdump: listening on enp0s8, link-type EN10MB (Ethernet), snapshot length 262144 bytes
16:50:54.672007 ARP, Request who-has 192.168.26.3 tell vbox1, length 28
16:50:54.672243 ARP, Reply 192.168.26.3 is-at 08:00:27:ae:84:b6 (oui Unknown), length 46
16:50:54.672243 ARP, Reply 192.168.26.3 is-at 08:00:27:69:22:ae (oui Unknown), length 46
```

这个困扰了我好久，我反复检查三台 vbox 的所有网卡和我宿主机所有网卡的 MAC 地址，没有一个是符合 `08:00:27:ae:84:b6` 的。

后来我突发奇想，这是不是 virtualbox NetNetwork 默认创建的地址，于是我将 vbox2 和 vbox3 的地址全部换掉，发现

- 192.168.26.1
- 192.168.26.2
- 192.168.26.3

这三个地址依然是能够 ping 通的。

我用关键字 `vbox nat network gateway` 在 Google 中搜索，找到了 vbox 的一篇文档: [6.4. Network Address Translation Service](https://www.virtualbox.org/manual/ch06.html#network_nat_service)

文档中创建了一个 `192.168.15.0/24` 的 Nat 网络， 并说静态设置的网关默认被赋予地址 `192.168.15.1`

> Here, natnet1 is the name of the internal network to be used and 192.168.15.0/24 is the network address and mask of the NAT service interface. By default in this static configuration the gateway will be assigned the address 192.168.15.1, the address following the interface address, though this is subject to change. To attach a DHCP server to the internal network, modify the example command as follows:

这下我就明白了，`192.168.26.1`, `192.168.26.2`, `192.168.26.3` 是 Vbox Nat 网络的保留地址，`192.168.26.1` 是默认网关，`192.168.26.3` 是 DNS Server 的地址(因为它的 53 端口能用 UDP 连上), `192.168.26.2` 是干嘛的还没搞明白

为了不冲突，我们改一下我们三台机器的地址，新地址如下

Hostname|网卡名称|IP/掩码|MAC 地址|网关
---|---|---|---|---
vbox1|enp0s8|192.168.26.129/24|08:00:27:4c:f0:52|192.168.26.123
vbox2|enp0s8|192.168.26.122/27|08:00:27:69:22:ae|192.168.26.123
vbox3|enp0s8|192.168.26.123/24|08:00:27:d5:b5:13|192.168.26.1

## 问题2: 网关没有转发

更新了 IP 地址后，我们接着在 vbox1 上 ping `192.168.26.122`, 此时出现的问题是 ping 不通了，看起来上一个问题解决了，但是新的问题出现了。

我在 vbox2 上抓了一下包，看到了如下内容

```
vagrant@vbox2:~$ sudo tcpdump -i enp0s8 --print -en
17:17:56.850218 08:00:27:4c:f0:52 > 08:00:27:69:22:ae, ethertype IPv4 (0x0800), length 98: 192.168.26.129 > 192.168.26.122: ICMP echo request, id 25, seq 8, length 64
17:17:56.850246 08:00:27:69:22:ae > 08:00:27:d5:b5:13, ethertype IPv4 (0x0800), length 98: 192.168.26.122 > 192.168.26.129: ICMP echo reply, id 25, seq 8, length 64
17:17:57.868013 08:00:27:4c:f0:52 > 08:00:27:69:22:ae, ethertype IPv4 (0x0800), length 98: 192.168.26.129 > 192.168.26.122: ICMP echo request, id 25, seq 9, length 64
17:17:57.868046 08:00:27:69:22:ae > 08:00:27:d5:b5:13, ethertype IPv4 (0x0800), length 98: 192.168.26.122 > 192.168.26.129: ICMP echo reply, id 25, seq 9, length 64
17:17:58.883354 08:00:27:4c:f0:52 > 08:00:27:69:22:ae, ethertype IPv4 (0x0800), length 98: 192.168.26.129 > 192.168.26.122: ICMP echo request, id 25, seq 10, length 64
17:17:58.883387 08:00:27:69:22:ae > 08:00:27:d5:b5:13, ethertype IPv4 (0x0800), length 98: 192.168.26.122 > 192.168.26.129: ICMP echo reply, id 25, seq 10, length 64
```

vbox2 收到了来自 vbox1 的 ping request, 并发送 ping reply 给网关 vbox3, 这和我们预期的行为一致，说明 vbox2 没问题。

接着我又在 vbox3 上抓了一下包

```
root@vbox3:~# tcpdump -i enp0s8 --print -en
listening on enp0s8, link-type EN10MB (Ethernet), snapshot length 262144 bytes
01:49:50.730850 08:00:27:69:22:ae > 08:00:27:d5:b5:13, ethertype IPv4 (0x0800), length 98: 192.168.26.122 > 192.168.26.129: ICMP echo reply, id 26, seq 1, length 64
01:49:51.790335 08:00:27:69:22:ae > 08:00:27:d5:b5:13, ethertype IPv4 (0x0800), length 98: 192.168.26.122 > 192.168.26.129: ICMP echo reply, id 26, seq 2, length 64
01:49:53.203978 08:00:27:69:22:ae > 08:00:27:d5:b5:13, ethertype IPv4 (0x0800), length 98: 192.168.26.122 > 192.168.26.129: ICMP echo reply, id 26, seq 3, length 64
01:49:55.993736 08:00:27:69:22:ae > 08:00:27:d5:b5:13, ethertype ARP (0x0806), length 60: Request who-has 192.168.26.123 tell 192.168.26.122, length 46
01:49:55.993751 08:00:27:d5:b5:13 > 08:00:27:69:22:ae, ethertype ARP (0x0806), length 42: Reply 192.168.26.123 is-at 08:00:27:d5:b5:13, length 28
01:52:10.616571 08:00:27:69:22:ae > 08:00:27:d5:b5:13, ethertype IPv4 (0x0800), length 98: 192.168.26.122 > 192.168.26.129: ICMP echo reply, id 27, seq 1, length 64
01:52:11.965582 08:00:27:69:22:ae > 08:00:27:d5:b5:13, ethertype IPv4 (0x0800), length 98: 192.168.26.122 > 192.168.26.129: ICMP echo reply, id 27, seq 2, length 64
01:52:12.992503 08:00:27:69:22:ae > 08:00:27:d5:b5:13, ethertype IPv4 (0x0800), length 98: 192.168.26.122 > 192.168.26.129: ICMP echo reply, id 27, seq 3, length 64
```

vbox3 收到了 vbox2 转发来的包，但它没有进一步的发送动作，此时我拍脑袋一想，Linux 可能默认有限制，不转发包，于是我用 __ubuntu 开启路由转发__ 作为关键字搜了一下，找到了配置项 `net.ipv4.ip_forward`, 我又用 __ubuntu ipv4_forward__ 作为关键字搜索了一下，找到了 ubuntu 开启 IP Forward 的文章。

我执行以下命令，在 vbox3 上临时开启了 ip 转发的功能

```
sysctl -w net.ipv4.ip_forward=1
```

改完上述配置后，在 vbox1 上 ping `192.168.26.122` 就能 ping 通了。

在 vbox3 上抓包也能看到转发的 ICMP reply 包

```
01:58:54.790382 08:00:27:d5:b5:13 > 08:00:27:4c:f0:52, ethertype IPv4 (0x0800), length 98: 192.168.26.122 > 192.168.26.129: ICMP echo reply, id 28, seq 1, length 64
```

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2023-08-23-234135.png)

## 参考链接

- [How to clear the ARP cache on Linux?](https://linux-audit.com/how-to-clear-the-arp-cache-on-linux/)
- [6.4. Network Address Translation Service](https://www.virtualbox.org/manual/ch06.html#network_nat_service)
- [Linux IP forwarding – How to Disable/Enable using net.ipv4.ip_forward](https://linuxconfig.org/how-to-turn-on-off-ip-forwarding-in-linux)
- 其他用到的命令

```
# 查看 arp 表
arp -n
# 清空 arp 表
sudo ip -s -s neigh flush all
# 查看路由信息
route -n
```

