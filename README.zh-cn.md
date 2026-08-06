<h4 align="right"><strong><a href="./README.md">English</a></strong> | 简体中文</h4>
<h1 align="center">Java Chains</h1>
<div align="center">
<img alt="downloads" src="https://img.shields.io/github/downloads/vulhub/java-chains/total"/>
<img alt="release" src="https://img.shields.io/github/v/release/vulhub/java-chains"/>
<a href="https://discord.gg/ukC8KTrRXv">
  <img src="https://img.shields.io/discord/485505185167179778.svg" alt="Chat on Discord">
</a>
<img alt="GitHub Stars" src="https://img.shields.io/github/stars/vulhub/java-chains?color=success"/>
<div align="center">
    <img src="img/logo.png" width="60" alt="center">
</div>
</div>

`Java-Chains` 是一个 Java Payload 生成与漏洞利用 Web 平台，便于安全研究员快速生成 Java Payload，并对 JNDI 注入、MySQL JDBC 反序列化、JRMP 反序列化等场景做方便快速的测试。

> 站在巨人肩膀上

<p align="center">
  <img src="./img/main.zh-cn.png" />
</p>

## v2.0 Beta 亮点

- **链条工作台** — 默认示例链、模糊搜索 Gadget、URL 分享链条
- **Canonical `/api`** — Session 登录 + 作用域 API Token（`X-Api-Token`）
- **产品 CLI** — `java-chains-cli` 支持远程编排与离线纯生成
- **BuiltIn Exploit** — 默认打进发行包的利用工作台模块
- **Docker / Compose** — `javachains/javachains:2.0.0-beta3`（不再捆绑 MCP 二进制）

## 快速开始

文档：https://java-chains.github.io/docs/guide

### Docker Compose

```bash
# 可选：把 release 包里的 chains-config 放到本目录旁
docker compose up -d
docker logs -f java-chains | grep -i password
```

打开 `http://your-ip:8011`

### Docker run

```bash
docker run -d \
  --name java-chains \
  --restart=unless-stopped \
  -p 8011:8011 \
  -p 58080:58080 -p 50389:50389 -p 50388:50388 \
  -p 3308:3308 -p 13999:13999 -p 50000:50000 -p 11527:11527 \
  -e CHAINS_AUTH=true \
  -e CHAINS_PASS= \
  javachains/javachains:2.0.0-beta3
```

### Jar 启动

需要 **OpenJDK / Temurin / Zulu JDK 8**（Oracle JDK 8 不推荐，BCEL 相关链可能失败）。

```bash
tar -xzf java-chains-2.0.0-beta3.tar.gz
java -jar java-chains.jar
```

### CLI（可选）

```bash
# 远程：对接已启动的 server
export CHAINS_API_TOKEN=...
java -jar java-chains-cli.jar generate \
  --execution remote --server http://127.0.0.1:8011 --token-env CHAINS_API_TOKEN \
  --payload JavaNativePayload --chain CommonsBeanutils1 --arg cmd=id --encode base64 --json

# 离线本地纯生成（fat jar）
java -jar java-chains-cli.jar generate --execution local \
  --payload JavaNativePayload --chain CommonsBeanutils1 --arg cmd=id --encode base64 --json
```

## 发行产物（v2）

| 产物 | 内容 |
|---|---|
| `java-chains-<ver>.tar.gz` | Server fat jar（内嵌 SPA）+ `chains-config` |
| `java-chains-<ver>-<platform>.*` | 同上 + 内嵌 JDK 8 |
| `java-chains-cli-<ver>.tar.gz` | 产品 CLI fat jar（+ 可选瘦远程 jar）+ `chains-config` |
| `java-chains-sdk-<ver>.jar` | 嵌入用 SDK |
| Docker `javachains/javachains:<ver>` | Server 镜像 |

## 更新内容

[CHANGELOG.zh-cn.md](./CHANGELOG.zh-cn.md)

## 参考和致谢

仅支持个人研究学习，切勿用于非法犯罪活动。

本项目的开发者、提供者和维护者不对使用者使用工具的行为和后果负责，工具的使用者应自行承担风险。

参考致谢：

- https://github.com/ReaJason/MemShellParty
- https://github.com/wh1t3p1g/ysomap
- https://github.com/qi4L/JYso
- https://github.com/X1r0z/JNDIMap
- https://github.com/Whoopsunix/PPPYSO
- https://github.com/jar-analyzer/class-obf
- https://github.com/4ra1n/mysql-fake-server
- https://github.com/mbechler/marshalsec
- https://github.com/frohoff/ysoserial
- https://github.com/H4cking2theGate/ysogate
- https://github.com/Bl0omZ/JNDIEXP
- https://github.com/kezibei/Urldns
- https://github.com/rebeyond/JNDInjector
- https://github.dev/LxxxSec/CTF-Java-Gadget
- https://github.com/pen4uin/java-memshell-generator
- https://github.com/pen4uin/java-echo-generator
- https://github.com/NickstaDB/SerializationDumper
- https://xz.aliyun.com/t/5381
- http://rui0.cn/archives/1408

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=vulhub/java-chains&type=Date)](https://star-history.com/#vulhub/java-chains&Date)
