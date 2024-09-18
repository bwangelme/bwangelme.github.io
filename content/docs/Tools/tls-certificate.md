---
title: "TLS 验证证书的过程"
date: 2024-09-18T17:20:20+08:00
lastmod: 2024-09-18T17:20:20+08:00
tags: [tls, openssl]
author: "bwangel"
---

## 查看证书

从网站 www.bwangel.me 上下载证书，输出成 www_bwangel_me_cert.pem 文件

```
openssl s_client -connect www.bwangel.me:443 -servername www.bwangel.me </dev/null | openssl x509 -outform PEM > www_bwangel_me_cert.pem
```

x509 证书中有以下几个关键字段

- Signature Algorithm: sha256WithRSAEncryption 证书数字签名的算法
- Signature Value: 证书数字前面的值
- Subject/CN: Common Name，证书的通用名称
- Issuer/CN: 证书颁发机构的通用名称
- Subject Public Key Info: 证书中包含的公钥

```bash
# 以下命令可以查看证书的信息
openssl x509 -in www_bwangel_me_cert.pem -text -noout
```

根证书是自签名的，Subject 和 Issuer 相同。

根证书是内置在电脑中的，`ca-certificates` 包提供了常用的根证书，`/etc/ssl/cert.pem` 中包含了系统内置的根证书。

```bash
# 这是根证书 Internet Security Research Group 的信息
ø> openssl x509 -in isrg.pem -text -noout
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            82:10:cf:b0:d2:40:e3:59:44:63:e0:bb:63:82:8b:00
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=US, O=Internet Security Research Group, CN=ISRG Root X1
        Validity
            Not Before: Jun  4 11:04:38 2015 GMT
            Not After : Jun  4 11:04:38 2035 GMT
        Subject: C=US, O=Internet Security Research Group, CN=ISRG Root X1
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (4096 bit)
                Modulus:
                    00:ad:e8:24:73:f4:14:37:f3:9b:9e:2b:57:28:1c:
                    ...
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Certificate Sign, CRL Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier:
                79:B4:59:E6:7B:B6:E5:E4:01:73:80:08:88:C8:1A:58:F6:E9:9B:6E
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        55:1f:58:a9:bc:b2:a8:50:d0:0c:b1:d8:1a:69:20:27:29:08:
        ...
```

## 证书验证的流程

- 客户端请求服务器，服务器返回证书链上除了根证书的所有证书。以下命令可以查看证书链上所有证书

```
openssl s_client -connect www.bwangel.me:443 -showcerts
```

- 客户端拿到证书后，根据 Issuer/CN 找颁发者证书，颁发者再往上找颁发者的证书，直至找到根证书。
- 根据根证书的公钥验证下一级证书的数字签名是否正确
    - 根据公钥解密出数字签名中的 hash 值
    - 根据证书签名算法，计算 hash 值，比较计算的 hash 值和数字签名中解密出的 hash 值是否相同
- 逐级向下验证证书链中的所有证书，直至验证目标网站的证书。
