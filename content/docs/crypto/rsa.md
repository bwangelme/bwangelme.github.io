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

对于 n = 9，1, 2, 4, 5, 7, 8 都与 9 互质，所以 $$ \phi(9) = 6 $$

对于 n = 10，1, 3, 7, 9 与 10 互质，所以 $$ \phi(10) = 4 $$

欧拉函数的通用公式是

如果 n 是一个正整数，并且其质因数分解为：

```math
n = p^{e1}_1 * p^{e2}_2 * p^{e3}_3 \cdots * p^{ek}_k
```

则

```math
\phi(n) = n * (1 - \frac{1}{p_1}) * (1 - \frac{1}{p_2}) * (1 - \frac{1}{p_3}) \cdots * (1 - \frac{1}{p_k})
```

__质因数分解:__ 先将 n 分解为质因数的乘积形式。

例如:

```math
12 = 2^2 * 3^1
```

```math
\phi(12) = 12 * (1 - \frac{1}{2}) * (1 - \frac{1}{3}) = 4
```

如果 p 是一个质数，代入到上述公式中

```math
p = p
```

```math
\phi(p) = p * (1 - \frac{1}{p}) = p-1
```

### 欧拉定理和费马小定理

欧拉定理的定义是

如果两个正整数 a 和 n 互质，则如下等式成立。

```math
a^{\phi(n)} \equiv 1 \pmod n
```

```math

a^{\phi(n)} 减去 1，可以整除 n。

```

如果 n 是质数，且 a 不是 p 的倍数，则可以写成

```math
a^{p-1} \equiv 1 \pmod n
```

这就是 费马小定理，它是欧拉定理的特例。

### 模反元素

如果两个正整数 a 和 n 互质，那么一定可以找到一个正整数 b，使得 ab - 1 被 n 整除。

```math
ab \equiv 1 \pmod n
```

这时候，b 就叫做 a 的模反元素

比如，3 和 11 互质，3 的模反元素是 4，因为 \\( 3*4 - 1 \\) 可以整除 11。

我们可以用欧拉定理来证明，模反元素一定存在。

```math
a^{\phi(n)} = a * a^{\phi(n) - 1} \equiv 1 \pmod n
```

\\( a^{\phi(n) - 1} \\) 就是 a 相对 n 的模反元素

## RSA 秘钥的生成

1. 随机选择两个大质数 p 和 q，并计算他们的乘积 n。在日常应用中，出于安全考虑，一般要求 n 换算成二进制要大于 2048 位。
我们选择两个简单的质数 5 和 11，n = 55

2. 计算 n 的欧拉函数 \\( \phi(n) \\)，根据公式，

```math
\phi(n) = n * (1 - \frac{1}{p}) * (1 - \frac{1}{q}) = (p-1) * (q-1) \\
\phi(55) = 40
```

3. 选择一个数 e 使得 e 与 \\( \phi(n) \\) 互质。\\( 1 < e < \phi(n) \\)，我们选择 13
4. 计算 e 相对 \\( \phi(n) \\) 的模反元素 d。根据上面的知识，因为 e 和 \\( \phi(n) \\) 互质，我们可以用如下公式计算 d

```math
d = e^{\phi(\phi(n)) - 1} \\
```

```math
\phi(55) = 40 \\
\phi(40) = 40 * (1 - \frac{1}{5}) * (1 - \frac{1}{2}) = 16 \\

d = e^{15} = 13^{15} = 51185893014090757 \\
51185893014090757 \pmod {40} = 37
```

最终我们选择的模反元素 d 是 37，

```math
13 * 37 \equiv 1 \pmod {40}
```

经过以上的步骤，我们就生成了 rsa 的秘钥对

- 公钥 (n, e) = (55, 13)
- 私钥 (n, d) = (55, 37)

## RSA 执行加解密

加密的公式是

```math
m^e \equiv c \pmod n
```

解密的公式是

```math
c^d \equiv m \pmod n
```

- m 表示明文数字
- c 表示加密后得到的密文数字

我们将明文 3 代入加密公式，

```math
3^13 \equiv c \pmod 55
```

得到 c = 38

我们将密文 38 代入解密公式

```math
38^{37} \equiv m \pmod {55}
```

解出明文 m=3


## RSA 秘钥对的格式

在当前目录下生成秘钥对

```
ssh-keygen -t rsa -f keys
```

使用解析程序解析公私钥的内容

```
# 解析公钥
ø> ./rsademo -parse keys.pub
OpenSSH Public Key
  keyType: ssh-rsa
  e: 0x010001
  n: 3072 0xCD1E1FB5DE2A0EFB36E184AD5B7B6FB811BECC938020FF5507E9DB4614F6AEC21F4CF53AF563BD6FA4715686672B74BA6E93F1096DDA4F71F9C4E1BD4355CE64923A19626F8511ECD717A7935EF26DF325B099D0B2BDDE6369570E9EFE851312C5F1D9054DFEA3EAE6106CDDB0159F7EA4607DE4B9CF163933C808C5CDDEE4A5023E459149D97F4009CBC64403CAA0F25CAF2A52CFB5C04619C289057473C6FECA71D94A348F0D53245E5EFBCDF6100F48A954D5F9C704E8784AC55E675186B4FAFD2AD4EF63A214C67CBC13E5070C1BC48F36A01ABDC5A1E989127363AFE2C803B35372B1AD9A26C0FE70ED64A0D0C0BE3FC0345006FCC6486C1C170F1E0FF29B0CC19A8BB0962B7E751536CB2851DAA9F07219512F71B8948B767B2389F07C1074810A35763B2BEF2F5CF42EDA2AEF68882E45C1CC5E90141FB6B73655106924D0C9F514844A051BB88072937A074C6F5610BF6257B158C0A63FD780596F582428C88AE19BB28048F8C69A840787A5AA20845502B481425881C20F9B5A653F
```

```
# 解析私钥
ø> ./rsademo -parse keys
OpenSSH Private Key
  keyType: ssh-rsa
  n: 3072 0xCD1E1FB5DE2A0EFB36E184AD5B7B6FB811BECC938020FF5507E9DB4614F6AEC21F4CF53AF563BD6FA4715686672B74BA6E93F1096DDA4F71F9C4E1BD4355CE64923A19626F8511ECD717A7935EF26DF325B099D0B2BDDE6369570E9EFE851312C5F1D9054DFEA3EAE6106CDDB0159F7EA4607DE4B9CF163933C808C5CDDEE4A5023E459149D97F4009CBC64403CAA0F25CAF2A52CFB5C04619C289057473C6FECA71D94A348F0D53245E5EFBCDF6100F48A954D5F9C704E8784AC55E675186B4FAFD2AD4EF63A214C67CBC13E5070C1BC48F36A01ABDC5A1E989127363AFE2C803B35372B1AD9A26C0FE70ED64A0D0C0BE3FC0345006FCC6486C1C170F1E0FF29B0CC19A8BB0962B7E751536CB2851DAA9F07219512F71B8948B767B2389F07C1074810A35763B2BEF2F5CF42EDA2AEF68882E45C1CC5E90141FB6B73655106924D0C9F514844A051BB88072937A074C6F5610BF6257B158C0A63FD780596F582428C88AE19BB28048F8C69A840787A5AA20845502B481425881C20F9B5A653F
  e: 0x010001
  d: 0x4F24AB699A02326B9DDE603A1F8D3E2B10B5C4EBB8C9829B85852735204B9A5C8E853C2DF696F876064630F385055071CACECC772DEAC9329A03EC7201742F41C0E627FB423A5F133A5F072AA6BCF5CD96A2508725207B997200C44476C253FCAF61C4B1F64925683242EE2E8F8D984FDE0ED92492C923B30896CB43BF4E9C7C4AA44A6567D042F82B8F73BDB494CF8B1456060793DB7607D652A859F177E6B552D9A0D4AFF8EE544139247F161636561F5C2EBEAD34AC612260FF4C90A2F54D57972DE74B3DFC00EF9CEC72B91037A02D05ACA3CB353AEFFBAB8046997CD8859A98F32E2590FC2B5630981E8FA7DA7C8CFA8C15C549585335142853EDD1587D583CA711BFCB43F1B1D7852549F793F3F1EC39F9F0D8E4284BA0AA3D0CFDE04A00D5165A9AD82FC0DCB06A0EC01195EE09299BB76EE9397D58F1FFD635C8FFDC903593738CC70263A9A53AEE57B66B1437F8182F654DCC421929C5710B165CF16966FDFC035B0EB25B85455238D1D7B80CAE470D85898DF54C2280322FA347F1
  p: 0xFF5B9A8C23FB76C20819F696DBC3998B3CA756F7228DB2851833B245BC611DCB0E23B231FA5EB42787D09AC95A2409F674DA257F4444AFE07F51C3E24669D1EF3A6466255A49C0FDF41FBD59DA8753E0303AF7243C19DFC060ACA6ED7EA899A4A2313F1FF4A4C7B5DAEA351E57F80B4BE3595D4499D595C3BC0997BBFB5C23D72F948F30718DFB3161952388462BB74ED764A427750ADDF2CDF213747FFC8D9C628E7135EA8332A19A292C971FCA9A3311A24CDA5F4BEC3D05D51DD1DC26FAD9
  q: 0xCDA22D18CE6E5CCC86C99681EE5087D4A5B1019717A991939FCD9603FC89081FDD63D630662A2EA1BF32C61538D709E8207C5778D37071851442161E06369F8F16A72111E3E4D5FF92090F87D4053A7BA2C78303A1CBDE7919CAB9FE1627EB5BCC42D72C4C79061D2326384B7F25B09081C12828E2B5F000778EC746E6395D9381946E6DB0F52988CCF82DDFD66CBF24ABBB5C9532DE66681C3B9D0169B785084216FDC6E2790CA83460B27CD0926842A2A23D64B448BA49B5483340BC2DE1D7
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

公钥解密其实执行的还是加密操作，将收到的密文进行一次加密，得到了明文

```
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

## 参考资料

* https://www.ruanyifeng.com/blog/2013/06/rsa_algorithm_part_one.html
* https://www.ruanyifeng.com/blog/2013/07/rsa_algorithm_part_two.html
* https://en.wikipedia.org/wiki/RSA_(cryptosystem)
* https://juejin.cn/post/6997271445776629768
* https://cjting.me/2020/03/13/rsa/
