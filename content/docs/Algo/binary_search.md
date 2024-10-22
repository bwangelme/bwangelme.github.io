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
```
