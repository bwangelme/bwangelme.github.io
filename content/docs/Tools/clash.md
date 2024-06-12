---
title: "UKnowY"
date: 2024-06-12T20:58:32+08:00
lastmod: 2024-06-12T20:58:32+08:00
tags: [clash]
author: "bwangel"
---

## Justmysocks 的订阅链接生成 clash 配置文件

1. 启动 subconverter

```
docker run -d --restart=always -p 25500:25500 tindy2013/subconverter:latest
```

2. 将下面命令中的 `https://justmysock.subscribe.url` 替换成你的 justmysock 服务的订阅地址, 可以得到一个 curl 命令

```
python -c "from urllib.parse import urlencode; print('curl \'http://localhost:25500/sub?%s\' > /tmp/config.yaml ' % urlencode({'target': 'clash', 'url': 'https://justmysock.subscribe.url'}))"
```

```
curl 'http://localhost:25500/sub?target=clash&url=https%3A%2F%2Fjustmysock.subscribe.url' > /tmp/config.yaml
```

3. 执行此 curl 命令, 生成的 clash 配置文件保存到了 `/tmp/config.yaml` 中,将此文件导入到 clash 中

- [subconverter README](https://github.com/tindy2013/subconverter/blob/master/README-cn.md)
