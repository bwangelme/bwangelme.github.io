---
title: "envoy 线程模型"
date: 2023-12-13T13:17:28+08:00
lastmod: 2023-12-13T13:17:28+08:00
tags: [Envoy, blog]
author: "bwangel"
---

## 线程模型

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2023-12-13-114846.png)

envoy 的线程可以分成三类

### main thread

main thread 负责进程的管理，和 xDS Server 的通信，统计信息 stat 刷新，admin 设置。

main 线程中所有的工作都是异步 & 非阻塞的， 而且它负责的重要功能通常都不会用到大量的 CPU，所以它可以以单线程的模式运行。

### worker thread

worker 线程可以通过 `--concurrency` 选项来控制个数。

worekr 线程整体是一个非阻塞的事件循环，它负责创建 Listener 的连接，listen 端口，accept 连接并处理连接生命周期内的所有请求。这使得大多数连接代码都可以像单线程一样编写。

这种设计可能会导致连接不均衡，即某些 worker 线程比其他线程处理更多的连接。

### file flush thread

Envoy 写的每个文件(主要是 access-log)都有一个独立的数据刷新线程。因为将内容写入到操作系统的文件缓存时，即使使用了 `O_NONBLOCK` 选项，有时也会阻塞住。

当线程需要写入文件时，他们通常是将内容写入到一块内存区域，然后 flush 线程再将内容刷新到文件中。

## 连接处理

连接不均衡的问题，最早就有人在 [github上问了](https://github.com/envoyproxy/envoy/issues/2961)，Envoy作者的回答是让操作系统来做负载均衡最好，而且一个线程处理accept，扩展性不高。但是后来作者还是加上了一个[均衡连接的可选配置](https://www.envoyproxy.io/docs/envoy/v1.28.0/intro/arch_overview/intro/threading_model#listener-connection-balancing)。

现代内核在连接的负载均衡方面表现得非常出色。
它们采用诸如IO优先级提升( IO priority boosting)之类的功能，试图在开始使用其他正在监听相同套接字的线程之前，填充一个线程的工作。同时，它们也不使用单个自旋锁来处理每个 accpet 操作。

连接一旦创建，IO 读写一般是绑定在一个线程。

Envoy 中每个工作线程都会创建一个连接池，因此尽管 HTTP2 会在一个连接上使用多个 Stream, 但是 Envoy 的每个线程还是会针对每个 Upstream 创建一个 TCP 连接。

`--concurrency` 默认等于机器的CPU核数，在高配置的服务器上默认太大了，除了边缘代理外，大部分代理可以将这个数字设置地小一点。

## 线程间通信的 TLS

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2023-12-13-125138.png)

主线程从 xDS 获取到配置信息后，使用 TLS (Thread local storage) 功能将配置发送给工作线程。

TLS 的模式如下，针对一份数据，主线程和工作线程维护了一份数组 slots，它里面保存了指向实际数据的指针。

工作线程的 slots 保存在线程本地变量(Threading local storage)中，这样可以避免并发，由于保存的是指针，使用的空间也比较少。

上图中，主线程更新了一份数据，将它保存到索引3上，同时发送一个事件给所有 worker 的事件循环，1-3号线程收到事件后都更新了，4号线程还在旧事件循环中处理 IO，它拿到的是索引2的旧数据，等线程4结束了一次事件循环后，它会更新数据，使用索引3上的数据。

每个数据都保存了使用方的 __引用计数__，当所有线程都不再使用，确认引用计数是0之后，Envoy 会删除索引2指向的数据。

## TLS 更新流程

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2023-12-13-125837.png)

1. 集群管理器 (cluster manager) 是 Envoy 内部的组件，负责管理所有已知的上游集群、CDS API、SDS/EDS API、DNS 和主动（out-of-band）健康检查。它负责创建每个上游集群的最终一致视图，包括发现的主机以及其健康状态。

2. 健康检查器 (health checker) 执行主动健康检查，并将健康状态变化报告给集群管理器。

3. CDS/SDS/EDS/DNS 用于确定集群成员资格。状态变化会报告给集群管理器。

4. 每个工作线程都持续运行一个事件循环。

5. 当集群管理器确定集群的状态发生变化时，它会创建该集群状态的新的只读快照，并将其发布到每个工作线程。

6. 在接下来的安静期间(quiescent period)，工作线程将更新分配的 TLS slots 中的快照。

7. 在需要确定负载均衡的主机的 IO 事件期间，负载均衡器将查询 TLS slots 以获取主机信息。这一过程无需获取任何锁。（还要注意，TLS 还可以在更新时触发事件，以便负载均衡器和其他组件可以重新计算缓存、数据结构等。这超出了本文的范围，但在代码中的各个地方都有使用。）

## 查看 Envoy 线程的名字

以下命令可以查看 envoy 所有线程的启动名字。

这个 envoy 进程我是以 `--concurrency 3` 启动的，可以看到线程数是 13 个，每个 worker 会启动两个线程 `wrk:worker_x` 和 `GrpcGoogClient`

```
envoy_id=`ps aux | rg 'envoy-1.28' | rg -v rg | awk '{print $2}'` \
           ps aux -L | rg 'envoy-1.28' | rg -v rg | awk '{print $3}' | \
           xargs -I{{ cat "/proc/${envoy_id}/task/{{/comm"
```

```
envoy-1.28.0
default-executo
resolver-execut
grpc_global_tim
GrpcGoogClient
dog:main_thread
dog:workers_gua

wrk:worker_0
wrk:worker_1
wrk:worker_2

GrpcGoogClient
GrpcGoogClient
GrpcGoogClient
```

## 参考文章

- [Envoy threading model](https://blog.envoyproxy.io/envoy-threading-model-a8d44b922310)
- [Envoy调研：线程模型](https://zhuanlan.zhihu.com/p/442036172)
- [Envoy源码分析之Dispatcher机制](https://developer.aliyun.com/article/757470)
- [Envoy源码分析之ThreadLocal机制](https://developer.aliyun.com/article/757471)

