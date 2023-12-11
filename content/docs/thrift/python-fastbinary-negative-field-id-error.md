---
title: "Thrift Python Client 解析负数 field id 失败"
date: 2023-11-23T17:27:03+08:00
lastmod: 2023-11-23T17:27:03+08:00
tags: [Python, Thrift]
author: "bwangel"
---

## thrift python 的 fastbinary 是什么

thrift 在进行通信的时候，Python client 需要将 idl 中定义的方法参数，结构体序列化成字节流。这是在 thrift 的 Protocol 层实现的。

序列化的方式有多种，JSON, Binary, Compact。

Binary 和 Compact 协议的实现有两种，分别是纯 Python 实现和 C++ 实现。C++ 实现的这份我们叫做 fastbinary。

使用 `TBinaryProtocol` 初始化 protocol ，调用的是纯 Python 实现。`TBinaryProtocolAccelerated` 调用的是 C++ 实现。

## 问题描述

Python Client 调用 Python Server, 当 idl 中定义的方法是非 strict 的话(即没有在参数或结构体中声明序号)。使用 fastbinary 调用 server 会出错，我们可以用以下的代码来复现问题。

1. 我们创建一个 thrift 服务，它的 idl 文件定义如下

```
service Service {
   string hello(1: string name)
   i64 add(i64 a, i64 b)
}
```

hello 方法是符合 strict 定义的，add 方法没有写序号，thrift 默认会使用负数序号。(a: -1, b: -2)

2. client.py 和 server.py 的代码如下

+ client.py

```py
from gen_py.tutorial import Service

from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol


def main():
    # Make socket
    transport = TSocket.TSocket('localhost', 9090)

    # Buffering is critical. Raw sockets are very slow
    transport = TTransport.TBufferedTransport(transport)

    # TBinaryProtocolAccelerated 表示 binary 协议使用 fastbinary 进行序列化
    protocol = TBinaryProtocol.TBinaryProtocolAccelerated(transport)
    # protocol = TBinaryProtocol.TBinaryProtocol(transport)

    # Create a client to use the protocol encoder
    client = Service.Client(protocol)

    # Connect!
    transport.open()

    print(client.hello("bwangel"))
    print(client.add(40, 2))


if __name__ == '__main__':
    main()
```

+ server.py

```
import sys
sys.path.append('gen-py')

from gen_py.tutorial import Service
from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol
from thrift.server import TServer


class ServiceHandler:
    def __init__(self):
        self.log = {}

    def hello(self, name):
        return "hello, %s" % name

    def add(self, a, b):
        return a + b


if __name__ == '__main__':
    handler = ServiceHandler()
    processor = Service.Processor(handler)
    transport = TSocket.TServerSocket(host='127.0.0.1', port=9090)
    tfactory = TTransport.TBufferedTransportFactory()
    pfactory = TBinaryProtocol.TBinaryProtocolFactory()

    server = TServer.TSimpleServer(processor, transport, tfactory, pfactory)

    print('Starting the server...')
    server.serve()
    print('done.')
```

上述完整代码见 [Github](https://github.com/bwangelme/thrift-fastbinary-error)

当我们运行 `./venv/bin/python client.py` 之后，服务端就会出现错误

```
ERROR:root:Unexpected exception in handler
Traceback (most recent call last):
  File "/home/xuyundong/Github/Python/thrift-fastbinary-error/gen_py/tutorial/Service.py", line 171, in process_add
    result.success = self._handler.add(args.a, args.b)
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/xuyundong/Github/Python/thrift-fastbinary-error/server.py", line 19, in add
    return a + b
           ~~^~~
TypeError: unsupported operand type(s) for +: 'NoneType' and 'NoneType'
```

这是因为服务端的 `add` 方法接收到的两个参数 `a` 和 `b` 都是 None, 在它们之上执行 `+` 就会抛出 `TypeError`

## 抓包查看细节

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2023-12-11-192219.png)

这是 add 方法的请求包，可以看到出了包头和方法之外，没有任何参数。应该写参数的位置写了一个空结构体(`T_STOP`)。 

## 问题原因

为什么客户端的参数没有写到协议里面呢，我们可以看一下生成代码的细节

在 `gen_py/tutorial/Service.py:191` 中定义了 hello 方法参数的序列化类 `hello_args`

```
class hello_args(object):
    """
    Attributes:
     - name

    """


    def __init__(self, name=None,):
        self.name = name

    def read(self, iprot):
        if iprot._fast_decode is not None and isinstance(iprot.trans, TTransport.CReadableTransport) and self.thrift_spec is not None:
            iprot._fast_decode(self, iprot, [self.__class__, self.thrift_spec])
        ....
    def write(self, oprot):
        if oprot._fast_encode is not None and self.thrift_spec is not None:
            oprot.trans.write(oprot._fast_encode(self, [self.__class__, self.thrift_spec]))
            return
        ....
```

可以看到，它在写入和读取的时候，都会判断底层协议对象(iprot, oprot)有没有 `_fast_decode/_fast_encode` 方法，如果有的话，调用这些方法。`_fast_decode/_fast_encode` 就是用 C++ 实现的 Binary 协议的序列化方法。

_fast_encode 方法传入2个参数，

1. hello_args 对象
2. [hello_args 类, hello_args 对象的 `thrift_spec` 属性] 组成的元组

问题就出在 thrift_spec 上，我们观察 `hello_args` 和 `add_args` 的 thrift_spec，发现 `add_args` 的 thrift_spec 是空的。

```py
hello_args.thrift_spec = (
    None,  # 0
    (1, TType.STRING, 'name', 'UTF8', None, ),  # 1
)
```

```py
add_args.thrift_spec = ()
```

为什么 `add_args.thrift_spec` 会是空的呢，我们再来看 thrift 编译器生成 Python 代码的逻辑，在 thrift 的代码 [`compiler/cpp/src/thrift/generate/t_py_generator.cc`](https://github.com/apache/thrift/blob/0.18.1/compiler/cpp/src/thrift/generate/t_py_generator.cc#L739-L775) 中的 `generate_py_thrift_spec` 中，定义了生成 thrift_spec 的逻辑。

```c
/**
 * Generate the thrift_spec for a struct
 * For example,
 *   all_structs.append(Recursive)
 *   Recursive.thrift_spec = (
 *       None,  # 0
 *       (1, TType.LIST, 'Children', (TType.STRUCT, (Recursive, None), False), None, ),  # 1
 *   )
 */
void t_py_generator::generate_py_thrift_spec(ostream& out,
                                             t_struct* tstruct,
                                             bool /*is_exception*/) {
  const vector<t_field*>& sorted_members = tstruct->get_sorted_members();
  vector<t_field*>::const_iterator m_iter;

  // Add struct definition to list so thrift_spec can be fixed for recursive structures.
  indent(out) << "all_structs.append(" << tstruct->get_name() << ")" << endl;

  // __注意__: 这里的判断语句， sorted_members[0]->get_key() >= 0, 意味着结构体成员的 field_num >= 0, 才会执行 if 块里面的内容
  if (sorted_members.empty() || (sorted_members[0]->get_key() >= 0)) {
    indent(out) << tstruct->get_name() << ".thrift_spec = (" << endl;
    indent_up();

    int sorted_keys_pos = 0;
    for (m_iter = sorted_members.begin(); m_iter != sorted_members.end(); ++m_iter) {

      for (; sorted_keys_pos != (*m_iter)->get_key(); sorted_keys_pos++) {
        indent(out) << "None,  # " << sorted_keys_pos << endl;
      }

      indent(out) << "(" << (*m_iter)->get_key() << ", " << type_to_enum((*m_iter)->get_type())
                  << ", "
                  << "'" << (*m_iter)->get_name() << "'"
                  << ", " << type_to_spec_args((*m_iter)->get_type()) << ", "
                  << render_field_default_value(*m_iter) << ", "
                  << "),"
                  << "  # " << sorted_keys_pos << endl;

      sorted_keys_pos++;
    }

    indent_down();
    indent(out) << ")" << endl;
  } else {
    indent(out) << tstruct->get_name() << ".thrift_spec = ()" << endl;
  }
}
```

可以看到，thrift 编译器生成代码的时候有判断逻辑，如果结构体第一个成员的 field_number < 0, 那么结构体对应的 `thrift_spec` 就是个空元组。

这样就能解释的通了，因为 `add` 方法没有写序列号，thrift 默认使用负数序列号，那它们生成代码的时候，`thrift_spec` 属性就是空，fastbinary 序列化成二进制协议的时候，也就不会生成对应的内容了。

## 代码考古

为什么 thrift 要这样区别对待非 strict 的方法呢，我翻了一下历史 PR, 找到了 fastbinary 最初提交的 COMMIT

- [382fc3043cba33fea1a919e4e6bfeac0cb9c22aa](https://github.com/apache/thrift/commit/382fc3043cba33fea1a919e4e6bfeac0cb9c22aa)

![](https://passage-1253400711.cos.ap-beijing.myqcloud.com/2023-12-11-194538.png)

作者一开始就没有考虑 field_id 是负数的情况，他当时还留了一个 TODO, 后来随着时间的流逝，这个 TODO 也被删掉了。
