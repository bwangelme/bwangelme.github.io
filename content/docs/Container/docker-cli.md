---
title: "Docker Cli"
date: 2024-01-04T16:53:10+08:00
lastmod: 2024-01-04T16:53:10+08:00
tags: [docker]
author: "bwangel"
---

## docker cli 获取所有容器的 IP

```
docker ps | rg -v CONTAINER | awk '{print $1}' \
    | xargs docker inspect -f \
    '{{.Name}}{{"\t"}}{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```
