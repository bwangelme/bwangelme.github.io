---
title: "Thrft"
date: 2022-11-15T12:40:19+08:00
lastmod: 2022-11-15T12:40:19+08:00
tags: [tips, thrift]
author: "bwangel"
---

## thrift 概念

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2018-05-27-060022.png)

## thrift 架构

Thrift 的架构图如下

![](https://passage-1253400711.cos-website.ap-beijing.myqcloud.com/2021-12-17-100303.png)

Transport 层位于最底部，用户传输字节数据。

Transport 层提供的接口如下:

![](https://passage-1253400711.cos-website.ap-beijing.myqcloud.com/2021-12-17-100415.png)

Transport 层可以由多个 TTransport 类组合起来，每个 TTransport 提供不同的功能。处于 TTransport 组合层次最下方，和设备(网络，磁盘，内存)直接打交道的 TTransport 类称为 __Endpoint transports__。例如 `TSocket`，它使用 Socket API 在 TCP/IP 网络上传输数据。

`TFramedTransport` 有两个作用:

1. 分帧，它在每个消息的头部加了四字节的长度，让接受者能够准确地得知消息的大小，并申请合适的 buffer
2. 缓存。当 `flush` 方法调用的时候，缓存的数据才会写入下一层 Transport

当不需要分帧，仅需要缓存的时候，可以使用 `TBufferedTransport`。某些语言在 Endpoint Transport 中內建了缓存机制，就没有提供 `TBufferedTransport` 类。

## 参考链接

- [Chapter 2. Apache Thrift architecture](https://livebook.manning.com/book/programmers-guide-to-apache-thrift/chapter-2/18)
