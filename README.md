<h4 align="right">English | <strong><a href="./README.zh-cn.md">简体中文</a></strong></h4>
<h1 align="center">Java Chains</h1>
<div align="center">
<img alt="downloads" src="https://img.shields.io/github/downloads/vulhub/java-chains/total"/>
<img alt="release" src="https://img.shields.io/github/v/release/vulhub/java-chains"/>
<a href="https://discord.gg/ukC8KTrRXv">
  <img src="https://img.shields.io/discord/485505185167179778.svg" alt="Chat on Discord">
</a>
<img alt="GitHub Stars" src="https://img.shields.io/github/stars/vulhub/java-chains?color=success"/>
<div align="center">
    <img src="./img/logo.png" width="60" alt="center">
</div>
</div>

`Java-Chains` is a Java payload generation and exploitation web platform for security researchers. It helps you build Java payloads quickly and test scenarios such as JNDI injection, MySQL JDBC deserialization, and JRMP deserialization.

> Standing on the shoulders of giants

<p align="center">
  <img src="./img/main.png" />
</p>

## v2.0 Beta highlights

- **Studio workbench** — default sample chain, fuzzy gadget search, shareable chain URL
- **Canonical `/api`** — session + scoped API token (`X-Api-Token`)
- **Product CLI** — `java-chains-cli` for remote orchestration and offline pure generate
- **BuiltIn Exploits** — optional exploit workbench modules packaged by default
- **Docker / Compose** — `javachains/javachains:2.0.0-beta3` (no bundled MCP binary)

## Quick start

Docs: https://java-chains.github.io/en/docs/guide

### Docker Compose

```bash
# optional: copy chains-config from the release tarball beside this file
docker compose up -d
docker logs -f java-chains | grep -i password
```

Open `http://your-ip:8011`

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

### Jar

Requires **OpenJDK / Temurin / Zulu JDK 8** (Oracle JDK 8 is not recommended for BCEL chains).

```bash
tar -xzf java-chains-2.0.0-beta3.tar.gz
cd java-chains-2.0.0-beta3   # or unpack layout with java-chains.jar + chains-config/
java -jar java-chains.jar
```

### CLI (optional)

```bash
# remote pure generate against a running server
export CHAINS_API_TOKEN=...
java -jar java-chains-cli.jar generate \
  --execution remote --server http://127.0.0.1:8011 --token-env CHAINS_API_TOKEN \
  --payload JavaNativePayload --chain CommonsBeanutils1 --arg cmd=id --encode base64 --json

# offline local pure generate (fat jar only)
java -jar java-chains-cli.jar generate --execution local \
  --payload JavaNativePayload --chain CommonsBeanutils1 --arg cmd=id --encode base64 --json
```

## Release artifacts (v2)

| Artifact | Contents |
|---|---|
| `java-chains-<ver>.tar.gz` | Server fat jar (SPA embedded) + `chains-config` |
| `java-chains-<ver>-<platform>.*` | Same + bundled JDK 8 |
| `java-chains-cli-<ver>.tar.gz` | Product CLI fat jar (+ thin remote jar if built) + `chains-config` |
| `java-chains-sdk-<ver>.jar` | Embeddable SDK |
| Docker `javachains/javachains:<ver>` | Server image |

## Changelog

[CHANGELOG.md](./CHANGELOG.md)

## References and acknowledgments

For personal research and learning only. Never use for illegal activity.

The developers, providers and maintainers are not responsible for actions or consequences of using this tool; users assume all risk.

Acknowledgments:

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

## Communication

If you have any questions, please open an issue.

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=vulhub/java-chains&type=Date)](https://star-history.com/#vulhub/java-chains&Date)
