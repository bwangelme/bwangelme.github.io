---
title: "curl"
date: 2023-08-01T11:50:58+08:00
lastmod: 2023-08-01T11:50:58+08:00
author: "bwangel"
weight: 4
---

## curl POST JSON 数据

```sh
curl -X PUT -H "Content-Type: application/json" -d '@/tmp/demo.json' :9200/demo
ø> cat /tmp/demo.json
{
    "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 1
    }
}
```

## 使用 `--resolve` 选项替换域名

+ 将 www.google.com 替换成 127.0.0.1，并访问 8000 端口

`curl -v --resolve www.google.com:8000:127.0.0.1 http://www.google.com:8000/ping`

+ 将 https://www.google.com 替换成 127.0.0.1，此时 curl 会忽略证书和域名不匹配的问题

`curl -v --resolve www.google.com:443:127.0.0.1 https://www.google.com/ping`

+ 将 http://www.google.com 替换成 127.0.0.1，http 默认访问 80 端口

`curl -v --resolve www.google.com:80:127.0.0.1 http://www.google.com/ping`

## `--fail` 和 `--fail-with-body`

这两个选项都可以让 curl 在接收到 400 及以上的 HTTP 响应码的时候，将退出码设置为 22

`--fail-with-body` 会输出服务端返回的内容到 stdout 或文件中

`--fail` 不会有任何输出，当服务端返回的是认证相关的状态码时(401/407), 可能会让使用者误以为出错了

### 使用场景

在一个 dockerfile 中，我期望下载项目的 `go.mod` 和 `go.sum` 文件，然后再执行 `go mod download`。
这样可以在 clone 代码之前，先下载 go module 文件。

如果项目的代码变了，但是依赖并没有变，因为 docker build 的缓存原理，可以省去下载 go module 的步骤。

```
...
ARG app_repo
ARG app_commit

RUN [[ ! -d /tmp/app ]] && mkdir /tmp/app && \
    curl -s https://raw.githubusercontent.com/${app_repo}/${app_commit}/go.mod -o /tmp/app/go.mod && \
    curl -s https://raw.githubusercontent.com/${app_repo}/${app_commit}/go.sum -o /tmp/app/go.sum

RUN cd /tmp/app && go mod download
...
```

当 app_repo 和 app_commit 参数错误，导致对应的 go.mod 文件不存在，curl 会得到 404 的 HTTP 响应码，此时我期望 docker build 出错。

但实际上并不会出错，docker build 会继续执行，直到 go mod download 文件无法识别 go.mod 文件，docker build 才会异常退出。

显示的错误内容如下:

```
0.467 go: errors parsing go.mod:
0.467 /tmp/app/go.mod:1: unknown directive: 404:
```

当我给 `curl` 加上了 `--fail` 选项之后，程序就会在下载 go.mod 出错时直接退出。显示的错误如下:

```
ERROR: failed to solve: 
	process "
		/bin/bash -c [[ ! -d /tmp/app ]] && mkdir /tmp/app &&
		curl --fail -s https://raw.githubusercontent.com/${app_repo}/${app_commit}/go.mod -o /tmp/app/go.mod &&
		curl -s https://raw.githubusercontent.com/${app_repo}/${app_commit}/go.sum -o /tmp/app/go.sum
	" did not complete successfully: exit code: 22
```

最终的 dockerfile 代码及复现命令

```
FROM golang:1.19
SHELL ["/bin/bash", "-c"]

ARG app_repo
ARG app_commit

RUN go env -w GOPROXY=https://goproxy.cn,direct

RUN [[ ! -d /tmp/app ]] && mkdir /tmp/app && \
    curl --fail -s https://raw.githubusercontent.com/${app_repo}/${app_commit}/go.mod -o /tmp/app/go.mod && \
    curl -s https://raw.githubusercontent.com/${app_repo}/${app_commit}/go.sum -o /tmp/app/go.sum

RUN cd /tmp/app && go mod download
RUN HTTP_PROXY='http://改成你自己的代理' HTTPS_PROXY='http://改成你自己的代理' git clone https://github.com/${app_repo}.git ~/app
RUN cd ~/app && git reset --hard ${app_commit} && go build .
```

- 复现命令

```
# 注意这个 app_commit 是一个不存在的 commit
docker build -t curl_test --build-arg app_repo=bwangelme/rdcdemo --build-arg app_commit=2f24a0658d7feb0205e7d75b7ae218ff6495e8f3 .
```

## 使用代理

- 使用 http 代理

```bash
curl -x http://127.0.0.1:1087 https://www.google.com/

# 可以简写, 默认的 proxy 协议是 http

curl -x 127.0.0.1:1087 https://www.google.com/
```

- 使用 socks5 代理

```bash
curl --socks5-hostname 127.0.0.1:1080 https://www.google.com/

# 可以简写, socks 代理默认端口是 1080

curl --socks5-hostname 127.0.0.1 https://www.google.com/

# 使用 -x 的形式写代理地址, socks5h 等价于 --socks5-hostname
curl -x 'socks5h://localhost:1080' https://www.google.com
```

__注意__: socks5 代理必须使用 `--socks5-hostname` 选项, 不能使用 `--socks5` , 要不然 dns 解析不会走代理, 导致请求失败

> socks5 和 socks5h 主要区别在于DNS解析的处理方式：
> - socks5: 在这种模式下，DNS解析是在客户端（即你本地的计算机）进行的。这意味着你本地的DNS服务器会解析你请求的域名，然后通过SOCKS5代理将请求发送出去。
> - socks5h: 在这种模式下，DNS解析是在代理服务器上进行的。这意味着代理服务器会解析域名，然后通过代理将请求发往目标服务器。这种方式有助于隐藏你的本地IP地址和DNS查询结果，增加了隐私保护。

- 覆盖环境变量的代理

```bash
# -x '' 指定代理为空, 使得 curl 不走代理, 覆盖了环境变量 http_proxy 设置的代理

$ http_proxy='http://127.0.0.1:1087' curl -x '' cip.cc
IP      : 122.190.50.89
地址    : 中国  湖北  武汉
```
