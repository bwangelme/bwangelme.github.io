---
title: 'Sublime小记'
date: 2016-04-10 10:56:54
tags: [工具]
---

__摘要__:

> 关于Sublime Text的一些小记


<!--more-->

## Goto Anything

`Ctrl + p`输入文件名或者文件路径来打开文件

在css文件中，输入`@`会列出所有css选择器

在js文件中，输入`@`会列出所有函数

## MacOS Sublime 多行复制不规则文本

```protobuf
service UserService {
  rpc Register(RegisterReq) returns (RegisterResp); // 创建用户

  rpc InitUserInfo(InitUserInfoReq) returns (InitUserInfoResp);

  // 获取用户最简化资料，是一个聚合接口，用于客户端展示
  rpc GetSimpleUsers(GetSimpleUsersReq) returns (GetSimpleUsersResp);
}
```

这样的文件，我只想复制方法名

- cmd+f 搜索
- 搜索框中输入 `(?<=rpc\s)(\w+)`
- 按 options+enter 选中所有复制文本
- 按 cmd+c 复制

### lookbehind 断言

`(?<=)` 是 lookbehind 断言，它的功能是

- __👉 匹配某个位置，但要求它前面必须是某个内容（且不包含这个内容）__
- lookbehind 里一般不能写可变长度，`(?<=rpc\s+)`（有些引擎不支持）

### 类似的断言概念

| 写法        | 名字     | 含义        |
| --------- | ------ | --------- |
| `(?<=A)B` | 正向后行断言 | B 前面必须是 A |
| `(?<!A)B` | 负向后行断言 | B 前面不能是 A |
| `A(?=B)`  | 正向先行断言 | A 后面必须是 B |
| `A(?!B)`  | 负向先行断言 | A 后面不能是 B |