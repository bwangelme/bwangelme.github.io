---
title: "素数生成器"
date: 2018-08-14T06:54:09+08:00
draft: false
tags: [Go, blog]
aliases:
  - /2018/08/14/素数生成器/
---

一个不太优雅的素数生成器，主要用来观察“Go-routine + 管道”的开发方式

<!--more-->

## 前言

在阅读《Go高级编程》的时候，里面有个用 Newsqueak 编写的生成素数的例子，感觉这个例子很有意思，我就把它用Go重写了一下，特来此记录一下。

## 代码

下面的程序实现了一个“素数生成器”，它将会输出前`N`个素数:

```go
package main

import "fmt"

func counter(c chan int) {
	i := 2
	for {
		c <- i
		i++
	}
}

/*
 * FilterPrime 将素数`prime`的倍数过滤掉，将不是`prime`倍数的数字输出
 *
 * 图示说明: https://passage-1253400711.cos.ap-beijing.myqcloud.com/2018-08-13-150647.png
 */
func FilterPrime(prime int, listen, send chan int) {
	var i int

	for {
		i = <-listen
		if i%prime != 0 {
			send <- i
		}
	}
}

func sieve() (prime chan int) {
	c := make(chan int)
	go counter(c)

	prime = make(chan int)
	go func() {
		var p int
		var newc chan int

		for {
			p = <-c
			prime <- p
			newc = make(chan int)
			go FilterPrime(p, c, newc)
			c = newc
		}
	}()

	return prime
}

func main() {

	// 这种方法计算素数，每产生一个素数，就需要新建一个goroutine。
	// 例如求前N个素数，空间复杂度为O(N)，时间复杂度为O(M)，M表示第N个素数的大小
	prime := sieve()
	const N = 100

	var times [N][0]int
	for range times {
		p := <-prime
		fmt.Println(p)
	}
}
```

## 分析

整个素数生成器可以用下面这张流程图来表示。

![素数生成器流程图](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2018-08-13-150647.png)

上图中各个 Goroutine 的说明如下

+ Counter 用来生成从2到N的数字
+ `FilterPrimer(prime, listen, send)` 从`listen`__输入管道__中读取数字，将素数`prime`的倍数过滤掉，然后将结果输出到`send`__输出管道__中
+ `sieve`负责从读取素数，并根据产生的素数新建`FilterPrime`进行后续的过滤

整个程序的流程如下：

+ Counter 产生第一个素数2，`sieve` Goroutine 将2输出到`prime`管道中，并以此建立 Goroutine `FilterPrime(2)`，`Counter`的输出管道会成为`FilterPrime(2)`的输入管道
+ `FilterPrime(2)`从输入管道中读取数字并过滤输出，它输出的第一个数字是素数3。`sieve` Goroutine 将3输出到`prime`管道中，并以此建立 Goroutine `FilterPrime(3)`，`FilterPrime(2)`的输出管道会作为`FilterPrime(3)`的输入管道
+ `FilterPrime(3)`从输入管道读取数字并过滤输出，它输出的第一个数字是素数5（4已经被`FilterPrime(2)`过滤掉了）。`sieve` Goroutine 将5输出到`prime`管道中，并以此建立 Goroutine `FilterPrime(5)`，`FilterPrime(3)`的输出管道会作为`FilterPrime(5)`的输入管道
+ 依次类推。。。
+ 最终可以从管道`prime`中读取出素数，`prime`管道每次读取，数字都会从`Counter`产生，然后经过一层层过滤，最终将素数输出出来，并根据这个输出的素数，建立下一个`FilterPrime` Goroutine。

从上面的分析中我们可以看出，如果我们想要获取前N个素数，那么就需要建立N+2个 Goroutine 和N+1个 Channel 。故其空间复杂度为O(2N)。同时，整个程序的流程就是`Counter`产生数字，然后经历一个一个的`FilterPrime`，最终将素数过滤出来，整个循环只进行一次，所以时间复杂度为O(M)，其中M表示第N个素数的值。

## 参考文章

+ [《Go高级编程》1.2.3小节](https://chai2010.gitbooks.io/advanced-go-programming-book/content/ch1-basic/ch1-02-hello-revolution.html)
