---
title: "CNI"
date: 2023-12-25T18:16:42+08:00
lastmod: 2023-12-25T18:16:42+08:00
tags: [k8s, cni]
author: "bwangel"
---

## CNI 要求

CNI 插件的要求可以被简述成两个

- 连通性(Connectivity), 每个 Pod 通过默认的网卡接口 eth0 分配 IP 地址，并且这个 IP 地址，在节点的根网络空间上可达。
- 可达性(Reachability)，跨节点的 Pod 可以直接用 pod ip 通信（不需要经过 NAT）。

### 验证连通性

- 这是我用 kind 在本地搭建的一个三节点集群

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: demo
nodes:
  - role: control-plane
    image: kindest/node:v1.26.3@sha256:61b92f38dff6ccc29969e7aa154d34e38b89443af1a2c14e6cfbd2df6419c66f
  - role: worker
    image: kindest/node:v1.26.3@sha256:61b92f38dff6ccc29969e7aa154d34e38b89443af1a2c14e6cfbd2df6419c66f
  - role: worker
    image: kindest/node:v1.26.3@sha256:61b92f38dff6ccc29969e7aa154d34e38b89443af1a2c14e6cfbd2df6419c66f
```

```bash
ø> docker ps
CONTAINER ID   IMAGE                  COMMAND                   CREATED              STATUS              PORTS                       NAMES
3fdffdb2fa2d   kindest/node:v1.26.3   "/usr/local/bin/entr…"   About a minute ago   Up About a minute   127.0.0.1:34309->6443/tcp   demo-control-plane
646f93b78436   kindest/node:v1.26.3   "/usr/local/bin/entr…"   About a minute ago   Up About a minute                               demo-worker
d5e20cd642fb   kindest/node:v1.26.3   "/usr/local/bin/entr…"   About a minute ago   Up About a minute                               demo-worker2
```

- 646f93b78436 是 k8s 的工作节点 `demo-worker`，它的进程 ID 是 1568942
- d5e20cd642fb 是 k8s 的工作节点 `demo-worker2`，它的进程 ID 是 1568954

```bash
ø> docker inspect 646f93b78436 | rg -i '"pid"'
            "Pid": 1568942,
ø> docker inspect d5e20cd642fb | rg -i '"pid"'
            "Pid": 1568954,
```

- apple-app-ddb7b6f95-kz2w8 是集群中的一个 pod, 它运行在 demo-worker2 上, 它的 eth0 网卡的地址是 10.244.1.2

```bash
ø> k -n qae get pod -o wide
NAME                        READY   STATUS    RESTARTS   AGE    IP           NODE           NOMINATED NODE   READINESS GATES
apple-app-ddb7b6f95-kz2w8   1/1     Running   0          117s   10.244.1.2   demo-worker2   <none>           <none>

ø> k -n qae exec -it apple-app-ddb7b6f95-kz2w8 ip addr show eth0
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl exec [POD] -- [COMMAND] instead.
2: eth0@eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
    link/ether 1e:a2:83:1b:93:92 brd ff:ff:ff:ff:ff:ff
    inet 10.244.1.2/24 brd 10.244.1.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::1ca2:83ff:fe1b:9392/64 scope link
       valid_lft forever preferred_lft forever
```

- 我进入 1568942 和 1568954 的网络空间，相当于登陆到了了 k8s 的 worker 节点上，ping pod 是可以 ping 通的。

```bash
# demo-worker 节点
ø> sudo nsenter -n -t 1568942 ping -c 2 10.244.1.2
PING 10.244.1.2 (10.244.1.2) 56(84) bytes of data.
64 bytes from 10.244.1.2: icmp_seq=1 ttl=63 time=0.063 ms
64 bytes from 10.244.1.2: icmp_seq=2 ttl=63 time=0.057 ms

--- 10.244.1.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1011ms
rtt min/avg/max/mdev = 0.057/0.060/0.063/0.003 ms

# demo-worker2 节点
ø> sudo nsenter -n -t 1568954 ping -c 2 10.244.1.2
PING 10.244.1.2 (10.244.1.2) 56(84) bytes of data.
64 bytes from 10.244.1.2: icmp_seq=1 ttl=64 time=0.059 ms
64 bytes from 10.244.1.2: icmp_seq=2 ttl=64 time=0.017 ms

--- 10.244.1.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 0.017/0.038/0.059/0.021 ms
```

### 验证可达性

这是集群中的所有 pod, 我在 apple-app-ddb7b6f95-kz2w8 上 ping  local-path-provisioner-75f5b54ffd-slkv5，可以 ping 通

```sh
ø> k get pod --all-namespaces -o wide
NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE     IP           NODE                 NOMINATED NODE   READINESS GATES
kube-system          coredns-787d4945fb-2sdzq                     1/1     Running   0          10m     10.244.0.3   demo-control-plane   <none>           <none>
kube-system          coredns-787d4945fb-kdmsd                     1/1     Running   0          10m     10.244.0.2   demo-control-plane   <none>           <none>
kube-system          etcd-demo-control-plane                      1/1     Running   0          10m     172.23.0.2   demo-control-plane   <none>           <none>
kube-system          kindnet-jdvn8                                1/1     Running   0          10m     172.23.0.4   demo-worker2         <none>           <none>
kube-system          kindnet-sbm7g                                1/1     Running   0          10m     172.23.0.2   demo-control-plane   <none>           <none>
kube-system          kindnet-xcbjv                                1/1     Running   0          10m     172.23.0.3   demo-worker          <none>           <none>
kube-system          kube-apiserver-demo-control-plane            1/1     Running   0          10m     172.23.0.2   demo-control-plane   <none>           <none>
kube-system          kube-controller-manager-demo-control-plane   1/1     Running   0          10m     172.23.0.2   demo-control-plane   <none>           <none>
kube-system          kube-proxy-6kqfz                             1/1     Running   0          10m     172.23.0.3   demo-worker          <none>           <none>
kube-system          kube-proxy-nq6dw                             1/1     Running   0          10m     172.23.0.4   demo-worker2         <none>           <none>
kube-system          kube-proxy-ws5nj                             1/1     Running   0          10m     172.23.0.2   demo-control-plane   <none>           <none>
kube-system          kube-scheduler-demo-control-plane            1/1     Running   0          10m     172.23.0.2   demo-control-plane   <none>           <none>
local-path-storage   local-path-provisioner-75f5b54ffd-slkv5      1/1     Running   0          10m     10.244.0.4   demo-control-plane   <none>           <none>
qae                  apple-app-ddb7b6f95-kz2w8                    1/1     Running   0          9m21s   10.244.1.2   demo-worker2         <none>           <none>
```

```
ø> k -n qae exec -it apple-app-ddb7b6f95-kz2w8 -- ping -c 2 10.244.0.4
PING 10.244.0.4 (10.244.0.4): 56 data bytes
64 bytes from 10.244.0.4: seq=0 ttl=62 time=0.063 ms
64 bytes from 10.244.0.4: seq=1 ttl=62 time=0.056 ms

--- 10.244.0.4 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 0.056/0.059/0.063 ms
```

## 参考链接

- [tkng](https://www.tkng.io/cni/)
