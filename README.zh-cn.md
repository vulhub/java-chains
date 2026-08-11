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

`Java-Chains` 是面向安全研究员的 Java Payload 生成平台。可快速构造反序列化 / JNDI / JDBC / JRMP 等 Payload，并通过 Web Studio 或 CLI 启停协议监听（JNDI、FakeMySQL、JRMP、HTTP、TCP）。

> 站在巨人肩膀上

<p align="center">
  <img src="./img/main.zh-cn.png" />
</p>

## 快速开始

文档：https://java-chains.github.io/docs/guide

### Docker Compose

```bash
# 推荐：把 release 包里的 chains-config 放到本目录旁（与 docker-compose.yml 同级）
# （空的 ./chains-config 挂载仍可启动，但会遮住镜像内置的配置/插件）
docker compose up -d
# 启动横幅里账号密码在 "Auth" 行
docker logs -f java-chains | grep -i auth
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
  javachains/javachains:2.0.0-beta7
```

`CHAINS_PASS` 为空时启动会随机生成密码，见日志中的 `Auth` 行。  
`CHAINS_AUTH=false` 时还需显式设置 `CHAINS_ALLOW_AUTH_DISABLED=true`。

### Jar 启动

需要 **OpenJDK / Temurin / Zulu JDK 8**（Oracle JDK 8 不推荐，BCEL 相关链可能失败）。

```bash
tar -xzf java-chains-2.0.0-beta7.tar.gz
cd java-chains-2.0.0-beta7   # 或解压后目录内含 java-chains.jar + chains-config/
java -jar java-chains.jar
```

### CLI（可选）

产品 CLI 为 fat 包 `java-chains-cli.jar`（远程 catalog/generate + 离线本地生成）。不再提供独立 SDK jar。

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

## 交流

有问题请开 Issue，或加入 [Discord](https://discord.gg/ukC8KTrRXv)。

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=vulhub/java-chains&type=Date)](https://star-history.com/#vulhub/java-chains&Date)

## 项目贡献者

排名不分先后：

<p>
  <a href="https://github.com/Ar3h"><img src="https://github.com/Ar3h.png?size=100" width="64" height="64" alt="Ar3h" title="Ar3h"/></a>
  <a href="https://github.com/xcxmiku"><img src="https://github.com/xcxmiku.png?size=100" width="64" height="64" alt="xcxmiku" title="xcxmiku"/></a>
  <a href="https://github.com/unam4"><img src="https://github.com/unam4.png?size=100" width="64" height="64" alt="unam4" title="unam4"/></a>
  <a href="https://github.com/phith0n"><img src="https://github.com/phith0n.png?size=100" width="64" height="64" alt="phith0n" title="phith0n"/></a>
  <a href="https://github.com/CHYbeta"><img src="https://github.com/CHYbeta.png?size=100" width="64" height="64" alt="CHYbeta" title="CHYbeta"/></a>
  <a href="https://github.com/ssrsec"><img src="https://github.com/ssrsec.png?size=100" width="64" height="64" alt="ssrsec" title="ssrsec"/></a>
  <a href="https://github.com/springkill"><img src="https://github.com/springkill.png?size=100" width="64" height="64" alt="springkill" title="springkill"/></a>
  <a href="https://github.com/su18"><img src="https://github.com/su18.png?size=100" width="64" height="64" alt="su18" title="su18"/></a>
  <a href="https://github.com/4ra1n"><img src="https://github.com/4ra1n.png?size=100" width="64" height="64" alt="4ra1n" title="4ra1n"/></a>
  <a href="https://github.com/ReaJason"><img src="https://github.com/ReaJason.png?size=100" width="64" height="64" alt="ReaJason" title="ReaJason"/></a>
</p>
