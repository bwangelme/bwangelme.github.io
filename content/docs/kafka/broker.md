---
title: "Broker"
date: 2023-09-11T16:27:26+08:00
lastmod: 2023-09-11T16:27:26+08:00
tags: [kafka, tips]
author: "bwangel"
---

## 优雅地关闭 Kafka Broker

向进程发送 `TERM` 信号就可以优雅地关闭 Kafka Broker

这是 `bin/kafka-server-stop.sh` 的内容，他的思路就是通过 ps 查找 cmd 中包括 `kafka.Kafka` 的进程，来寻找进程 ID

```sh
SIGNAL=${SIGNAL:-TERM}

OSNAME=$(uname -s)
if [[ "$OSNAME" == "OS/390" ]]; then
    if [ -z $JOBNAME ]; then
        JOBNAME="KAFKSTRT"
    fi
    PIDS=$(ps -A -o pid,jobname,comm | grep -i $JOBNAME | grep java | grep -v grep | awk '{print $1}')
elif [[ "$OSNAME" == "OS400" ]]; then
    PIDS=$(ps -Af | grep -i 'kafka\.Kafka' | grep java | grep -v grep | awk '{print $2}')
else
    PIDS=$(ps ax | grep ' kafka\.Kafka ' | grep java | grep -v grep | awk '{print $1}')
fi

if [ -z "$PIDS" ]; then
  echo "No kafka server to stop"
  exit 1
else
  kill -s $SIGNAL $PIDS
fi
```

但是 Linux 内核有限制，ps 输出的一行内容不能超过页大小 `PAGE_SIZE` (4096)，所以如果 kafka 进程的 cmd 过长，可能会导致 ps + grep 失败。

此时就需要我们手动来找对应的进程，可以通过 `ps ax | grep 'kafka'` 来寻找对应的进程。

## 存储

- 顺序写盘的速度不仅比随机写盘的速度快，而且也比随机写内存的速度快。kafka 在设计时采用了文件追加的方式来写入消息，即只能在日志文件的尾部追加新的消息，并且也不允许修改已经写入的消息，这种方式属于典型的顺序写盘的操作。

- kafka 大量地使用了页缓存来提高读写文件的效率，而并没有怎么使用进程内的缓存。Java 对象的内存开销非常大，是真实数据的几倍，Java 的 GC 会随着堆内数据的增多而变得越来越慢。基于以上考虑，kafka 使用 Linux 为文件 I/O 提供的页缓存，而不是使用 Java 进程内的缓存。

- Linux 系统提供了 swap 分区的功能，将非活跃的进程调入 swap 分区，以此把内存空出来让给活跃的进程。对于大量使用系统页缓存的 kafka 而言，应避免这种内存的交换，否则会对它各方面的性能产生较大的影响。`vm.swappiness` 参数控制 swap 分区的使用率，数值在 0 - 100，数值越大使用的越多，建议设置成1，不设置成 0 防止系统在内存耗尽时 kill 进程。
