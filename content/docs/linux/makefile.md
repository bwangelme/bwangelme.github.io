---
title: "Makefile"
date: 2023-12-19T17:13:40+08:00
lastmod: 2023-12-19T17:13:40+08:00
tags: [linux, makefile]
author: "bwangel"
---

- `?=`

`?=` 指示仅在未设置或没有值时设置 KDIR 变量。

```makefile
# make test 将会输出 foo

KDIR ?= "foo"
KDIR ?= "bar"

test:
    echo $(KDIR)
```

