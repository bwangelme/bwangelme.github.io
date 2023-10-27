---
title: "Python2 使用 Thrift 时为什么会出现 EINTR 错误"
date: 2023-10-27T09:22:30+08:00
lastmod: 2023-10-27T09:22:30+08:00
tags: [python, thrift]
author: "bwangel"
---

## 复现一个 EINTR 错误

当 Python2 调用 Thrift 的时候，收到信号后，会出现一个 TTransportException。

我们可以用以下代码复现一下这个错误

### 代码准备

1. 从 [github.com/bwangelme/thrift-eintr](https://github.com/bwangelme/thrift-eintr) 克隆代码
2. 在代码目录中，使用 virtualenv 创建 venv2 和 venv3 分别 2 和 3 Python 虚拟环境

```
~/.pyenv/versions/2.7.18/bin/virtualenv venv2
~/.pyenv/versions/3.11.0/bin/virtualenv venv3
```

服务端的代码比较简单，就不过多赘述了，客户端的代码中主要做了两件事情。

1. 处理 SIGUSR1 信号
2. 调用 get_image 接口获取文件

```py
def signal_handler(signum, frame):
    print("Receive sig %s" % (signum,))


def main():
    # 注册处理信号的 handler
    signal.signal(signal.SIGUSR1, signal_handler)

    print("Start client @ %s" % (os.getpid()))
    transport = TSocket.TSocket('localhost', 9090)
    transport = TTransport.TBufferedTransport(transport)
    protocol = TBinaryProtocol.TBinaryProtocol(transport)
    client = Calculator.Client(protocol)
    transport.open()

    print("Start thrift req")
    start = time.time()
    # 调用 thrift 接口
    res = client.get_image()
    dur = time.time() - start
    print("get %d bytes in %s" % (len(res), dur))


if __name__ == '__main__':
    try:
        main()
    except Thrift.TException as tx:
        # 遇到错误后打印异常和栈信息
        print(tx, tx.inner)
        traceback.print_exc()
```

### 复现错误

1. 为了有时间能够发送信号，我们首先调慢 lo 网卡(即 localhost)的发包速度, 这样 `get_image` 接口就会持续十几秒才结束。

```
# 设置 lo 网卡上发出去的包都有 1000ms 的延迟
ø> sudo tc qdisc add dev lo root netem delay 1000ms

# 使用 list 可以看到我们刚刚创建的规则
ø> sudo tc qdisc list
qdisc netem 8001: dev lo root refcnt 2 limit 1000 delay 1s
...

# 执行完测试函数后，记得删掉这个规则
ø> sudo tc qdisc del dev lo root
```

2. 首先使用 `./venv2/bin/python server.py` 启动 server, 然后再启动 client

```
ø> ./venv2/bin/python client.py

Start client @ 241683
Start thrift req
```

client 启动以后，会打印进程 id, `Start thrift req` 表示开始调用 `get_image` 接口了。

由于此时网卡速度很慢，我们 client 会一直阻塞着。此时我们可以给 client 发送一个 `SIGUSR1` 信号:

```
kill -SIGUSR1 241683
```

client 在收到信号后会处理信号，并出现一个异常

```
# 表示 SIGUSR1 信号已经处理完了
Receive sig 10

# 打印出来的异常的类型, 及其值
(TTransportException('unexpected exception',), error(4, 'Interrupted system call'))

# 抛出异常的栈信息
Traceback (most recent call last):
      File "client.py", line 50, in <module>
          main()
        File "client.py", line 43, in main
          res = client.get_image()
        File "gen-py/tutorial/Calculator.py", line 35, in get_image
          return self.recv_get_image()
        File "gen-py/tutorial/Calculator.py", line 53, in recv_get_image
          result.read(iprot)
        File "gen-py/tutorial/Calculator.py", line 178, in read
          self.success = iprot.readBinary()
        File "/home/xuyundong/Github/Python/thrift-eintr/venv2/lib/python2.7/site-packages/thrift/protocol/TBinaryProtocol.py", line 234, in readBinary
          s = self.trans.readAll(size)
        File "/home/xuyundong/Github/Python/thrift-eintr/venv2/lib/python2.7/site-packages/thrift/transport/TTransport.py", line 62, in readAll
          chunk = self.read(sz - have)
        File "/home/xuyundong/Github/Python/thrift-eintr/venv2/lib/python2.7/site-packages/thrift/transport/TTransport.py", line 164, in read
          self.__rbuf = BufferIO(self.__trans.read(max(sz, self.__rbuf_size)))
        File "/home/xuyundong/Github/Python/thrift-eintr/venv2/lib/python2.7/site-packages/thrift/transport/TSocket.py", line 164, in read
          raise TTransportException(message="unexpected exception", inner=e)
      TTransportException: unexpected exception
```

从栈信息我们可以知道，抛出异常的位置是 `thrift/transport/TSocket.py:164`，它的代码如下

```py
    def read(self, sz):
        try:
            buff = self.handle.recv(sz)
        except socket.error as e:
            if (e.args[0] == errno.ECONNRESET and
                    (sys.platform == 'darwin' or sys.platform.startswith('freebsd'))):
                # freebsd and Mach don't follow POSIX semantic of recv
                # and fail with ECONNRESET if peer performed shutdown.
                # See corresponding comment and code in TSocket::read()
                # in lib/cpp/src/transport/TSocket.cpp.
                self.close()
                # Trigger the check to raise the END_OF_FILE exception below.
                buff = ''
            elif e.args[0] == errno.ETIMEDOUT:
                raise TTransportException(type=TTransportException.TIMED_OUT, message="read timeout", inner=e)
            else:
                # 在这里抛出了异常
                raise TTransportException(message="unexpected exception", inner=e)
        if len(buff) == 0:
            raise TTransportException(type=TTransportException.END_OF_FILE,
                                      message='TSocket read 0 bytes')
        return buff
```

这段代码逻辑就是，client 已经发送完了请求，正在等待 server 返回响应的时候，收到了一个 `socket.error`, 它的值是

```
error(4, 'Interrupted system call')

# 在 python 标准库的 errno.py 文件中也可以看到 4 表示是 EINTR 错误
EINTR = 4
```

### python3 中无法复现

如果我们使用 Python3 启动 client, 再往该进程发送 SIGUSR1 信号，它就不会抛出异常。

```
ø> ./venv3/bin/python client.py
Start client @ 241720
Start thrift req
# 收到了两次信号
Receive sig 10
Receive sig 10
get 2745109 bytes in 16.005424737930298
```

EINTR 是什么错误，为什么 Python2 中抛异常，Python3不会抛异常呢，且听我慢慢讲解。

## EINTR 是什么

### man 文档中的解释

### 为什么要有 EINTR 错误

## Python 中如何处理这个错误的

## thrift 如何对待这个错误的

## 吐槽 Python

