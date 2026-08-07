<h4 align="right"><strong><a href="./README.md">English</a></strong> | 简体中文</h4>
<h1 align="center">Java Chains</h1>
<div align="center">
<img alt="downloads" src="https://img.shields.io/github/downloads/vulhub/java-chains/total"/>
<img alt="release" src="https://img.shields.io/github/v/release/vulhub/java-chains"/>
<img alt="GitHub Stars" src="https://img.shields.io/github/stars/vulhub/java-chains?color=success"/>
</div>

面向安全研究的 Java Payload 生成平台。仅供个人学习研究。

## Docker

```bash
docker run -d \
  --name java-chains \
  --restart=unless-stopped \
  -p 8011:8011 \
  -p 58080:58080 -p 50389:50389 -p 50388:50388 \
  -p 3308:3308 -p 13999:13999 -p 50000:50000 -p 11527:11527 \
  -e CHAINS_AUTH=true \
  -e CHAINS_PASS= \
  javachains/javachains:2.0.0-beta5
```

或使用 Compose：

```bash
docker compose up -d
```

打开 `http://your-ip:8011`。`CHAINS_PASS` 为空时会随机生成密码，见 `docker logs -f java-chains` 中的 `Auth` 行。
