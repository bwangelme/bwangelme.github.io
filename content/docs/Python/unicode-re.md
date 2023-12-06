---
title: "Python2 的正则在 Mac 和 Linux 上的不同表现"
date: 2023-12-06T12:20:47+08:00
lastmod: 2023-12-06T12:20:47+08:00
tags: [Python, Unicode, re]
author: "bwangel"
---

## 表现

```
s = u'玛丽黛佳眉笔只-需-18,冲p腹t製o2𝒂I5EfW4xPmTq𝒃o2打🤔开桃o寶'
```

这个字符串 s 是一段淘口令，核心内容就是 𝒂 和 𝒃 之间的 ID `I5EfW4xPmTq`, 我们想用一个正则表达式将 ID 捕获出来。

𝒂 和 𝒃 的 unicode 码点不在基本平面内，在1号平面内。Unicode 各个平面的字符范围参考 [维基百科](https://zh.wikipedia.org/wiki/Unicode%E5%AD%97%E7%AC%A6%E5%B9%B3%E9%9D%A2%E6%98%A0%E5%B0%84)

在 MacOS 的 Python2 上，可以用下面这段正则捕获

```
ur"[\uD800-\uDBFF][\uDC00-\uDFFF]([a-zA-Z0-9]{11})[\uD800-\uDBFF][\uDC00-\uDFFF]"
```

`D800-DBFF`, `DC00-DFFF` 表示非基本平面的字符，用 utf-16 编码后，生成的两个字节。

MacOS 的 Python2 中，编译的时候默认使用了 UCS2 作为 Unicode 的编码实现，`sys.maxunicode == 65535`， 它不支持展示非基本平面外的 unicode 字符，所以只能用这种办法来绕过。

在 Linux 的 Python2 中，上述正则就失效了，需要用另外一个正则

```
ur"[\U00010000-\U0001FFFF]([a-zA-Z0-9]{11})[\U00010000-\U0001FFFF]"
```

`00010000-0001FFFF` 表示1号平面内的所有字符。

Linux 的 Python2 中，Unicode 的编码实现使用的是 UCS4，`sys.maxunicode == 1114111`, 它可以展示 Unicode 17 个平面中的所有字符，所以在正则中可以直接写非基本平面的码点

## 如何开启 UCS4

编译 Python 的时候，指定 `--enable-unicode=ucs4` 即可指定 unicode 的编码实现是 UCS4, 从而支持展示所有平面的 Unicode 码点。

```
curl -O https://www.python.org/ftp/python/2.7.8/Python-2.7.8.tgz
tar xf ./Python-2.7.8.tgz
cd ./Python-2.7.8
./configure --enable-unicode=ucs4 --prefix=/path/to/install MACOSX_DEPLOYMENT_TARGET=10.9
make
make install
cd
/path/to/install/bin/python2.7
```

## 参考链接

- [How to install python on Mac with wide-build](https://stackoverflow.com/a/25112348/5161084)
- [Unicode字符平面映射](https://zh.wikipedia.org/wiki/Unicode%E5%AD%97%E7%AC%A6%E5%B9%B3%E9%9D%A2%E6%98%A0%E5%B0%84)
- [细说：Unicode, UTF-8, UTF-16, UTF-32, UCS-2, UCS-4](https://www.cnblogs.com/malecrab/p/5300503.html)
