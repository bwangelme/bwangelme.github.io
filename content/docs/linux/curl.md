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
