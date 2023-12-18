---
title: "利用 Python 处理字符串"
date: 2023-12-14T12:06:58+08:00
lastmod: 2023-12-14T12:06:58+08:00
tags: [python, shell]
author: "bwangel"
---

/tmp/abc.md 中的内容如下

```
subject/music
antispam/karazhan
```

我想输出成

```
Repo(dir='music', name='subject/music'),
Repo(dir='karazhan', name='antispam/karazhan'),
```

可以利用 Python 来做解析重组字符串的工作, `sys.argv[1]` 就是每行想要解析的字符串

- parse.py

```py
import sys

dir_=sys.argv[1].split('/')[1]
name=sys.argv[1]
print("Repo(dir='%s', name='%s')," % (dir_, name))
```

如果 xargs 不加 -I 那就是将多行内容聚合到一行解析。

```
cat /tmp/abc.md | rg -v '^#' | xargs -I{} python3 /tmp/parse.py {}
```

