---
title: "DNS"
date: 2023-09-09T13:41:16+08:00
lastmod: 2023-09-09T13:41:16+08:00
tags: [linux, dig, dns, tips]
author: "bwangel"
---

## A 记录

Address Mapping records, 指示了对应名称的IPv4地址, A记录用来将域名转换为ip地址.

## AAAA 记录

类似于A记录, 只不过指示的是IPv6的地址。

因为 IPv6 地址长度是 IPv4 的四倍，所以用 AAAA 表示 IPv6 记录

## NS 记录

- Name Server records, 用来指定对应名称的可信名称服务器 (authoritative name server)

例如这段 dig 日志是 `j.gtld-servers.net` 告诉我们，它不知道 `www.baidu.com` 的 IP, 但是它告诉我们要查询 `baidu.com.` 域的地址，可以去 ns[12345].baidu.com 这5个地址中查。

```
baidu.com.              172800  IN      NS      ns2.baidu.com.
baidu.com.              172800  IN      NS      ns3.baidu.com.
baidu.com.              172800  IN      NS      ns4.baidu.com.
baidu.com.              172800  IN      NS      ns1.baidu.com.
baidu.com.              172800  IN      NS      ns7.baidu.com.
;; Received 849 bytes from 192.48.79.30#53(j.gtld-servers.net) in 316 ms
```

## PTR 记录

Pointer records, 通过 IP 反查域名，大部分域名服务器都不支持，目前只找到了 `dns.google.` 支持 PTR 查询

```
ø> dig -x 8.8.4.4

;; QUESTION SECTION:
;4.4.8.8.in-addr.arpa.          IN      PTR

;; ANSWER SECTION:
4.4.8.8.in-addr.arpa.   1       IN      PTR     dns.google.
```

## CNAME 记录

又称 alias 别名，是 A 记录的别名

例如以下的查询说明

1. `www.baidu.com.` 是 `www.a.shifen.com.` 的别名
2. `www.a.shifen.com.` 指向了 `220.181.38.150` 和 `220.181.38.149`

```
ø> dig -4 www.baidu.com

;; QUESTION SECTION:
;www.baidu.com.                 IN      A

;; ANSWER SECTION:
www.baidu.com.          70      IN      CNAME   www.a.shifen.com.
www.a.shifen.com.       53      IN      A       220.181.38.150
www.a.shifen.com.       53      IN      A       220.181.38.149
```

## 查询方式

### 递归查询

client 发送请求给局域网 DNS, 局域网 DNS 再去上游 DNS 服务器执行进一步查询。一级一级向上递归并回到局域网 DNS , 局域网 DNS 将查询的地址返回给客户端

dig 命令默认执行的就是递归查询

### 集中查询

1. client 发送请求给局域网 DNS 获得 DNS 根服务器的地址
2. client 请求根服务器获得下一级 DNS 服务器地址
3. 以此往复，一级一级直到查到目标域名的 IP 地址

以下用集中查询的方式查询 www.baidu.com IP 地址的过程

```sh
ø> dig -4 +trace www.baidu.com

# 获取根服务器的名字列表
; <<>> DiG 9.18.12-0ubuntu0.22.04.2-Ubuntu <<>> -4 +trace www.baidu.com
;; global options: +cmd
.                       2229    IN      NS      k.root-servers.net.
.                       2229    IN      NS      b.root-servers.net.
.                       2229    IN      NS      h.root-servers.net.
.                       2229    IN      NS      i.root-servers.net.
.                       2229    IN      NS      l.root-servers.net.
.                       2229    IN      NS      c.root-servers.net.
.                       2229    IN      NS      a.root-servers.net.
.                       2229    IN      NS      d.root-servers.net.
.                       2229    IN      NS      e.root-servers.net.
.                       2229    IN      NS      m.root-servers.net.
.                       2229    IN      NS      f.root-servers.net.
.                       2229    IN      NS      g.root-servers.net.
.                       2229    IN      NS      j.root-servers.net.
;; Received 239 bytes from 10.8.0.1#53(10.8.0.1) in 4 ms

# 根服务器返回通用定义域名的名字列表
com.                    172800  IN      NS      a.gtld-servers.net.
com.                    172800  IN      NS      b.gtld-servers.net.
com.                    172800  IN      NS      c.gtld-servers.net.
com.                    172800  IN      NS      d.gtld-servers.net.
com.                    172800  IN      NS      e.gtld-servers.net.
com.                    172800  IN      NS      f.gtld-servers.net.
com.                    172800  IN      NS      g.gtld-servers.net.
com.                    172800  IN      NS      h.gtld-servers.net.
com.                    172800  IN      NS      i.gtld-servers.net.
com.                    172800  IN      NS      j.gtld-servers.net.
com.                    172800  IN      NS      k.gtld-servers.net.
com.                    172800  IN      NS      l.gtld-servers.net.
com.                    172800  IN      NS      m.gtld-servers.net.
com.                    86400   IN      DS      30909 8 2 E2D3C916F6DEEAC73294E8268FB5885044A833FC5459588F4A9184CF C41A5766
com.                    86400   IN      RRSIG   DS 8 1 86400 20230921210000 20230908200000 11019 . M02FKEukwDc7T/KjNtpdCfwvkzHx1STqPt3AO/eXQxqBU7jN9vrHbJMJ PNXpBlO5p+HgnZ9w0c7sR8qnDXFl1OziNAo0el1fRq0YFwBae9BgoLCg IeZVoZmqerXpVXCrpKX1Fb+ILjuIX1bL5li2xQ/gpq4u91EijGvZg6sQ UmBiQW0JlXKR927uOm+aJHN6Ujnzd7sZrOWpSXQAOVPf4dHjvCJNohfs V9cJkjBRI+QuOpArJ+gCGKoiMidjYZBuYXIsYV7PYLQbVfVZg2E3JFXX h5BkqZUlCZbabAcVCzQ6BGZMpxcs1A/J8g/7+eguU6bJFpbiBXeHEZhx TS1zoQ==
;; Received 1173 bytes from 192.58.128.30#53(j.root-servers.net) in 8 ms

# 通用顶级域名返回 baidu.com. 域的 DNS 服务器名字列表
baidu.com.              172800  IN      NS      ns2.baidu.com.
baidu.com.              172800  IN      NS      ns3.baidu.com.
baidu.com.              172800  IN      NS      ns4.baidu.com.
baidu.com.              172800  IN      NS      ns1.baidu.com.
baidu.com.              172800  IN      NS      ns7.baidu.com.
CK0POJMG874LJREF7EFN8430QVIT8BSM.com. 86400 IN NSEC3 1 1 0 - CK0Q2D6NI4I7EQH8NA30NS61O48UL8G5 NS SOA RRSIG DNSKEY NSEC3PARAM
CK0POJMG874LJREF7EFN8430QVIT8BSM.com. 86400 IN RRSIG NSEC3 8 2 86400 20230915042421 20230908031421 4459 com. ACWanRvoDIwYH40J5TjA8G6UXUldpz8+aNZdFlLO1eY9GRalvfLnpa6H RqiP03pvORSpHJEv2+HuQ1HtWTCj/nlJOeiRKG0Bk/HjcjkH9yv1b6pF ASeyvdJYN2wYPp4e1KPVe3GuoxBETq6kPKfUhR289IzQFy5vLgIfeVWK pR6z0kgCFKTKaO21nj2LxxWsxmfuIpe8ztJuPTF7lVhXhw==
HPVV0C47Q7CQMTAJM90K1FBFJBRP4B4D.com. 86400 IN NSEC3 1 1 0 - HPVVAN8CFKHHHMEIDVJHFNQEOI5G6C89 NS DS RRSIG
HPVV0C47Q7CQMTAJM90K1FBFJBRP4B4D.com. 86400 IN RRSIG NSEC3 8 2 86400 20230914060727 20230907045727 4459 com. oUS/iAWQKq/0KHQdg18vwuUvT1Ftl8tnpHZVCwdQPEaIq3gceZnmpE2Z u8pj+JPFOUqp/DWRNlWZYMmTuhSjJil7cCpahWk3+RJbeJQIWPtNvBkl BBmM1M3he1ELoS37YqcflA8U/q4CaNdEpIS7OiNy6f4efrkZMvqRZZ9U hRgI2CugaGb6C9mDeAfThooAqsc5xFCX9KjWGsNLr0pE+Q==
;; Received 849 bytes from 192.48.79.30#53(j.gtld-servers.net) in 316 ms

# ns3.baidu.com 返回 www.baidu.com 的解析结果
www.baidu.com.          1200    IN      CNAME   www.a.shifen.com.
;; Received 100 bytes from 153.3.238.93#53(ns3.baidu.com) in 24 ms
```

这是集中查询的抓包过程(建议在新 tab 中打开图片对比说明查看)

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2023-09-09-143516.png)

包序号|包功能
---|---
1, 2|从 10.8.0.1 DNS 服务器获得根服务器的地址
3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 24, 25, 26|向 192.168.1.1 和 10.8.0.1 查询根服务器的地址 (两个网卡都发送了查询请求)
14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 28, 29, 30, 31| 10.8.0.1 和 192.168.1.1 返回 DNS 根服务器地址
26|向根服务器 `g.root-servers.net.` 查询 `www.baidu.com.` 的地址
32|根服务器 `g.root-servers.net.` 返回通用顶级域名列表及其地址 `[a-j].gtld-servers.net`
33, 34, 35, 36, 37, 38, 39, 40, 42, 43, 44, 45|向 10.8.0.1 查询通用顶级域名的 IP
47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59| 10.8.0.1 返回通用顶级域名的 IP
46|向通用顶级域名 DNS server `i.gtld-servers.net` 查询 www.baidu.com 的 IP
60|`i.gtld-servers.net` DNS返回 `baidu.com.` 域的 DNS 服务器 `ns[12347].baidu.com` 的名字
61, 62, 63, 64, 65, 69|向 192.168.1.1 和 10.8.0.1 查询 `ns[12347].baidu.com` 的 IP
66,67,68,71,72,73| 192.168.1.1 和 10.8.0.1 返回 `ns[12347].baidu.com` 的 IP
70|向 `ns2.baidu.com` 查询 `www.baidu.com` 的地址
74|`ns2.baidu.com` 返回 `www.baidu.com` 的地址，它是 `www.a.shifen.com` 地址的别名

## 参考链接

- [关于DNS,你应该知道这些](https://www.cnblogs.com/pannengzhi/p/6262076.html)
