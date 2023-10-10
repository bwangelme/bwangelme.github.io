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
mid = left + ((right-left) >> 2))
```

3. left 和 right 的更新方法

```
left = mid + 1
right = mid - 1
```

