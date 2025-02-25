---
title: 'MySQL索引'
date: 2016-04-10 10:56:54
tags: [MySQL, blog]
---

__摘要__:

MySQL索引
=========

## 1. 索引简介

索引在MySQL中也叫作键，是存储引擎用于快速找到记录的一种数据结构

索引优化应该是对查询性能优化最有效的手段了

相当于字典中的音序表，如果没有音序表，则需要一页一页去查

## 2. 索引分类

|说明|普通索引|唯一索引|全文索引|单列索引|多列索引|空间索引|
|--|--|--|--|--|--|--|
|存储引擎|所有存储引擎支持(同样的索引，不同存储类型，实现不同)|只有Memory支持|5.5及之前前仅MyISAM支持| | | |
|特点|允许字段重复|不允许字段重复|针对`varchar`类型支持| |select语句条件有第一个字段时才会使用多列索引| | |

## 3. 测试

### 利用存储过程插入数据

```sql
mysql> delimiter $$ --设置分隔符为$$
-- 定义一个存储过程
mysql> create procedure autoinsert1()
    -> BEGIN
    -> declare i int default 1;
    -> while(i<20000)do
    -> insert into school.t2 values(i, 'xff');
    -> set i=i+1
    -> end while;
    -> END$$
mysql> delimiter ; --还原分隔符为;
mysql> call autoinsert1(); --调用存储过程
```

创建存储过程要选择对应数据库，否则可能会报错

### 创建索引

#### 1. 在创建表的时候创建索引

```sql
create table table_name(
字段名1 数据类型 [完整性约束条件],
字段名2 数据类型 [完整性约束条件],
[UNIQUE|FULLTEXT|SPATIAL] INDEX|KEY
[索引名] (字段名[(长度)] [ASC|DESC]) --ASC|DESC表示对索引进行排序
--字段名后的长度针对varchar类型
);
```

#### 2. 创建多列索引

select在条件中使用第一个字段时才会使用索引

```sql
--创建表
--这里第一个字段为dept_name

mysql> show create table dept4\G
*************************** 1. row ***************************
       Table: dept4
Create Table: CREATE TABLE `dept4` (
  `dept_id` int(11) NOT NULL,
  `dept_name` varchar(30) DEFAULT NULL,
  `comment` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`dept_id`),
  KEY `index_dept_name` (`dept_name`,`comment`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1
```

```sql
-- 使用了索引
-- explain 解释这句如何执行，但是并不实际执行
mysql> explain select * from dept4 where dept_name='sale'\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: dept4
         type: ref
possible_keys: index_dept_name  --这句表示使用了的索引的名字
          key: index_dept_name
      key_len: 33
          ref: const
         rows: 1                -- 一共查询了多少行
        Extra: Using where; Using index
1 row in set (0.01 sec)

mysql> explain select * from dept4 where comment='sale001'\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: dept4
         type: index
possible_keys: NULL           -- 这句表示没有使用索引
          key: index_dept_name
      key_len: 86
          ref: NULL
         rows: 4              -- 一共查询了多少行
        Extra: Using where; Using index
1 row in set (0.00 sec)
```

#### 3. 在已存在的表上创建索引

```sql
create [UNIQUE|FULLTEXT|SPATIAL] INDEX 索引名
    ON 表名(字段名[(长度)] [ASC|DESC]);

alter table 表名 ADD [UNIQUE|FULLTEXT|SPATIAL] INDEX 索引名(字段名[(长度)] [ASC|DESC]);
```

复制表

```sql
-- 复制了表的内容和结构，但是没有复制表的key(约束)
mysql> create table t3 select * from t2;

-- 下面两条，复制了表的结构，但是没有内容，也没有复制表的key(约束)
mysql> create table t4 select * from t2 where 1=2;
mysql> create table t5 like t2;
```
## 4. 管理索引

查看索引
`show create table 表名\G`

测试示例
`explain select * from t2 where id = 1;`
查看查询优化器做了哪些操作

`DROP INDEX 索引名 ON 表名`
删除索引

## explain 语句解释

表 T 的结构及索引

```
Create Table: CREATE TABLE `T` (
  `ID` int NOT NULL,
  `k` int NOT NULL DEFAULT '0',
  `s` varchar(16) NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`),
  KEY `k` (`k`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
```

回表表示用二级索引查到主键 ID 后，再用主键ID去主键索引中查找行数据，这个过程称为回表。

explain 输出的 rows 表示 mysql server 从 InnoDB 引擎中拿到的行数。

```
mysql> explain select s from T where k between 3 and 5;
+----+-------------+-------+------------+-------+---------------+------+---------+------+------+----------+-----------------------+
| id | select_type | table | partitions | type  | possible_keys | key  | key_len | ref  | rows | filtered | Extra                 |
+----+-------------+-------+------------+-------+---------------+------+---------+------+------+----------+-----------------------+
|  1 | SIMPLE      | T     | NULL       | range | k             | k    | 4       | NULL |    2 |   100.00 | Using index condition |
+----+-------------+-------+------------+-------+---------------+------+---------+------+------+----------+-----------------------+
1 row in set, 1 warning (0.00 sec)
```

## explain 语句的说明

在 MySQL 中使用 EXPLAIN 语句可以显示 MySQL 如何执行 SQL 查询，从而帮助优化查询性能。EXPLAIN 语句输出的信息包含多个字段，每个字段都有特定的含义。下面是这些字段的详细解释：

- id: 查询的标识符，表示查询中每个子查询或表的执行顺序。id 值越大，优先级越高，先被执行。

- select_type: 查询的类型，表示每个 SELECT 子句的类型。常见的类型有：

    - SIMPLE：简单查询，不包含子查询或 UNION。
    - PRIMARY：主查询，最外层的查询。
    - SUBQUERY：子查询，出现在 SELECT 或 WHERE 子句中。
    - DERIVED：衍生表，出现在 FROM 子句中的子查询。
    - UNION：UNION 中的第二个或后续的 SELECT 语句。
    - UNION RESULT：UNION 的结果。

- table: 表示正在访问的表名。

- partitions: 显示匹配的分区信息（如果表使用了分区）。

- type: 连接类型，表示 MySQL 如何找到所需行。常见类型包括：

    - ALL：全表扫描。
    - index：全索引扫描。
    - range：索引范围扫描。
    - ref：使用非唯一索引扫描，返回匹配某个单独值的所有行。
    - eq_ref：唯一索引扫描，对于每个索引键值，表中有一行与之匹配。
    - const：表有最多一个匹配行，快速访问。
    - system：表只有一行（系统表）。
    - possible_keys: 显示查询中可能使用的索引。

- key: 实际使用的索引。如果没有使用索引，该值为 NULL。

- key_len: 使用的索引长度（字节数）。这个值是计算得出的，表示 MySQL 实际使用了索引的多少部分。

- ref: 显示使用索引时，哪一列或常量与 key 一起用于查询行。

- rows: MySQL 估计为找到所需数据，需要读取的行数。该值是一个估计值，不是准确值。

- filtered: 显示查询条件过滤掉的行的百分比（百分比形式），这个值用于估计返回结果的数量。

- Extra: 额外信息，说明查询的额外细节。常见的值包括：

    - Using where：在存储引擎之后使用 WHERE 子句过滤行。
    - Using index：表示查询只使用索引访问表数据，而不访问表的实际行。
    - Using temporary：使用临时表保存中间结果。
    - Using filesort：使用外部文件排序，而不是从索引中读取顺序行。
    - Using join buffer：使用连接缓冲区来存储临时结果。
    - Backward index scan: 使用索引的倒序来进行扫描，通常和 SQL 中有 order by xx desc limit 有关
    - Using index condition: 查询使用了索引条件下推 (Index Condition Pushdown, ICP)，并通过索引过滤行，需要扫描表中的某些数据行来满足查询条件

通过理解和分析 EXPLAIN 输出的这些字段，可以找出查询中的性能瓶颈，并进行针对性的优化。

## 索引条件下推

索引条件下推（Index Condition Pushdown，ICP） 是 MySQL 在执行查询时的一项优化技术，它将查询中的某些条件“下推”到索引扫描阶段，而不是等到数据被读取到内存后再应用过滤条件。这可以显著提高查询性能，特别是在处理大数据量时。

__工作原理__

通常，MySQL 在使用索引扫描时，会首先读取索引中的值，然后通过访问表数据行来获取符合条件的记录。而索引条件下推的优化则是将查询中的某些 WHERE 子句中的过滤条件直接下推到索引扫描的过程中，减少了不必要的数据行访问，提升了性能。

具体而言，MySQL 会尝试将 WHERE 子句中的某些条件直接应用于索引扫描时，而不是等到数据行完全读取后才应用这些条件。这样可以提前过滤掉不符合条件的记录，从而减少扫描的数据量。

举例
假设有如下的表结构和索引：

```sql
CREATE TABLE users (
  id INT,
  name VARCHAR(255),
  age INT,
  gender ENUM('male', 'female'),
  INDEX idx_id_age(id, age)
);
```

执行如下查询：

```sql
SELECT * FROM users WHERE id > 100 AND age < 30;
```

1. 没有索引条件下推：
如果没有使用索引条件下推，MySQL 可能会按以下步骤执行：

* 首先使用 idx_id_age 索引查找 id > 100 的记录；
* 然后读取这些记录的 age 列，并在内存中应用 age < 30 这个条件；
* 最后返回符合 id > 100 AND age < 30 条件的记录。

2. 使用索引条件下推：
如果启用了索引条件下推，MySQL 会进行优化，按以下步骤执行：

* 使用 idx_id_age 索引来查找 id > 100 的记录；
* 在扫描过程中，MySQL 会直接使用索引中的 age 值（索引已经包含了 id 和 age 列）来判断 age < 30 是否满足；
* 如果某个记录不满足 age < 30 条件，MySQL 会在索引扫描阶段直接跳过该记录，而不需要再访问对应的数据行。

__优势__

- 提高性能：索引条件下推可以减少对不符合条件的记录的访问，尤其是在大数据量的表中。通过在索引扫描过程中就过滤掉不符合条件的记录，可以显著减少扫描的数据量，降低 I/O 操作。
- 避免不必要的回表操作：当查询使用覆盖索引时（即索引中包含查询所需的所有列），索引条件下推可以避免回表，从而进一步提高查询效率。

__何时使用__

- 复杂的 WHERE 条件：如果查询的 WHERE 子句包含多个条件，并且索引已经覆盖了这些条件中的一部分或全部，启用索引条件下推能够提升查询效率。
- 大表查询：对于大表，使用索引条件下推能有效减少扫描的数据量，提升查询速度。

__总结__

索引条件下推（ICP）是一种优化技术，通过将查询中的过滤条件尽早应用到索引扫描阶段，避免了在数据行读取后再进行过滤，进而提高了查询性能。它适用于涉及多个条件的查询，尤其是条件中有索引列时。
