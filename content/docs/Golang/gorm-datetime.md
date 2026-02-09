---
title: "MySQL + GORM 如何设置创建时间和更新时间"
date: 2026-02-09T10:21:07+08:00
lastmod: 2026-02-09T10:21:07+08:00
tags: [Golang, GORM, MySQL, Blog]
author: "bwangel"
---

## 目标

正确配置 MySQL 表中的 create_time 和 update_time，自动记录行的创建时间和更新时间，精度为**微秒**。

## 如何正确配置 create_time 和 update_time (How)

### 一、MySQL DDL

建表时将 create_time、update_time 设为**微秒**精度：

```sql
CREATE TABLE `item` (
  `id` int NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `union_id` int NOT NULL COMMENT 'union id',
  `keyword` varchar(255) NOT NULL COMMENT 'keyword',
  `create_time` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '创建时间',
  `update_time` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_union_id` (`union_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```

### 二、GORM 初始化连接时声明时间精度

初始化 GORM 连接时配置 `NowFunc`：

```go
dsn := "user:password@tcp(127.0.0.1:3306)/test?charset=utf8mb4&parseTime=True&loc=Local"
db, err := gorm.Open(mysql.New(mysql.Config{DSN: dsn}), &gorm.Config{
    NowFunc: func() time.Time {
        return time.Now().Local()
    },
})
```

### 三、GORM 结构体中的 tag

create_time 和 update_time 对应字段需添加 `autoCreateTime`、`autoUpdateTime` tag：

```go
type Item struct {
	ID         uint      `gorm:"primaryKey"`
	UnionID    int       `gorm:"column:union_id;not null;uniqueIndex:uniq_union_id"`
	Keyword    string    `gorm:"column:keyword;type:varchar(255);not null"`
	CreateTime time.Time `gorm:"column:create_time;autoCreateTime"`
	UpdateTime time.Time `gorm:"column:update_time;autoUpdateTime"`
}
```

## 为什么要进行上述配置 (Why)

### 为什么要设置 GORM 的 autoCreateTime 和 autoUpdateTime Tag

GORM 默认通过 **CreatedAt** 和 **UpdatedAt** 字段来追踪记录的创建时间和更新时间。只要定义了这些字段，GORM 在**创建**或**更新**记录时会自动设为当前时间。

如果你希望使用不同名称的字段，可以通过为字段添加 autoCreateTime、autoUpdateTime 标签来进行配置。

如果你更倾向于保存 UNIX 时间戳（秒 / 毫秒 / 纳秒），只需要将字段的数据类型从 time.Time 改为 int 即可。

```go
type User struct {
	CreatedAt    time.Time // 创建时如果这个值是0，设置为当前时间
	UpdatedAt    int       // 在更新时设置为当前时间，或者在创建时如果该值为 0，则设置为当前时间。
	UpdatedNano  int64     `gorm:"autoUpdateTime:nano"`  // 在更新时设置为 Unix 纳秒时间戳
	UpdatedMilli int64     `gorm:"autoUpdateTime:milli"` // 在更新时设置为 Unix 毫秒时间戳
	Created      int64     `gorm:"autoCreateTime"`       // 在创建时设置为 Unix 秒级时间戳
}
```

如果我们使用 `db.Save` 接口保存数据，如果没有**手动更新 UpdateTime**，或者**使用 `Omit` 忽略 update_time**，那么 GORM 不会更新 update_time，它将时间设置为原来存储的值。

- 使用 Omit 忽略 `create_time` 和 `update_time`

```go
db.Omit("create_time", "update_time").Save(&item)
```

- 手动更新 `update_time`

```go
db.Model(&Item{}).
  Where("id = ?", item.ID).
  Update("updated_time", gorm.Expr("CURRENT_TIMESTAMP(6)"))
```

### 为什么 MySQL DDL 中要设置 current_timestamp

这是使用 GORM 实现的一个 CreateOrUpdate 函数，record 中 union_id 有一个唯一约束，当 union_id 对应的行已经存在时，更新 keyword 列。

```go
func (d *svc) CreateOrUpdate(ctx context.Context, record *Item, keyword string) error {
    err := pkg.DBRw.WithContext(ctx).Clauses(clause.OnConflict{
        Columns: []clause.Column{{Name: "union_id"}},
        DoUpdates: clause.Assignments(map[string]any{
            "keyword": keyword,
        }),
    }).Create(record).Error

   	if err != nil {
		return fmt.Errorf("DB CreateOrUpdate %w", err)
	}
}
```

在上述语句中，GORM 不会更新 update_time 列；若 MySQL DDL 中未声明 `ON UPDATE CURRENT_TIMESTAMP(6)`，updated_time 就不会被更新。

### 为什么 GORM 初始化连接时，要设置 NowFunc

GORM 配置中，`NowFunc` 用于获取当前时间；在填充 create_time 和 update_time 时都会使用该函数返回的时间。

在 `"gorm.io/driver/mysql"` 库中，默认会设置 NowFunc 返回的时间精度为毫秒

```go
// NowFunc return now func
func (dialector Dialector) NowFunc(n int) func() time.Time {
	return func() time.Time {
		round := time.Second / time.Duration(math.Pow10(n))
		return time.Now().Round(round)
	}
}

// 修改 GORM 配置中的 NowFunc，dialector.DefaultDatetimePrecision 默认是3
config.NowFunc = dialector.NowFunc(*dialector.DefaultDatetimePrecision)
```

设置 NowFunc 后，GORM 使用的当前时间精度不会被截断。

## 小结

- **MySQL**：使用 `datetime(6)` 和 `DEFAULT CURRENT_TIMESTAMP(6)` / `ON UPDATE CURRENT_TIMESTAMP(6)` 实现微秒级时间。
- **GORM**：通过 `autoCreateTime` / `autoUpdateTime` tag 绑定自定义列名，并通过 `NowFunc` 控制时间精度与时区。
- **CreateOrUpdate / Upsert**：若使用 `Clauses(OnConflict(...))` 且未在 DoUpdates 中包含时间列，需依赖 MySQL 的 `ON UPDATE CURRENT_TIMESTAMP(6)` 自动更新 updated_time。
