---
title: "Go 内部实现"
date: 2025-04-17T22:43:37+08:00
lastmod: 2025-04-17T22:43:37+08:00
tags: [Golang]
author: "bwangel"
---

## Golang 中计算指针长度

```go
// PtrSize is the size of a pointer in bytes - unsafe.Sizeof(uintptr(0)) but as an ideal constant.
// It is also the size of the machine's native word size (that is, 4 on 32-bit systems, 8 on 64-bit).
const PtrSize = 4 << (^uintptr(0) >> 63)
```

这是 Golang 中计算指针长度的方式。

uintptr(0) 表示将0转换成无符号整数类型

| 执行步骤                       | 32位系统的值      | 64位系统的值            |
|----------------------------|--------------|--------------------|
| uintptr(0)                 | 0x00000000   | 0x0000000000000000 |
| `^uintptr(0)`              | 0xFFFFFFFF   | 0xFFFFFFFFFFFFFFFF |
| `^uintptr(0) >> 63`        | 0x00000000   | 0x0000000000000001 |
| `4 << (^uintptr(0) >> 63)` | `4 << 0 = 4` | `4 << 1 =8`        |

通过以上步骤，会计算出不同平台中，指针的字节长度(4 或 8)。

+ 这样设计的好处

1. 编译时确定：通过常量表达式在编译阶段直接计算出指针长度，无需运行时判断。
2. 跨平台兼容：利用 uintptr 的平台相关性自动适配 32/64 位架构。

+ 与 unsafe.Sizeof 的关系
   - **unsafe.Sizeof(uintptr(0))**：返回运行时指针的大小（动态值，但 Go 中 uintptr 的大小在编译时已知）。
   - **PtrSize**：等效于 unsafe.Sizeof(uintptr(0))，但作为编译时常量，可用于需要常量的场景（如数组长度声明）。

## Golang 中 map 的实现

- 每个 map 中有若干个桶，每个桶中有8个键值对
- map 写入 
  - 计算 key 的哈希值
  - 根据哈希值计算要写入的桶
  - 将数据写入到桶中，如果桶溢出，那么使用链表扩展桶
- map 查找
  - 计算 key 的哈希值
  - 根据哈希值计算要写入的桶
  - 遍历桶查找数据
- map 扩容
  - 当桶溢出触发某个条件，对 map 进行扩容
  - 不是立刻扩容，是渐进式的，每次访问时进行扩容
- 解决哈希冲突
  - 当哈希冲突发生时，使用链地址法解决冲突，将相同哈希的元素放到链表中
- map 遍历
  - TODO
- TODO: 内存对齐
