---
title: "Pod Tips"
date: 2023-03-02T09:31:14+08:00
lastmod: 2023-03-02T09:31:14+08:00
draft: false
tags: [tips, k8s]
author: "bwangel"
comment: true
---

---

## Pod 状态计算细节

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2023-03-02-093104.png)

## Pod 的 QoS 分类

> request 是最低资源需求，limit 是最高资源需求

QoS 类别|描述
---|---
Guaranteed(确保)|Pod 的资源 request 和 limit 相同
Burstable(可破裂)| Pod 的资源 request 小于 limit
BestEffort(尽力而为)| Pod 的资源没有设置任何 request 和 limit

当计算节点上存在内存/磁盘压力时，k8s 会按照 `BestEffort -> Burstable -> Guaranteed` 的顺序一次驱逐 pod.

CPU 是可以压缩的资源，当 CPU 存在压力时，k8s 不会驱逐 pod.

通常情况下，Burstable 是最好的 QoS 策略，对于一些重要的核心 pod，可以设置为 Guaranteed, 确保它最后被驱逐。

## 统计集群中运行 pod 的数量

```
sum(kube_pod_status_phase{phase="Running"})
```

`kube_pod_container_status_ready` 指标有 `namespace`, `cluster`, `phase` Label 可以对指标进行筛选，其他的看起来都是 prom 相关的

phase 有五种: Pending|Running|Succeeded|Failed|Unknown

+ 统计处于 Running 和 Succeeded 状态的 Pod，某些 Job 执行成功后是 Succeed 状态

```
sum(kube_pod_status_phase{phase=~"Running|Succeeded"})
```

+ 按 namespace 统计集群中运行 pod 的数量，并按逆序排序

```
sort_desc(sum(kube_pod_status_phase{phase="Running"}) by (namespace))
```

### 参考链接

- [Pod Metrics](https://github.com/kubernetes/kube-state-metrics/blob/master/docs/pod-metrics.md)

## k8s 停止 Pod 的过程

1. 将 Pod 的状态设置为 `Terminating`，将 Pod 从 service 的 endpoints 列表中移除。
2. 执行 [preStopHook](https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/#hook-details)
3. 发送 SIGTERM 信号给进程。
    - __注意:__ k8s 不会等待 preStopHook 结束后再发送信号，发送 SIGTERM 和 执行 preStopHook 是同时进行的
4. 等待 Pod 正常退出，等待的时间由 `terminationGracePeriod` 设置
5. 如果等待超时，会发送 SIGKILL 信号给进程。
6. 清理 k8s 中存储的 Pod 信息。

### 参考链接

- [Kubernetes best practices: terminating with grace](https://cloud.google.com/blog/products/containers-kubernetes/kubernetes-best-practices-terminating-with-grace)

