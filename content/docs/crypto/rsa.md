---
title: "Rsa 使用公钥进行解密"
date: 2025-01-08T14:25:11+08:00
lastmod: 2025-01-08T14:25:11+08:00
tags: [rsa, crypto]
author: "bwangel"
---

## RSA 加密算法相关的数学概念

### 互质

如果两个正整数，除了 1 以外没有其他的公因数，则他们互质。比如，14 和 15 互质。注意，两个数构成互质关系，他们不一定需要是质数，比如 7 和 9。

### 欧拉函数

欧拉函数是一个数学函数，用来表示一个整数 n 的“相对质数”的个数，也就是说，它计算的是小于 n 且与 n 互质的数的数量。举个例子：

对于 n = 9，1, 2, 4, 5, 7, 8 都与 9 互质，所以 \\( \phi(9) = 6 \\)

对于 n = 10，1, 3, 7, 9 与 10 互质，所以 \\( \phi(10) = 4 \\)

__质因数分解:__ 先将 n 分解为质因数的乘积形式。

欧拉函数的通用公式是

如果 n 是一个正整数，并且其质因数分解为：

$$
n = p^{e1}_1 * p^{e2}_2 * p^{e3}_3 \cdots * p^{ek}_k
$$

则

$$
\phi(n) = n * (1 - \frac{1}{p_1}) * (1 - \frac{1}{p_2}) * (1 - \frac{1}{p_3}) \cdots * (1 - \frac{1}{p_k})
$$

例如:

$$
12 = 2^2 * 3^1
$$

$$
\phi(12) = 12 * (1 - \frac{1}{2}) * (1 - \frac{1}{3}) = 4
$$

如果 p 是一个质数，代入到上述公式中

$$
p = p
$$

$$
\phi(p) = p * (1 - \frac{1}{p}) = p-1
$$

### 欧拉定理和费马小定理

欧拉定理的定义是

如果两个正整数 a 和 n 互质，则如下等式成立。

$$
a^{\phi(n)} \equiv 1 \pmod n
$$

这个公式表达的是\\( a^{\phi(n)} \\) 减去 1，可以整除 n。

如果 n 是质数，且 a 不是 p 的倍数，则可以写成

$$
a^{p-1} \equiv 1 \pmod n
$$

这就是 费马小定理，它是欧拉定理的特例。

### 模反元素

如果两个正整数 a 和 n 互质，那么一定可以找到一个正整数 b，使得 ab - 1 被 n 整除。

$$
ab \equiv 1 \pmod n
$$

这时候，b 就叫做 a 的模反元素

例如，3 和 11 互质，3 的模反元素是 4，因为 \\(3 \times 4 - 1\\) 可以整除 11。

我们可以用欧拉定理来证明，模反元素一定存在。

$$
a^{\phi(n)} = a * a^{\phi(n) - 1} \equiv 1 \pmod n
$$

\\( a^{\phi(n) - 1} \\) 就是 a 相对 n 的模反元素

## RSA 秘钥的生成

1. 随机选择两个大质数 p 和 q，并计算他们的乘积 n。在日常应用中，出于安全考虑，一般要求 n 换算成二进制要大于 2048 位。
我们选择两个简单的质数 5 和 11，n = 55

2. 计算 n 的欧拉函数 \\( \phi(n) \\)，根据公式，

$$
\phi(n) = n * (1 - \frac{1}{p}) * (1 - \frac{1}{q}) = (p-1) * (q-1) \\
\phi(55) = 40
$$

3. 选择一个数 e 使得 e 与 \\( \phi(n) \\) 互质。\\( 1 < e < \phi(n) \\)，我们选择 13
4. 计算 e 相对 \\( \phi(n) \\) 的模反元素 d。根据上面的知识，因为 e 和 \\( \phi(n) \\) 互质，我们可以用如下公式计算 d

$$
d = e^{\phi(\phi(n)) - 1} \\
$$

计算过程如下

$$
\phi(55) = 40
$$

$$
\phi(40) = 40 * (1 - \frac{1}{5}) * (1 - \frac{1}{2}) = 16
$$

$$
d = e^{15} = 13^{15} = 51185893014090757
$$

计算出来 d 是 51185893014090757，为了方便计算，我们对 40 取余，得到一个最小的 d 是 37。

$$
51185893014090757 \pmod {40} = 37
$$

最终我们选择的模反元素 d 是 37，

$$
13 * 37 \equiv 1 \pmod {40}
$$

经过以上的步骤，我们就生成了 rsa 的秘钥对

- 公钥 \\( (n, e) \\) = (55, 13)
- 私钥 \\( (n, d) \\) = (55, 37)

## RSA 的可靠性

在上一章节中，我们得到了 RSA 的公钥和私钥的内容，在公钥 \\( (n,e) \\) 已知的情况下，如果保证私钥 \\( (n, d) \\) 的安全性。

* 已知 d 是 e 基于 \\( \phi(n) \\) 的模反元素，我们想要得到 d 需要知道 \\( \phi(n) \\)

* 因为 n 是两个质数 p 和 q 的乘积，根据欧拉公式我们可以得到 \\( \phi(n) \\) 的计算方法

$$
\phi(n) = (p-1) \times (q-1)
$$

因为将一个大整数分解成两个质数非常困难，因此我们很难计算出 \\( \phi(n) \\)，因此保证了私钥 \\( (n, d) \\) 的安全性。

综上所述可以得到，__RSA 的可靠性基于大整数的质数分解非常困难。__

## RSA 执行加解密

加密的公式是

$$
m^e \equiv c \pmod n
$$

解密的公式是

$$
c^d \equiv m \pmod n
$$

- m 表示明文数字
- c 表示加密后得到的密文数字

我们将明文 3 代入加密公式，

$$
3^13 \equiv c \pmod 55
$$

得到 c = 38

我们将密文 38 代入解密公式

$$
38^{37} \equiv m \pmod {55}
$$

解出明文 m=3


## 解析 OpenSSH RSA 密钥

[rsademo](https://github.com/cj1128/rsademo.git) 程序实现了 OpenSSH 公私钥的解析功能。

我们在当前目录下生成一个秘钥对

```bash
ssh-keygen -t rsa -f keys
```

可以使用 rsademo 解析公私钥的内容

```bash
# 解析公钥，公钥中仅仅包含 n, e
ø> ./rsademo -parse keys.pub
OpenSSH Public Key
  keyType: ssh-rsa
  e: 0x010001
  n: 3072 0xCD1E1FB5DE2A0EFB36E184AD5B7B6FB811BECC938020FF5507E9DB4614F6AEC21F4CF53AF563BD6FA4715686672B74BA6E93F1096DDA4F71F9C4E1BD4355CE64923A19626F8511ECD717A7935EF26DF325B099D0B2BDDE6369570E9EFE851312C5F1D9054DFEA3EAE6106CDDB0159F7EA4607DE4B9CF163933C808C5CDDEE4A5023E459149D97F4009CBC64403CAA0F25CAF2A52CFB5C04619C289057473C6FECA71D94A348F0D53245E5EFBCDF6100F48A954D5F9C704E8784AC55E675186B4FAFD2AD4EF63A214C67CBC13E5070C1BC48F36A01ABDC5A1E989127363AFE2C803B35372B1AD9A26C0FE70ED64A0D0C0BE3FC0345006FCC6486C1C170F1E0FF29B0CC19A8BB0962B7E751536CB2851DAA9F07219512F71B8948B767B2389F07C1074810A35763B2BEF2F5CF42EDA2AEF68882E45C1CC5E90141FB6B73655106924D0C9F514844A051BB88072937A074C6F5610BF6257B158C0A63FD780596F582428C88AE19BB28048F8C69A840787A5AA20845502B481425881C20F9B5A653F
```

```bash
# 解析私钥，私钥中除了 n 和 d，还有 n 分解的两个质数 p，q，公钥使用的 e
ø> ./rsademo -parse keys
OpenSSH Private Key
  keyType: ssh-rsa
  n: 3072 0xCD1E1FB5DE2A0EFB36E184AD5B7B6FB811BECC938020FF5507E9DB4614F6AEC21F4CF53AF563BD6FA4715686672B74BA6E93F1096DDA4F71F9C4E1BD4355CE64923A19626F8511ECD717A7935EF26DF325B099D0B2BDDE6369570E9EFE851312C5F1D9054DFEA3EAE6106CDDB0159F7EA4607DE4B9CF163933C808C5CDDEE4A5023E459149D97F4009CBC64403CAA0F25CAF2A52CFB5C04619C289057473C6FECA71D94A348F0D53245E5EFBCDF6100F48A954D5F9C704E8784AC55E675186B4FAFD2AD4EF63A214C67CBC13E5070C1BC48F36A01ABDC5A1E989127363AFE2C803B35372B1AD9A26C0FE70ED64A0D0C0BE3FC0345006FCC6486C1C170F1E0FF29B0CC19A8BB0962B7E751536CB2851DAA9F07219512F71B8948B767B2389F07C1074810A35763B2BEF2F5CF42EDA2AEF68882E45C1CC5E90141FB6B73655106924D0C9F514844A051BB88072937A074C6F5610BF6257B158C0A63FD780596F582428C88AE19BB28048F8C69A840787A5AA20845502B481425881C20F9B5A653F
  e: 0x010001
  d: 0x4F24AB699A02326B9DDE603A1F8D3E2B10B5C4EBB8C9829B85852735204B9A5C8E853C2DF696F876064630F385055071CACECC772DEAC9329A03EC7201742F41C0E627FB423A5F133A5F072AA6BCF5CD96A2508725207B997200C44476C253FCAF61C4B1F64925683242EE2E8F8D984FDE0ED92492C923B30896CB43BF4E9C7C4AA44A6567D042F82B8F73BDB494CF8B1456060793DB7607D652A859F177E6B552D9A0D4AFF8EE544139247F161636561F5C2EBEAD34AC612260FF4C90A2F54D57972DE74B3DFC00EF9CEC72B91037A02D05ACA3CB353AEFFBAB8046997CD8859A98F32E2590FC2B5630981E8FA7DA7C8CFA8C15C549585335142853EDD1587D583CA711BFCB43F1B1D7852549F793F3F1EC39F9F0D8E4284BA0AA3D0CFDE04A00D5165A9AD82FC0DCB06A0EC01195EE09299BB76EE9397D58F1FFD635C8FFDC903593738CC70263A9A53AEE57B66B1437F8182F654DCC421929C5710B165CF16966FDFC035B0EB25B85455238D1D7B80CAE470D85898DF54C2280322FA347F1
  p: 0xFF5B9A8C23FB76C20819F696DBC3998B3CA756F7228DB2851833B245BC611DCB0E23B231FA5EB42787D09AC95A2409F674DA257F4444AFE07F51C3E24669D1EF3A6466255A49C0FDF41FBD59DA8753E0303AF7243C19DFC060ACA6ED7EA899A4A2313F1FF4A4C7B5DAEA351E57F80B4BE3595D4499D595C3BC0997BBFB5C23D72F948F30718DFB3161952388462BB74ED764A427750ADDF2CDF213747FFC8D9C628E7135EA8332A19A292C971FCA9A3311A24CDA5F4BEC3D05D51DD1DC26FAD9
  q: 0xCDA22D18CE6E5CCC86C99681EE5087D4A5B1019717A991939FCD9603FC89081FDD63D630662A2EA1BF32C61538D709E8207C5778D37071851442161E06369F8F16A72111E3E4D5FF92090F87D4053A7BA2C78303A1CBDE7919CAB9FE1627EB5BCC42D72C4C79061D2326384B7F25B09081C12828E2B5F000778EC746E6395D9381946E6DB0F52988CCF82DDFD66CBF24ABBB5C9532DE66681C3B9D0169B785084216FDC6E2790CA83460B27CD0926842A2A23D64B448BA49B5483340BC2DE1D7
```

## RSA 密钥对的存储格式

### ASN.1

__ASN.1(Abstract Syntax Notation dotone)__，抽象语法标记1。
是定义抽象数据类型形式的标准，描绘了与任何表示数据的编码技术无关的通用数据结构。

它提供了一些基本和组合的数据类型，例如 INTEGER, String, BOOLEAN，SET, SEQUENCE 等，我们可以通过 ASN.1 定义数据结构，并通过它将值转换成二进制。

### PEM

__PEM(Privacy-Enhanced Mail)__ 是存储数据的一种文件格式。它使用 base64 编码将二进制数据表示为 ASCII 字符串，并通过特定的标头和标尾标识文件类型

### PKCS#1, PKCS#8, PKIX, ASN.1, PEM 等格式的关系

将 RSA 密钥转换成 pem 文件需要经过三步

1. 定义一个 ANS.1 格式的数据结构，规定保存的密钥中的数据（例如模数n，公钥指数e，私钥指数d，质数 p,q等），根据数据结构的不同，密钥的格式分为 PKCS#1, PKCS#8, PKIX
2. 将第一步定义的数据结构的值，通过 ASN.1 转换成二进制，此时将二进制存储到文件中，它就是 .der 格式的密钥
3. 将二进制编码成 base64，并在文件开头结尾加上密钥的格式，将文本数据写入到文件中，它就是 .pem 格式的密钥

### PKCS#1

PKCS#1 是用于 RSA 密钥的标准，它定义了 RSA 公钥和私钥的格式以及与 RSA 算法相关的加密操作。

* 主要内容：
  - RSA 公钥：RSA 公钥主要包括两个字段：
    - 模数（n） 和 公钥指数（e）
  - RSA 私钥：私钥包括多个字段，最重要的是：
    - 模数（n）
    - 私钥指数（d）
    - 与公钥指数相关的私钥参数（例如 p, q, dp, dq 等，表示素数因子以及加速加密过程的参数）

* 典型格式：
  - PKCS#1 格式的私钥：通常以 PEM 格式表示，首尾有 `-----BEGIN RSA PRIVATE KEY-----` 和 `-----END RSA PRIVATE KEY-----` 标识
  - PKCS#1 格式的公钥：通常以 PEM 格式表示，首尾有 `-----BEGIN RSA PUBLIC KEY-----` 和 `-----END RSA PUBLIC KEY----` 标识

- 以下程序展示了生成 PKCS#1 格式的 RSA 密钥对

```go
package main

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"fmt"
)

func printPKCS1RSAKey() {
	// 生成 RSA 密钥对
	privKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		fmt.Println("Error generating RSA key:", err)
		return
	}

	// 提取公钥
	pubKey := &privKey.PublicKey

	// 将公钥编码为 PKCS#1 格式
	// 将公钥数据写入文件
	pubKeyBytes := x509.MarshalPKCS1PublicKey(pubKey)
	data := pem.EncodeToMemory(&pem.Block{
		Type:  "RSA PUBLIC KEY",
		Bytes: pubKeyBytes,
	})
	fmt.Println("Public key pem")
	fmt.Println(string(data))

	privateKeyBytes := x509.MarshalPKCS1PrivateKey(privKey)
	data = pem.EncodeToMemory(&pem.Block{
		Type:  "RSA PRIVATE KEY",
		Bytes: privateKeyBytes,
	})
	fmt.Println("Private key pem")
	fmt.Println(string(data))
}
```

### PKCS#8

PKCS#8 是一个更通用的标准，定义了 __私钥__ 信息的格式，不仅仅支持 RSA 私钥，还支持多种不同类型的私钥（如 DSA、ECDSA 等）。它的设计目标是提供一种更通用的格式，可以用来存储和交换各种类型的私钥信息。

PKCS#8 只用了定义私钥数据结构，不能定义公钥

* PKCS#8 格式中的主要内容：
  - 版本：标识 PKCS#8 格式的版本号。
  - 算法标识符：指示所用加密算法（例如 RSA、DSA 或 ECDSA 等）。 
  - 私钥：私钥数据本身，通常是一个二进制编码（DER 格式）表示的私钥。

* PKCS#8 的优势：
  - 与 PKCS#1 不同，PKCS#8 支持多种加密算法，而不仅仅是 RSA。
  - PKCS#8 格式支持通过密码加密私钥数据，从而提高私钥的安全性。

* 典型格式：
  PKCS#8 的 pem 文件以 `-----BEGIN PRIVATE KEY-----` 和 `-----END PRIVATE KEY-----` 来标识

以下代码展示了使用 Golang 生成 pem 格式的 rsa 密钥

```go
package main

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"fmt"
)

func printPKCS8PrivateKey() {
	// 生成 RSA 密钥对
	privKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		fmt.Println("Error generating RSA key:", err)
		return
	}

	// 将 rsa 私钥序列化成 pkcs#8 格式
	privateKeyBytes, err := x509.MarshalPKCS8PrivateKey(privKey)
	if err != nil {
		fmt.Println("Error marshal RSA key:", err)
		return
	}
	data := pem.EncodeToMemory(&pem.Block{
		Type:  "PRIVATE KEY",
		Bytes: privateKeyBytes,
	})
	fmt.Println("Private key pem")
	fmt.Println(string(data))
}
```

### PKIX

__PKIX（Public Key Infrastructure X.509）__ 是一个标准格式，用于描述和存储公钥及其相关信息，通常用于公钥基础设施（PKI）中。
PKIX格式的典型应用场景包括数字证书（如X.509证书）和公钥交换。

__RSA公钥被存储为X.509证书的一部分，或者可以单独以PKIX格式存储。__

PKIX格式实际上通常是指X.509证书格式，它包含的字段如下

1. 版本（Version）
描述证书的版本。常见的版本为v3。
2. 序列号（Serial Number）
证书的唯一标识符。通常由证书颁发机构（CA）分配。
3. 签名算法（Signature Algorithm）
证书使用的签名算法，通常包括哈希算法（如SHA256）和签名算法（如RSA）。
4. 颁发者（Issuer）
证书的颁发机构的名称。通常是CA的名称。
5. 有效期（Validity）
证书的有效期，包括开始日期和结束日期。
6. 主体（Subject）
证书的主体信息，通常是持有证书的实体的信息（如组织、个人等）。
7. 主体公钥信息（Subject Public Key Info）

* 这是证书中最关键的部分，包含公钥的详细信息。包括：
  * 算法（Algorithm）: 表明公钥使用的算法类型（如RSA、EC等）。
  * 公钥（Public Key）: 具体的公钥数据，RSA公钥则是一个大整数。
  * 扩展（Extensions）: 可选字段，提供额外的信息，如密钥用法、证书策略等。
 
8. 签名（Signature）
证书颁发机构对证书内容的签名，用于验证证书的真实性和完整性。

PKIX(X.509) 格式既可以用来表示一个证书，也可以只包含 __主体公钥信息（Subject Public Key Info）__ 用来表示一个公钥，它不仅支持 RSA，还支持 ecdsa, ed25519, ecdh 等多种公钥。

当我们将RSA公钥编码为PKIX格式时，公钥信息部分的结构如下：

```
Subject Public Key Info:
  Algorithm:
    Algorithm: rsaEncryption (1.2.840.113549.1.1.1)
  Public Key:
    [Modulus] [Exponent]
```

* Algorithm:
  * 包含公钥使用的算法类型（对于RSA公钥，算法是rsaEncryption）。
* Public Key: 包括两个部分：
  * Modulus (n)：RSA公钥的模数。
  * Exponent (e)：RSA公钥的指数。

以下代码展示了生成一个 pkix 格式的 RSA 公钥

```go
package main

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/pem"
	"fmt"
)

func printPKIXPublicKey() {
	// 生成 RSA 密钥对
	privKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		fmt.Println("Error generating RSA key:", err)
		return
	}

	// 将 rsa 公钥序列号成 pkix 格式
	pubKey := privKey.PublicKey
	pubKeyBytes, err := x509.MarshalPKIXPublicKey(&pubKey)
	if err != nil {
		fmt.Println("Error marshal RSA key:", err)
		return
	}
	data := pem.EncodeToMemory(&pem.Block{
		Type:  "PUBLIC KEY",
		Bytes: pubKeyBytes,
	})
	fmt.Println("Public key pem")
	fmt.Println(string(data))
}
```

## RSA 明文的填充方式 (padding)

RSA 算法本身只处理固定长度的数字，而实际的消息通常比 RSA 模数小，因此需要填充操作来确保消息可以适应 RSA 的加密大小。

常见的 RSA 填充模式有以下几种：

1. PKCS#1 v1.5 填充（PKCS#1 v1.5 Padding）

* 描述：这是一种广泛使用的填充模式，定义在 PKCS#1 v1.5 标准中。填充的目的是通过在消息中插入一些填充字节，以确保加密后的数据长度与 RSA 密钥的长度相匹配。
* 工作原理：在消息的开头插入一个字节 0x00 和一个字节 0x02， 然后添加一些非零随机字节（保证不为全零）, 最后，添加消息的实际内容，并以 0x00 结束。
* 缺点：这种填充方式容易受到某些攻击（如填充Oracle攻击），在某些场景下不太安全。

2. OAEP 填充（Optimal Asymmetric Encryption Padding）

* 描述：OAEP 是一种更安全的填充方案，定义在 PKCS#1 v2.x 标准中。它利用哈希函数和随机数生成器来增强填充的安全性。
* 工作原理：OAEP 填充通过使用一个随机的种子值和哈希函数对消息进行加密填充，增加了对抗填充攻击的能力。
它包括两部分：使用哈希函数对消息进行混合。将随机数与消息结合进行加密，以确保填充过程的不可预测性。
* 优点：相比 PKCS#1 v1.5 填充，OAEP 提供更强的安全性，尤其在抗攻击（例如选择密文攻击）方面表现更好。

3. PKCS#1 v2.1 填充（PKCS#1 v2.1 Padding）

* 描述：PKCS#1 v2.1 是 PKCS#1 v2.x 标准的更新版本，支持 OAEP 填充，并对一些加密操作进行了改进。
* 工作原理：PKCS#1 v2.1 填充和 OAEP 类似，使用哈希函数和随机数填充数据。它和 PKCS#1 v2.x 标准一致，但提供了一些额外的改进。

## Golang 使用标准库如何进行 RSA 加解密

```go
package main

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"log"
)

// 生成 RSA 公私钥对
func generateRSAKeyPair() (*rsa.PrivateKey, *rsa.PublicKey, error) {
	privKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		return nil, nil, fmt.Errorf("生成 RSA 密钥对失败: %v", err)
	}
	return privKey, &privKey.PublicKey, nil
}

// 将公钥转为 PEM 格式的字符串
func publicKeyToPEM(pubKey *rsa.PublicKey) string {
	pubASN1, err := x509.MarshalPKIXPublicKey(pubKey)
	if err != nil {
		log.Fatalf("无法将公钥转换为 ASN.1 格式: %v", err)
	}

	pubPEM := pem.EncodeToMemory(&pem.Block{
		Type:  "PUBLIC KEY",
		Bytes: pubASN1,
	})
	return string(pubPEM)
}

// 将私钥转为 PEM 格式的字符串
func privateKeyToPEM(privKey *rsa.PrivateKey) string {
	privASN1 := x509.MarshalPKCS1PrivateKey(privKey)
	privPEM := pem.EncodeToMemory(&pem.Block{
		Type:  "PRIVATE KEY",
		Bytes: privASN1,
	})
	return string(privPEM)
}

// 使用公钥进行加密
func encryptWithPublicKey(plainText []byte, pubKey *rsa.PublicKey) ([]byte, error) {
	cipherText, err := rsa.EncryptOAEP(sha256.New(), rand.Reader, pubKey, plainText, nil)
	if err != nil {
		return nil, fmt.Errorf("加密失败: %v", err)
	}
	return cipherText, nil
}

// 使用私钥进行解密
func decryptWithPrivateKey(cipherText []byte, privKey *rsa.PrivateKey) ([]byte, error) {
	plainText, err := rsa.DecryptOAEP(sha256.New(), rand.Reader, privKey, cipherText, nil)
	if err != nil {
		return nil, fmt.Errorf("解密失败: %v", err)
	}
	return plainText, nil
}

func main() {
	// 生成 RSA 公私钥对
	privKey, pubKey, err := generateRSAKeyPair()
	if err != nil {
		log.Fatalf("生成 RSA 密钥对失败: %v", err)
	}

	// 将公私钥转换为 PEM 格式的字符串
	pubKeyPEM := publicKeyToPEM(pubKey)
	privKeyPEM := privateKeyToPEM(privKey)

	// 打印 PEM 格式的公钥和私钥
	fmt.Println("公钥 PEM 格式:")
	fmt.Println(pubKeyPEM)

	fmt.Println("私钥 PEM 格式:")
	fmt.Println(privKeyPEM)

	// 要加密的明文
	plainText := []byte("Hello, this is a secret message using RSA encryption!")

	// 使用公钥进行加密
	encryptedText, err := encryptWithPublicKey(plainText, pubKey)
	if err != nil {
		log.Fatalf("加密失败: %v", err)
	}
	fmt.Printf("加密后的数据: %x\n", encryptedText)

	// 使用私钥进行解密
	decryptedText, err := decryptWithPrivateKey(encryptedText, privKey)
	if err != nil {
		log.Fatalf("解密失败: %v", err)
	}
	fmt.Printf("解密后的数据: %s\n", decryptedText)
}
```

## Java 如何进行公钥解密

下面的程序展示了 Java 如何使用公钥进行解密，可以看到，声明 cipher 的模式是解密模式，就可以使用公钥进行解密了。

```java
    public static String decryptByPublicKey(String data, String pubKey) throws Exception {
        byte[] decodePubKey = DECODER.decode(pubKey);
        X509EncodedKeySpec x509KeySpec = new X509EncodedKeySpec(decodePubKey);
        java.security.Security.addProvider(new org.bouncycastle.jce.provider.BouncyCastleProvider());
        RSAPublicKey publicKey = (RSAPublicKey)KeyFactory.getInstance(ALGORITHM).generatePublic(x509KeySpec);
        System.out.println(publicKey.getModulus());
        System.out.println(publicKey.getPublicExponent());

        return decryptByPublicKey(data, publicKey);

    }

    public static String decryptByPublicKey(String data, RSAPublicKey publicKey) throws Exception {
        Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding");
        cipher.init(Cipher.DECRYPT_MODE, publicKey);

        byte[] b1 = DECODER.decode(data);

        /* 执行解密操作 */

        byte[] b = cipher.doFinal(b1);
        return new String(b);

    }
```

## 公钥解密的数学原理是什么以及Go 三方库的实现

Go 标准库中没有实现公钥解密，我在 GitHub 上找到了一个实现此功能的三方库 [wenzhenxi/gorsa](https://github.com/wenzhenxi/gorsa)

查看它的代码，它在使用公钥进行解密的代码如下：

```go
func pubKeyDecrypt(pub *rsa.PublicKey, data []byte) ([]byte, error) {
	k := (pub.N.BitLen() + 7) / 8
	if k != len(data) {
		return nil, ErrDataLen
	}
    // 这一句执行的是 m = m^e mod n，这实际上是执行了加密公式
	m := new(big.Int).SetBytes(data)
	if m.Cmp(pub.N) > 0 {
		return nil, ErrDataToLarge
	}
	m.Exp(m, big.NewInt(int64(pub.E)), pub.N)
	d := leftPad(m.Bytes(), k)
	if d[0] != 0 {
		return nil, ErrDataBroken
	}
	if d[1] != 0 && d[1] != 1 {
		return nil, ErrKeyPairDismatch
	}
	var i = 2
	for ; i < len(d); i++ {
		if d[i] == 0 {
			break
		}
	}

```

可以看到，公钥解密其实执行的还是加密操作，执行公式  \\( m^e \pmod n \\) 计算出明文，将收到的密文进行一次加密，得到了明文


## 参考资料

* https://www.ruanyifeng.com/blog/2013/06/rsa_algorithm_part_one.html
* https://www.ruanyifeng.com/blog/2013/07/rsa_algorithm_part_two.html
* https://en.wikipedia.org/wiki/RSA_(cryptosystem)
* https://juejin.cn/post/6997271445776629768
* https://cjting.me/2020/03/13/rsa/
* https://javacfox.github.io/2019/07/18/ASN-1%E5%85%A5%E9%97%A8%EF%BC%88%E8%B6%85%E8%AF%A6%E7%BB%86%EF%BC%89/
