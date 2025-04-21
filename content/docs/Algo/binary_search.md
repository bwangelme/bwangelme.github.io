---
title: "二分查找"
date: 2023-10-10T09:31:53+08:00
lastmod: 2023-10-10T09:31:53+08:00
tags: [tips, algo]
author: "bwangel"
---

## 二分查找的注意点

1. 循环的条件: `left <= right`
2. mid 计算方法:

```
# 用移位预算速度更快
mid = left + ((right-left) >> 1))
```

3. left 和 right 的更新方法

```
left = mid + 1
right = mid - 1
```

```go
// BinarySearchLastV2
/**
## 功能

返回 arr 中最后一个 == num 的数字的索引

 **/
func BinarySearchLastV2(arr []int64, num int64) int {
	var (
		low  = 0
		n    = len(arr)
		high = n - 1
	)

	/**
	1. for 循环结束后, low > high
	2. 由于 midNum <= num 条件先执行，for 结束后, low 指向第一个 > n 的数，high 指向 low 的前一位
	3. 如果 high 的索引在数组中，且 arr[high] == num, 那么 high 就是 num 在数组中最后一位
	*/
	for low <= high {
		mid := low + ((high - low) >> 1)
		midNum := arr[mid]
		if midNum <= num {
			low = mid + 1
		} else {
			high = mid - 1
		}
	}

	if high > 0 && arr[high] == num {
		return high
	}

	return -1
}

// BinarySearchFirstV2
/**
## 功能

返回 arr 中第一个 == num 的数字的索引

 **/
func BinarySearchFirstV2(arr []int64, num int64) int {
	var (
		low  = 0
		n    = len(arr)
		high = n - 1
	)

	/**
	## 对于 num 存在的情况
	1. for 循环结束后，low > high
	2. 由于判断条件 midNum >= num 先检查，所以循环结束后， arr[high] != num
	3. low > high, arr[high] != num, 所以 arr[low] 是第一个 num

	## 对于 arr 所有数比 num 小的情况
	1. for 循环结束后，low > high
	2. high 一次也没移动，low = n
	3. 此时 low 超出数组长度，arr[low] 会异常，所以要先判断 low < n

	## 对于 arr 所有数比 num 大的情况
	1. for 循环结束后，low > high
	2. low 一次也没移动，low = 0, high = -1
	3. 此时 arr[low] != num 不存在

	## 对于 num 处于 arr 中部但不存在的情况
	1. for 循环结束后，low > high
	2. low < n, arr[low] != num, return -1
	*/

	for low <= high {
		mid := low + ((high - low) >> 1)
		midNum := arr[mid]
		if midNum >= num {
			high = mid - 1
		} else {
			low = mid + 1
		}
	}

	if low < n && arr[low] == num {
		return low
	}

	return -1
}

```
