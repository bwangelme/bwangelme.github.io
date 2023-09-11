---
title: "Consumer"
date: 2023-09-11T16:30:55+08:00
lastmod: 2023-09-11T16:30:55+08:00
tags: [kafka, tips]
author: "bwangel"
---

## Commit

- 当 Consumer 将 `enable.auto.commit` 设置为 true 的时候，kafka consumer 会自动提交 offset。
它在 `auto.commit.interval.ms` 选项的控制下，间隔N秒后，自动将当前 consumer 拉取到的消息 offset 提交到 kafka 中。

- 当 `enable.auto.commit=false` 时，kafka 客户端不会自动提交 offset，需要开发者通过 `consumer.commitSync` 或 `consumer.commitAsync` 提交 offset。

- 不建议每收到一条消息就提交一次 offset，`consumer.commitSync` 是有性能损耗的，如果 `consumer.commitSync` 调用的频率非常高，consumer 消费消息的速度将会变得很慢。

- `consumer.commitAsync` 是异步提交的，它相对 `consumer.commitSync` 会有一定的性能提升。`consumer.commitAsync` 还有一个回调函数参数，让开发者设定在提交失败时做什么。
    - 一般在 broker 正常时，提交失败的情况很少发生。开发者不需要做提交失败后重试的逻辑。

### 参考链接

- https://github.com/edenhill/librdkafka/blob/4992b3db321befa04ece3027f3c79f3557684db9/CONFIGURATION.md
- https://docs.confluent.io/platform/current/clients/consumer.html#id1

## offset

kafka 的消息以 group 为单位给 Consumer 发送。Consumer Group 在 topic 中的 offset 存储在 broker 的 `__consumer_offsets` topic 中。

新加入的 consumer group 默认从最新位置读取 message。可以通过修改 Consumer 的`auto.offset.reset=smallest` 选项，让 consumer 从头开始读取 message.

当 broker 获取 consumer group 的 offset 出错时(offset 不存在或者 offset 超出已有的 message 的范围)，也会根据 `auto.offset.reset` 的配置来决定从什么位置开始读取 message。

- auto.offset.reset 说明
    - `smallest`, `earliest` 自动将 offset 设置成最小的 offset
    - `largest`, `latest` 自动将 offset 设置成最大的 offset
    - `error` 抛出一个错误 (ERR__AUTO_OFFSET_RESET) consumer 可以通过 `message->err` 获取到该错误

### 参考链接

- https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md

