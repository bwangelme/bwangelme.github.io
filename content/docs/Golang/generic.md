---
title: "泛型"
date: 2023-08-15T19:22:52+08:00
lastmod: 2023-08-15T19:22:52+08:00
tags: [Golang]
author: "bwangel"
---

## 利用泛型实现的语法糖

```go
// Cond
// 条件表达式的简单实现，支持任意类型
func Cond[T any](val bool, a, b T) T {
	if val {
		return a
	}
	return b
}

// Or
// 返回 vals 中第一个不是对应类型0值的参数，如果没有，则返回对应类型的0值
func Or[T comparable](vals ...T) T {
	for _, val := range vals {
		if val != *new(T) {
			return val
		}
	}
	return *new(T)
}
```

- 用法

```go
func TestCond(t *testing.T) {
	assert.Equal(t, 1, Cond(true, 1, 2))
	assert.Equal(t, 2, Cond(false, 1, 2))
	var req *http.Request
	assert.Equal(t, http.MethodGet, Cond(req == nil, http.MethodGet, http.MethodPost))
}

func TestOr(t *testing.T) {
	// 范型函数可以不传类型参数
	// 我在 1.18, 1.19, 1.20 上测试均可以工作
	assert.Equal(t, 0, Or[int]())
	assert.Equal(t, 0, Or(0))
	assert.Equal(t, 1, Or(1))
	assert.Equal(t, 2, Or(0, 2))
	assert.Equal(t, 3, Or(0, 0, 3))
}
```
