---
title: "Python2 使用 Thrift 为什么会出现 EINTR 错误"
date: 2023-10-27T09:22:30+08:00
lastmod: 2023-10-27T09:22:30+08:00
tags: [python, thrift, blog]
author: "bwangel"
---

## EINTR 错误是什么

在 [man 7 signal](https://man7.org/linux/man-pages/man7/signal.7.html) 中写到，

>If a signal handler is invoked while a system call or library
> function call is blocked, then either:
>
>  •  the call is automatically restarted after the signal handler
>    returns; or
>
>  •  the call fails with the error EINTR.

如果一些阻塞的系统调用或库函数调用被信号中断了，会发生以下任一情况

1. 在信号处理函数执行完以后，系统调用或库函数调用继续执行
2. 系统调用或库函数调用失败，返回错误码 EINTR

具体会发生哪种情况，取决于具体的系统调用接口和是否通过 [sigaction](https://man7.org/linux/man-pages/man7/signal.7.html) 设置了 `SA_RESTART` 标记。

例如 

- `read`, `readv`, `wait`, 没有设置超时的 `recv` 和 `send` 等调用会受到 `SA_RESTART` 标记的控制，继续执行或返回 EINTR 错误
- 设置了超时的 `send` 和 `recv`, `epoll_wait`, `poll` 等接口不会受到 `SA_RESTART`，都是直接返回 EINTR 错误码

## 为什么要有 EINTR 错误

从上面的 man 文档中可知，`EINTR` 其实并不是一个错误，只是程序被信号中断了而已。Unix/Linux 系统要设计成中断系统调用，并返回一个错误码呢?

在 [PEP 475](https://peps.python.org/pep-0475/) 中说

> Therefore, when a signal is received by a process during the execution of a system call,
>  the system call can fail with the EINTR error to give the program an opportunity to handle the signal without the restriction on signal-safe functions.

系统调用返回 `EINTR` 的设计，让信号处理函数有机会能在不考虑信号安全的情况下编写。

光看这句话看不太明白，后来我又搜索了一下，看到了 StackOverflow 上的一篇回答。 

- [What is the rationale behind EINTR?](https://unix.stackexchange.com/a/253358/191858)

这里面说，信号处理函数因为要考虑可重入性，在函数中，很多系统调用都是不能使用的。这就决定了信号处理函数中不能编写复杂的逻辑。

大部分程序的逻辑是，在 signal handler 里面设置一个 flag, 然后主线程再检查 flag, 做出具体操作。

如果程序在系统调用上卡住了，那么 signal handler 设置了 flag 之后，主线程无法及时执行后续操作，相当于信号没有及时处理。

所以 unix 的设计者才定义了 EINTR 这个错误，让系统调用及时结束，将执行权交换给用户程序，及时处理信号。

## 复现一个 EINTR 错误

了解了 EINTR 错误的原理后，我们再来看一下 Python2 调用 Thrift 的时候，经常会出现的一个和 EINTR 有关的错误。

我们可以用以下代码复现一下这个错误

### 代码准备

1. 从 [github.com/bwangelme/thrift-eintr](https://github.com/bwangelme/thrift-eintr) 克隆代码
2. 在代码目录中，使用 virtualenv 分别创建 venv2 和 venv3 两个 Python 虚拟环境

```
~/.pyenv/versions/2.7.18/bin/virtualenv venv2
~/.pyenv/versions/3.11.0/bin/virtualenv venv3
```

服务端的代码比较简单，他就是提供了 `get_image` 接口，读取图片文件并返回文件内容，这里就不过多赘述了。

客户端的代码中主要做了两件事情。

1. 处理 SIGUSR1 信号
2. 调用 get_image 接口获取文件

```py
def signal_handler(signum, frame):
    print("Receive sig %s" % (signum,))


def main():
    # 注册处理信号的 handler
    signal.signal(signal.SIGUSR1, signal_handler)

    # 打印进程 ID
    print("Start client @ %s" % (os.getpid()))
    transport = TSocket.TSocket('localhost', 9090)
    transport = TTransport.TBufferedTransport(transport)
    protocol = TBinaryProtocol.TBinaryProtocol(transport)
    client = Calculator.Client(protocol)
    transport.open()

    # 调用 thrift 接口
    print("Start thrift req")
    start = time.time()
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
# ø> sudo tc qdisc del dev lo root
```

2. 首先使用 `./venv2/bin/python server.py` 启动 server,

```shell
ø> python server.py
Starting the server...
```

 然后再启动 client

```
ø> ./venv2/bin/python client.py

Start client @ 241683
Start thrift req
```

client 启动以后，会打印进程 id `241683`, `Start thrift req` 表示开始调用 `get_image` 接口了。

由于网卡速度很慢，我们 client 会阻塞十几秒。此时我们可以给 client 发送一个 `SIGUSR1` 信号:

```
kill -SIGUSR1 241683
```

client 在收到信号后会处理信号，并抛出一个异常

```
# 这句表示 SIGUSR1 信号已经处理完了
Receive sig 10

# 打印出来的异常的类型及其值
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

## 为什么 Python2 和 Python3 的表现不同

### Python 的原因

Python 在 [PEP 475](https://peps.python.org/pep-0475/) 中实现了，在系统调用遇到 EINTR 的时候自动重试。

而且它只在 signal handler 没有抛出异常的时候重试，这样确保信号能够中断程序的执行，不会阻塞在系统调用中。

以下是中断后能够自动重试的函数列表:

- open() 和 io.open();
- [faulthandler](https://docs.python.org/3/library/faulthandler.html#module-faulthandler) 模块相关的函数;
- os 模块的函数: fchdir(), fchmod(), fchown(), fdatasync(), fstat(), fstatvfs(), fsync(), ftruncate(), mkfifo(), mknod(), open(), posix_fadvise(), posix_fallocate(), pread(), pwrite(), read(), readv(), sendfile(), wait3(), wait4(), wait(), waitid(), waitpid(), write(), writev();
- 特例: os.close() 和 os.dup2() 会忽略 EINTR 错误，并且不会重试
- select 函数: devpoll.poll(), epoll.poll(), kqueue.control(), poll.poll(), select();
- socket 类相关的函数: accept(), connect() (except for non-blocking sockets), recv(), recvfrom(), recvmsg(), send(), sendall(), sendmsg(), sendto();
- signal.sigtimedwait() 和 signal.sigwaitinfo();
- time.sleep().

但是 PEP 475 仅在 Python 3.5 及之后的版本中生效，在 Python 2.7 的版本中，是没有这个处理逻辑的。

### Thrift 的原因

在 Thrift 的 [Issue-617](https://issues.apache.org/jira/browse/THRIFT-617) 中，有人提到了在网络 IO 接口中忽略 EINTR 错误的建议。维护者的回答是，这个问题已经在 Python 3.5 中修了，没有提到 Python 2.7 该怎么办。

PEP 475 只管 Python3, thrift 没有针对 Python2 做特殊处理，这就导致了上述错误只会在 Python 2 出现，Python 3 不会出现。

## thrift 在 Python2 环境中忽略 EINTR

目前 Python 和 Thrift 官方都无意去处理这个问题，我们可以修改一下 thrift 代码，手动处理 EINTR 错误。我的处理办法很简单，遇到 EINTR 错误，直接重试即可。

```diff
--- a/lib/py/src/transport/TSocket.py
+++ b/lib/py/src/transport/TSocket.py
@@ -149,22 +149,26 @@ class TSocket(TSocketBase):
         raise TTransportException(type=TTransportException.NOT_OPEN, message=msg)

     def read(self, sz):
-        try:
-            buff = self.handle.recv(sz)
-        except socket.error as e:
-            if (e.args[0] == errno.ECONNRESET and
-                    (sys.platform == 'darwin' or sys.platform.startswith('freebsd'))):
-                # freebsd and Mach don't follow POSIX semantic of recv
-                # and fail with ECONNRESET if peer performed shutdown.
-                # See corresponding comment and code in TSocket::read()
-                # in lib/cpp/src/transport/TSocket.cpp.
-                self.close()
-                # Trigger the check to raise the END_OF_FILE exception below.
-                buff = ''
-            elif e.args[0] == errno.ETIMEDOUT:
-                raise TTransportException(type=TTransportException.TIMED_OUT, message="read timeout", inner=e)
-            else:
-                raise TTransportException(message="unexpected exception", inner=e)
+        while True:
+            try:
+                buff = self.handle.recv(sz)
+            except socket.error as e:
+                if e.args[0] == errno.EINTR:
+                    pass
+                elif (e.args[0] == errno.ECONNRESET and
+                        (sys.platform == 'darwin' or sys.platform.startswith('freebsd'))):
+                    # freebsd and Mach don't follow POSIX semantic of recv
+                    # and fail with ECONNRESET if peer performed shutdown.
+                    # See corresponding comment and code in TSocket::read()
+                    # in lib/cpp/src/transport/TSocket.cpp.
+                    self.close()
+                    # Trigger the check to raise the END_OF_FILE exception below.
+                    buff = ''
+                elif e.args[0] == errno.ETIMEDOUT:
+                    raise TTransportException(type=TTransportException.TIMED_OUT, message="read timeout", inner=e)
+                else:
+                    raise TTransportException(message="unexpected exception", inner=e)
+
         if len(buff) == 0:
             raise TTransportException(type=TTransportException.END_OF_FILE,
                                       message='TSocket read 0 bytes')
@@ -185,7 +189,8 @@ class TSocket(TSocketBase):
                 sent += plus
                 buff = buff[plus:]
             except socket.error as e:
-                raise TTransportException(message="unexpected exception", inner=e)
+                if e.args[0] != errno.EINTR:
+                    raise TTransportException(message="unexpected exception", inner=e)

     def flush(self):
         pass
```

## 吐槽

- PEP 475 是 2014 年的提案，那一年 Python2 还没有停止维护，然后官方在这个 PEP 中直接忽略了 Python2 ，让 Python2 的开发者自己去捕获 EINTR 错误并重试。Python 社区真的不是一个好社区，如果你想开发一个能够维护10年以上的程序，不建议用 Python
- Thrift 维护者也没有考虑 Python2 的情况，认为 Python3 已经修了，就万事大吉了，让 Python2 的 client 和 server 多了很多不必要的 TTransportException

