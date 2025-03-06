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

`Java-Chains` is a Java Payload generation and vulnerability exploitation web platform, designed to facilitate security
researchers in quickly generating Java Payloads and conveniently and rapidly testing vulnerabilities such as JNDI
injection, MySQL JDBC deserialization, and JRMP deserialization. It aims to improve testing efficiency to a certain
extent.

> Standing on the shoulders of giants

<p align="center">
  <img src="./img/main.png" />
</p>

## Quick Start

> [!WARNING]
> Special Note: We only provide random password login protection for port 8011 by default. Other ports may have the risk
> of being counter-exploited. Please remember to close the corresponding ports after using the relevant functions.

### Method 1: Docker

You can start the `java-chains` project with a single `docker` command (recommended approach).

```shell
docker run -d \
  --name java-chains \
  --restart=always \
  -p 8011:8011 \
  -p 58080:58080 \
  -p 50389:50389 \
  -p 50388:50388 \
  -p 13999:13999 \
  -p 3308:3308 \
  -p 11527:11527 \
  -p 50000:50000 \
  -e CHAINS_AUTH=true \
  -e CHAINS_PASS= \
  javachains/javachains:1.4.0
```

Authentication or password can be configured through environment variables;

**CHAINS_AUTH**: `true` to enable authentication, `false` to disable authentication. Authentication is enabled by
default.

**CHAINS_PASS**: Specify the web password. If this variable is empty, a random password will be generated. Random
password generation is the default.

Note: Only port `8011` is required for the generation function. Other ports are used by the `exploit` module.

Use the following command to retrieve the randomly generated strong password from Docker:

```shell
docker logs $(docker ps | grep javachains/javachains | awk '{print $1}') | grep -E 'password'
```

Output example:

```text
11-12 06:59:53.301 INFO  [main] c.a.c.w.c.SecurityConfig       |  | password: XSsWerJFGcCjB8FU
```

Login page: `http://your-ip:8011`

### Method 2: Jar Package Startup

⚠️ Only JDK8 is supported. Temurin8/Zulu8 JDK is recommended.

Use `java -jar java-chains.jar` to start. A randomly generated password will be printed after each startup.

Default listening address is 0.0.0.0. Login page: `http://your-ip:8011` (Use the username and password here to log in).

You can set the web login password through environment variables, for example:

Linux:

```bash
export CHAINS_PASS=[your_password] && java -jar java-chains.jar
```

Windows:

```cmd
set CHAINS_PASS=[your_password] && java -jar java-chains.jar
```

## Module Introduction

`Java-Chains` comprises the following six major modules:

### Generation Module (Generate)

`JavaNativePayload`: Java Native Deserialization Payload Generation

`HessianPayload`: Hessian1 Deserialization Payload Generation, supporting HessianServlet format deserialized data

`Hessian2Payload`: Hessian2 Deserialization Payload Generation

`ShiroPayload`: Shiro Payload Generation, facilitating manual generation and testing in specific environments

- Supports custom AES KEY
- Supports AES GCM mode
- Supports inserting Base64 obfuscation characters

`OtherPayload`

- `CharsetJarConvet`: Generates charsets.jar package, suitable for file upload RCE scenarios under SpringBoot
- `GroovyJarConvert`: Generates fastjson-groovy.jar package, suitable for achieving RCE in high versions of Fastjson by
  loading specific format Jar packages via Groovy chains.
- `SnakeyamlJarConvert`: Generates snakeyaml.jar package, suitable for achieving RCE in SnakeYaml by loading specific
  format Jar packages via SPI.

- `JDBCPayload`: JDBC Payload Generation
    - H2 JDBC
    - PostgresSQL
    - ...

`ExpressionPayload`: Expression Payload Generation, essentially replacing the bytecode part in the bytecode template
with the expression. Manual implementation is recommended.

- `BcelConvert`: BCEL format bytecode generation
- `JsConvert`: Oracle Nashorn JS expression loading bytecode
- `VelocityConvert`: Velocity loading bytecode via bcel
- ...

`BytecodePayload`: Bytecode Generation

- For example, can generate bytecode for command execution, Sleep, DNSLog, in-memory webshell injection, echo,
  middleware detection, file writing, and file downloading.
- Supports custom bytecode version
- Supports custom bytecode class name
- Supports generating TemplatesImpl bytecode format - implementing the AbstractTranslet interface
- Supports bytecode obfuscation using Class-Obf

`XStreamPayload`: XStream data generation, not fully tested yet, some Payloads may not be usable.

---

The Payloads generated by this platform support the following obfuscation scenarios:

|                                      | JavaNativePayload | HessianPayload | Hessian2Payload |
|--------------------------------------|-------------------|----------------|-----------------|
| Random Collection Dirty Data Padding | ✅                 | ✅              | ✅               |
| Garbage Class Padding                | ✅                 | ✅              | ✅               |
| UTF-8 Overlong Encoding              | ✅                 | ✅              | ✅               |
| TC_RESET Padding                     | ✅                 | ❌              | ❌               |

---

Note: If you want to use `UserCustomByteArrayFromXXX` to provide custom Java serialized byte stream data for
obfuscation, currently it does not support random collection and garbage class insertion obfuscation. This is related to
the implementation of obfuscation. The specific support is as follows:

|                               | JavaNativePayload (Custom Serialization Scenario) |
|-------------------------------|---------------------------------------------------|
| Random Collection Obfuscation | ❌                                                 |
| Garbage Class Insertion       | ❌                                                 |
| UTF-8 Overlong Encoding       | ✅                                                 |
| TC_RESET Padding              | ✅                                                 |

### JNDI Injection Exploitation Module (JNDI)

Supports six exploitation techniques, plus a ShowHand chain for easy one-click testing of common chains.

`JndiBasicPayload`: LDAP remote bytecode loading

`JndiDeserializationPayload`: Deserialization based on the javaSerializedData field in LDAP

`JndiResourceRefPayload`: LDAP exploitation based on BeanFactory Tomcat EL, Groovy, etc.

`JndiReferencePayload`: LDAP Reference exploitation based on other ObjectFactories, such as various DataSource JDBC
exploits.

`JndiRMIDeserializePayload`: RMI deserialization to bypass high version JDK in LDAP

`JndiRefBypassPayload`: ReferenceBypass to bypass high version JDK in LDAP

`JndiShowHandPayload`: JNDI ShowHand Chain, one-click testing of common exploitation chains to improve testing
efficiency.

### MySQL JDBC Deserialization Exploitation Module (Fake MySQL)

`FakeMySQLPayload`: MySQL JDBC deserialization exploitation technique

`FakeMySQLReadPayload`: MySQL JDBC client file read exploitation technique

`FakeMySQLSHPayload`: FakeMySQL deserialization ShowHand Chain, one-click testing of common deserialization chains to
improve testing efficiency.

### JRMP Deserialization Exploitation Module (JRMPListener)

Can be used with JRMPClient deserialization chain to bypass low versions of RMI.

### TCP Server

A simple TCP Server that can mount generated Payload files to a TCP port. Accessing this port will return the specified
content.

Suitable for Derby deserialization RCE scenarios, can directly obtain deserialization data through the TCP port.

### HTTP Server

A simple HTTP server that mounts generated Payload files to an HTTP port. Accessing the specified port will return the
specified content.

Suitable for scenarios such as PostgreSQL remote loading of SpringBeanXML files.

### Tools

Underlyingly calls SerializationDumper, which can parse serialized data and manually modify the serialVersionUID field
of classes.

![SerializationDumper.png](./img/SerializationDumper.png)

## Detailed use

Github Wiki: https://github.com/vulhub/java-chains/wiki

or Documentation: https://www.yuque.com/shenjingwa-leuvd/wpqdhf/war0zkzgzg3c4bzg

## Other

Advantages of this tool:

1. Compared to command-line tools, web interface operations are simpler and easier to use, making it convenient to
   generate JNDI injection, MySQL JDBC, and other test Payloads.
2. Decouples and reuses various Payloads, with dynamically rendered parameter input boxes on the frontend, facilitating
   expansion and maintenance.
3. Collects and organizes a comprehensive range of Java, Hessian, and other deserialization Payloads, integrating
   various tricks and obfuscation techniques.

Disadvantages (also points to be improved):

1. Some less common Payload combinations may not work properly. Due to decoupling, the complexity of combinations
   increases, and it is currently impossible to cover and test all Payload combinations. To mitigate this, the platform
   provides a [Preset Chain] dropdown option above the Payload output box, offering tested chain combinations for
   reference. It is recommended to test less common Payload combinations in advance. If you find Payloads that do not
   run properly, you can submit Issues for feedback.
2. Due to the need for various dependencies to generate Payloads, the project's jar package is relatively large (
   200+MB).
3. Less common Payloads and Payloads with low practical value are not yet integrated.

Common questions:

Q: Why use Web instead of Java GUI?

A: Both have advantages, but I believe Web has a wider range of application scenarios. The main reason is that it is
very convenient to operate on the server to generate JNDI injection and other Payloads.

## Updated content

[CHANGELOG.md](./CHANGELOG.md)

## References and acknowledgments

It only supports personal research and learning, and should never be used for illegal and criminal activities.

The developers, providers and maintainers of the project are not responsible for the actions and consequences of the
user's use of the tool, and the user of the tool shall do so at their own risk.

Acknowledgments:

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

If you have any questions, please feel free to send issus

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=vulhub/java-chains&type=Date)](https://star-history.com/#vulhub/java-chains&Date)
