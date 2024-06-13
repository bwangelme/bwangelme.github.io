---
title: "Pytest Tips"
date: 2024-06-13T15:40:02+08:00
lastmod: 2024-06-13T15:40:02+08:00
tags: [Python, pytest]
author: "bwangel"
---

## pytest 启动 pdb 调试

0. 安装 ipython

1. 在想要打断点的地方, 写入语句 `import pdb; pdb.set_trace()`

2. 执行 pytest 测试函数

```
pytest dir/test_files --pdb --pdbcls=IPython.terminal.debugger:TerminalPdb
```

## Pytest 开启日志记录

1. 在根目录中创建 `conftest.py` 文件
2. 在 `conftest.py` 文件中写入以下函数

```
def pytest_configure(config):
    logger = logging.getLogger('')
    logger.setLevel(logging.DEBUG)
```

这将会将所有 logger 的级别设置为 debug, pytest 执行测试的过程中,在 `---Captured log call---` 章节中将会看到捕获的日志输出
