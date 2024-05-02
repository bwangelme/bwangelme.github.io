---
title: "排序"
date: 2024-05-02T11:39:20+08:00
lastmod: 2024-05-02T11:39:20+08:00
tags: [Algo, 排序]
author: "bwangel"
---

## 归并排序

### 思路

- mergeSortC 对数组的子数组进行排序，当 len(子数组) == 1 的时候，这个数组就是有序的，此时就是递归出口
- merge 对有序的子数组进行合并。
    0. left, right 两个子数组内部的元素是有序的
    1. 就像交换需要创建 tmp 变量。merge 时 先创建 tmp 数组
    3. 将 left, right 两个子数组的元素 __有序__ 放入 tmp 中
    4. 将子数组中剩余的部分放入到 tmp 中
    5. 将 tmp 更新到 arr 的对应位置

### 特性

1. 无论数据源是什么，归并排序的时间复杂度固定是 O(nlogn)
2. 归并排序的空间复杂度是 O(1) ，因为每次只有一个函数会申请一个临时数组
3. 归并排序是稳定性排序，两个相同的元素，排序之后它们的顺序不会变

### 代码

```go
func MergeSort(arr []int64) []int64 {
	mergeSortC(arr, 0, len(arr)-1)

	return arr
}

func mergeSortC(arr []int64, start, end int) {
	if start >= end {
		return
	}

	q := (start + end) / 2
	mergeSortC(arr, start, q)
	mergeSortC(arr, q+1, end)
	merge(arr, start, q, q+1, end)
}

func merge(arr []int64, leftStart, leftEnd int, rightStart, rightEnd int) {
	var tmp = make([]int64, 0)
	var leftIdx, rightIdx = leftStart, rightStart

	for leftIdx <= leftEnd && rightIdx <= rightEnd {
		if arr[leftIdx] <= arr[rightIdx] {
			tmp = append(tmp, arr[leftIdx])
			leftIdx++
		} else {
			tmp = append(tmp, arr[rightIdx])
			rightIdx++
		}
	}

	// 将子数组剩余部分放入到 tmp 中
	var (
		remainStart = leftIdx
		remainEnd   = leftEnd
	)
	if leftIdx > leftEnd {
		remainStart = rightIdx
		remainEnd = rightEnd
	}
	for remainStart <= remainEnd {
		tmp = append(tmp, arr[remainStart])
		remainStart++
	}

	// 将 tmp 的元素放入 arr 对应位置中
	for idx := 0; idx <= (rightEnd - leftStart); idx++ {
		arr[leftStart+idx] = tmp[idx]
	}
}
```

### 时间复杂度

N 等于数组长度

- T(1) = C 当数组长度为 1 时，时间复杂度是常数, 因为长度为1的数组本身是有序的，所以不需要排序

```
T(n) = 2 * T(n/2) + n
T(n) = 2*T(n/2) + n
     = 2*(2*T(n/4) + n/2) + n = 4*T(n/4) + 2*n
     = 4*(2*T(n/8) + n/4) + 2*n = 8*T(n/8) + 3*n
     = 8*(2*T(n/16) + n/8) + 3*n = 16*T(n/16) + 4*n
     ......
     = 2^k * T(n/2^k) + k * n
T(n) = 2^k * T(n/2^k) + k*n
```

```math
因为 \\
T(n/2^k) == T(1)\\

可得 \\
k = log_2{n}
```

最终得到

```math
T(n) = n * T(1) + n * log_2{n}
\newline
T(n) = n * C + n * log_2{n}
```

用大O表示法，得到 归并排序的时间复杂度是 \\( O(n*logn) \\)

### 空间复杂度

N 等于数组长度

- merge 函数中每次都会申请临时数组 tmp, 因为每次 merge 函数执行完之后，tmp 数组就被释放掉了
- 所以归并排序申请的额外空间最大不会超过 N, 所以空间复杂度是 O(N)

## 快速排序

### 思路

它的思路是，给定一个数组 arr

- partition 函数找到支撑点 pivot 的索引 p，保证 p 左边的数字都 < pivot，右边的数字都 >= pivot
    - 在  partition 函数中巧妙地实现了原地排序，没有申请新的数组空间
    - 然后再用分治的思想，分别将 p 左右两边的数组再进行排序

- 快排和归并排序的过程正好是相反的，
    - 归并排序是自底向上，先将长度为1的数组进行排序，再逐级往上
    - 快排是自顶向下，先将数组分成两份，保证 all of left < pivot < all of right, 再对左右两个数组进行排序

### 代码

```go
func QuickSort(arr []int64) []int64 {
	n := len(arr) - 1
	quickSortC(arr, 0, n)

	return arr
}

func quickSortC(arr []int64, p, r int) {
	if p >= r {
		return
	}

	q := partition(arr, p, r)
	quickSortC(arr, p, q-1)
	quickSortC(arr, q+1, r)

}

func partition(arr []int64, p, r int) int {
	// 我们选择子数组中最后一个元素作为 p 点，循环结束后，将 p 点放到中间，保证左边小于它，右边大于等于它
	pivot := arr[r]
	i := p
	for j := p; j <= r-1; j++ {
		if arr[j] < pivot {
			if i != j {
				tmp := arr[i]
				arr[i] = arr[j]
				arr[j] = tmp
			}
			i++
		}
	}

	tmp := arr[i]
	arr[i] = arr[r]
	arr[r] = tmp

	return i
}
```

### 特性

1. 快速排序不是稳定排序

给定 6, 8, 7, 6, 3, 5, 9, 4 这个数组，在第一次调用 parition 之后，6 和 6 的相对位置已经发生了变化

### 时间复杂度

大部分情况下，时间复杂度都是 \\( O(n*logn) \\), 最坏情况下时间复杂度是 \\( O(n^2) \\)

#### 最坏情况

例如 1, 3, 5, 6, 8 这个有序数组，每次分区只得到一个数组, 左边是 n-1, 右边是 0

```
T(1) = C
T(n) = T(n-1) + n
     = T(n-2) + n - 1 + n
     ....
     = T(n-n-1) + 2 + 3 + 4 ... + n

T(n) = C + 2 + 3 +4 + .. n = C + (1+n)*n/2 - 1
```

用大 O 表示法就是 

```math
O(n^2)
```

#### 最好情况

每次分区，得到两个大小相同的数组，那么它的复杂度就和归并排序完全相同，就是

```math
O(n*log_2{n})
```

### 空间复杂度

快速排序没有申请新数组空间，它的空间复杂度是 \\( O(1) \\)
