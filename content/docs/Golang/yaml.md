---
title: "YAML"
date: 2023-08-15T11:48:16+08:00
lastmod: 2023-08-15T11:48:16+08:00
author: "bwangel"
---

## gopkg.in/yaml.v3 在 Unmarshal 时设置默认值

使用 [gopkg.in/yaml.v3](https://github.com/go-yaml/yaml/tree/v3.0.1) 解析 yaml 文件时，我们可以实现结构体的 UnmarshalYAML 接口

在 `UnmarshalYAML` 方法中，既可以在结构体创建的时候指定默认值，也可以在结构体 Decode 完成之后，设置更复杂的默认值

- test.yaml

```yaml
application: snowave
runtime: golang
services:
  - interface: linaewen.fdoulist
    handler: services/api/thrift.go
    type: thrift
use_services:
  - app: fm
    type: grpc
    version: 6b15b80
  - app: music
    version: e89b497be9ef0fb932d5e543ed866f920780750f
  - app: pony
    version: c5b2e21
```

- main.go

```go
package main

import (
	"fmt"
	"github.com/pkg/errors"
	"gopkg.in/yaml.v3"
	"log"
	"os"
	"strings"
)

type UseService struct {
	App     string `yaml:"app,omitempty"`
	Type    string `yaml:"type,omitempty"`
	Version string `yaml:"version"`
}

// UnmarshalYAML
//
//	此程序演示了，在 Decode 之前设置 Type 字段的默认值为 thrift
func (u *UseService) UnmarshalYAML(value *yaml.Node) error {
	type tmp UseService
	ru := tmp{
		Type: "thrift",
	}
	err := value.Decode(&ru)
	if err != nil {
		return errors.Wrap(err, "UseService: failed to unmarshal")
	}
	*u = UseService(ru)
	return nil
}

type Service struct {
	Name      string `yaml:"name"`
	Interface string `yaml:"interface"`
	Type      string `yaml:"type"`
	Handler   string `yaml:"handler"`
}

// UnmarshalYAML
//
//	此函数演示了更复杂的情况, Name 字段的默认值是根据 Interface 的值来设置的
//
// Name 是 Interface 中 `.` 分割的最后一段
// 如果 Interface 中没有 `.` , 则 Name == Interface
func (s *Service) UnmarshalYAML(value *yaml.Node) error {
	type tmp Service
	rs := tmp{}
	err := value.Decode(&rs)
	if err != nil {
		return errors.Wrap(err, "Service: failed to unmarshal")
	}

	if rs.Name == "" {
		// 注意这里，无论 rs.Interface 的值是什么， tokens 的长度一定 >= 1,
		// 所以 tokens[len(tokens)-1] 不会 Panic
		tokens := strings.Split(rs.Interface, ".")
		rs.Name = tokens[len(tokens)-1]
	}

	*s = Service(rs)
	return nil
}

type AppConfig struct {
	Application string        `yaml:"application"`
	Runtime     string        `yaml:"runtime"`
	Services    []*Service    `yaml:"services"`
	UseServices []*UseService `yaml:"use_services"`
}

func main() {
	config := &AppConfig{}
	content, _ := os.ReadFile("test.yaml")
	err := yaml.Unmarshal(content, config)
	if err != nil {
		log.Fatalln(err)
	}

	// 输出
	//fdoulist linaewen.fdoulist
	for _, svc := range config.Services {
		fmt.Println(svc.Name, svc.Interface)
	}

	// 输出
	//fm grpc
	//music thrift
	//pony thrift
	for _, svc := range config.UseServices {
		fmt.Println(svc.App, svc.Type)
	}
}
```

### 参考链接

- https://github.com/go-yaml/yaml/issues/165#issuecomment-727092641


