---
title: "Leetcode 142: 环形链表 II"
date: 2022-09-11T10:54:04+08:00
lastmod: 2022-09-11T10:54:04+08:00
draft: false
tags: [Algo, blog]
author: "bwangel"
comment: true

---

<!--more-->
---

## 题目

给定一个链表的头节点  head ，返回链表开始入环的第一个节点。 如果链表无环，则返回 null。

链表节点的定义如下

```go
type ListNode struct {
	Val  int
	Next *ListNode
}
```

## 解题思路

### 判断链表是否有环

判断链表是否有环就使用简单的双指针法。

定义两个指针，slow, fast, 它们一起从 head 开始往前移动，slow 每次移动一步，fast 每次移动两步。

因为每次移动后 fast 比 slow 多一步，如果链表有环的话，它们一定会相遇。代码如下

```go
// 判断链表中是否有环，并返回 slow 指针
func getCycleSlow(head *ListNode) *ListNode {
	if head == nil {
		return nil
	}

	var (
		fast = head
		slow = head
	)

	// 注意这里的判断条件，先判断 fast 再判断 fast.Next
	for fast != nil && fast.Next != nil && slow != nil {
		fast = fast.Next.Next
		slow = slow.Next

		if fast == slow {
			// 快慢指针重合
			// s = nb
			// f = 2nb
			return slow
		}
	}

	// 链表中没有环，此时 slow == nil
	return nil
}
```

我们假设链表中存在环，环的长度是 `b`。那么当 `getCycleSlow` 结束时，我们可以得到以下结论

- fast 移动的步数是 slow 的两倍

```math
fast = 2 * slow
```

- fast 比 slow 多走了 n 次环的长度

```math
fast = slow + n * b
```

将上述两式相减，可以得到

```math
slow = n * b
```

```math
fast = 2 * n * b
```

### 寻找环的入口

我们令 `a` 为从起点 head 到 环入口的距离，任意一个节点，从起点 head 走到环入口的距离为 k 步，可得:

```math
k = a + n * b
```

\\(b\\) 表示环的长度，任意一个节点从 head 开始，走 \\(a\\) 步后可以到达环入口，在环中再走 \\(n\\) 圈后，又到达了环入口。

此时我们继续用双指针法，

1. 定义一个追赶者 `pursuer`，让它从 head 开始往前走 \\(a\\) 步。
2. 同时让 \\(slow\\) 开始往前走 \\(a\\) 步。

因为 \\(slow\\) 已经走了 \\(n * b\\) 步了，所以当 \\(slow\\) 走了 \\(a + n * b\\) 步后，`pursuer` 走了 \\(a\\) 步之后，\\(slow\\) 和 `pursuer` 就会在环的入口相遇。

代码如下

```go
func detectCycle(head *ListNode) *ListNode {
	var pursuer = head

	// 判断有环的同时，返回 slow 的位置
	var slow = getCycleSlow(head)
	if slow == nil {
		return nil
	}

	// 因为链表中有环，slow 和 pursuer 一定能够相遇
	for {
		// 需要先判断 pursuer == slow，因为 slow 可能正好停在环入口
		if pursuer == slow {
			return pursuer
		}

		pursuer = pursuer.Next
		slow = slow.Next
	}
}
```


## 参考链接

- [环形链表 II（双指针法，清晰图解）](https://leetcode.cn/problems/linked-list-cycle-ii/solution/linked-list-cycle-ii-kuai-man-zhi-zhen-shuang-zhi-/)
