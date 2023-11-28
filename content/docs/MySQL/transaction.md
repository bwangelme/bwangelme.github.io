---
title: "MySQL 事务"
date: 2023-11-28T22:10:53+08:00
lastmod: 2023-11-28T22:10:53+08:00
tags: [Tips, MySQL]
author: "bwangel"
---

## 查询持续时间超过 60s 的事务

```sql
select * from information_schema.innodb_trx where TIME_TO_SEC(timediff(now(),trx_started))>60;

-- innodb_trx 存储了数据库的所有事务
-- trx_started 表示事务的开始时间
```

