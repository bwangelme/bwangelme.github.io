---
title: "httpie"
date: 2024-11-27T16:50:23+08:00
lastmod: 2024-11-27T16:50:23+08:00
tags: [httpie, tools]
author: "bwangel"
---

## httpie 使用 jq 解析 JSON 响应

```
http -v -o - -d https://api.github.com/users/bwangelme | jq '.bio'
```

- 命令中选项的说明

- `-v` 输出请求体，请求 header，响应 header
- `-o -` 将 response body 输出到 stdout 中
- `-d` 当 `-d` 选项开启时，`-o` 会只将 response body 输出到 stdout 中，其他部分(header, 请求体)会输出到 stderr 中
- `| jq '.bio'` 输出响应体中的 `bio` 字段

```
ø> http -v -o - -d https://api.github.com/users/bwangelme | jq '.bio'
GET /users/bwangelme HTTP/1.1
Accept: */*
Accept-Encoding: identity
Connection: keep-alive
Host: api.github.com
User-Agent: HTTPie/3.2.3



HTTP/1.1 200 OK
Accept-Ranges: bytes
Access-Control-Allow-Origin: *
Access-Control-Expose-Headers: ETag, Link, Location, Retry-After, X-GitHub-OTP, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Used, X-RateLimit-Resource, X-RateLimit-Reset, X-OAuth-Scopes, X-Accepted-OAuth-Scopes, X-Poll-Interval, X-GitHub-Media-Type, X-GitHub-SSO, X-GitHub-Request-Id, Deprecation, Sunset
Cache-Control: public, max-age=60, s-maxage=60
Content-Length: 1254
Content-Security-Policy: default-src 'none'
Content-Type: application/json; charset=utf-8
Date: Wed, 27 Nov 2024 08:48:31 GMT
ETag: W/"602829689b0bfe6dd876cdac25d7bb03b2366b7c52c3c65cfb461b4664ba1743"
Last-Modified: Tue, 05 Nov 2024 07:45:58 GMT
Referrer-Policy: origin-when-cross-origin, strict-origin-when-cross-origin
Server: github.com
Strict-Transport-Security: max-age=31536000; includeSubdomains; preload
Vary: Accept,Accept-Encoding, Accept, X-Requested-With
X-Content-Type-Options: nosniff
X-Frame-Options: deny
X-GitHub-Media-Type: github.v3; format=json
X-GitHub-Request-Id: DC16:22CCB7:6C77CC:7A9813:6746DCE6
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 53
X-RateLimit-Reset: 1732699633
X-RateLimit-Resource: core
X-RateLimit-Used: 7
X-XSS-Protection: 0
x-github-api-version-selected: 2022-11-28

Downloading to <stdout>
Done. 1.3 kB in 00:0.04114 (30.5 kB/s)
"不念过去，不畏将来"
```
