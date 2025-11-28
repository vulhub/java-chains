## 1.4.2

#### 🚀 New Features

- **New Echo Modules**: Added multiple Echo chains/gadgets. Contributed by @ReaJason.
- **High JDK Support**: Added support for multiple gadgets compatible with JDK 17+ (identified by `HighJDK` or
  `HighVersion` suffix). Contributed by @n1ght (https://www.n1ght.cn/).
- **Embedded JDK**: Support for bundled JDK in the release, allowing out-of-the-box usage.
- **Payload Generation**:
    - Added FakeMySQLPipeFile generation. Contributed by @unam4.
    - Added JSF encrypted Payload generation. Contributed by @B0T1eR.
    - Added FileUpload1 gadget. Contributed by @B0T1eR.
    - Added Hutool MapProxy secondary deserialization gadget. Contributed by @unam4.
- **Environment Detection**: Added detection for `javax_servlet` and `jakarta_servlet`. Contributed by @B0T1eR.

#### 🛠 Improvements

- **JRMPListener Optimization**: Improved JRMPListener to prevent leaking local library information. Contributed by
  @unam4.
- **Dependency Clarification**: Clearly distinguished between `MchangeC3p0Reference` (com.mchange:c3p0) and
  `C3p0_C3p0Reference` (c3p0:c3p0).
- **UI Update**: Optimized the frontend login user interface.

#### 🐛 Bug Fixes

- Fixed an issue causing port conflicts.
- Fixed an issue triggering the Security Manager on Windows environments.

#### ❤️ Acknowledgments

Special thanks to the following users for reporting bugs and helping improve the project:
@Catherines77 @1diot9 @yuxianzi @Skay @jlkl @Ckmount

## 1.4.1

**Added**

1. Added partial fastjson payload generation capabilities and a Unicode-based WAF bypass technique by
   @xcxmiku. [Reference article](https://mp.weixin.qq.com/s?__biz=Mzg3NzczOTA3OQ==&mid=2247486066&idx=1&sn=25021413b4ca3be4037ea3819ff12bdc&chksm=cec076c7d99fce55e8eebc531a6c5e6363182ba166120fc676a4c161788ed43a5863efe57fff&mpshare=1&scene=1&srcid=0319gACpuJIZjaROthkFVH3Y&sharer_shareinfo=78b3da8cba5f6492f886dc1da02f001a&sharer_shareinfo_first=78b3da8cba5f6492f886dc1da02f001a#rd)
2. Display the User-Agent value of incoming HTTPServer requests.
3. Introduced a file upload parameter type to facilitate the customization of binary bytecode files. Refer to the
   corresponding Gadget: BytecodeFromUploadFile.
4. Introduced JmgCustomShellGadget, enabling the injection of custom memory shells.
5. Added support for specifying the listening address through environment variables.

**Changed**

1. Removed the `comparatorType` option from the CB chain.
2. Parameter values in log outputs are now displayed with a maximum length of 200 characters.
3. Fixed a concatenation error (#9).
4. Improved the frontend display of "Choice" selection parameters.
5. Fixed an exception related to custom bytecode.
6. Improved the frontend display of preset chains.
7. In download/save mode, the output format is automatically switched to Raw.

## 1.4.0

**Added**

- Integrated some FastjsonPayload @iSafeBlue
- Added the following Expression Injection Payloads:
    - FreeMarker
    - JXPath @unam4
    - Thymeleaf @unam4
    - Aviator @ReaJason
    - JINJava @ReaJason
    - Velocity @ReaJason
- When exploit modules are generated, they automatically check if the service port is open, and if not, automatically
  start it.

**Changed**

- java-chains migrated to the vulhub project.
- Project renamed from web-chains to java-chains.
- [class-obf](https://github.com/jar-analyzer/class-obf) obfuscation project updated from v1.4.0 to v1.5.0.
- Removed WriteFile bytecode.
- Removed the "delete" option from DownloadExec and WriteFileExec bytecode gadgets.
- Gadget IP parameter now defaults to 127.0.0.1.

## 1.3.1

**Added**

- SpringAopAspectjweaver Chain

**Bugfix**

- Fixed issue where Payload parameters were ineffective in version 1.3.0
- Fixed parameter setting errors for some Gadgets

**Optimization**

- Improved generation speed for large packets of overlong UTF8 dirty data
- Added support for obfuscation in secondary deserialization
- Improved descriptions for some chains
- Added extra information to the Context output box
- Frontend display improvements
- i18n

## 1.3.0

- [Feature] Added [SerializationDumper](https://github.com/NickstaDB/SerializationDumper) for parsing Java serialized
  data, enabling custom modification of class SUIDs, etc.
- [Feature] Enabled Chains plugin development. See: https://github.com/Java-Chains/chains-plugin-demo. The frontend
  supports plugin reloading.
- [Feature] Added Hessian2ToStringPayload; a toString chain can be triggered via `except`.
- [Feature] The frontend now displays basic information for all Payloads and Gadgets.
- [Feature] Added CommonsBeanutils5 Gadget, suitable for cb version 1.10.
- [Feature] Added FakeMySQLReadPayload for file reading exploitation, compatible with `fileread_/etc/passwd` format.
  See https://github.com/4ra1n/mysql-fake-server.
- [Feature] The Generate module now offers a URL Encoding option.
- [Feature] Added the `preTags` field in gadget annotations, which can be used to specify preceding chains.
- [Feature] Synchronously updated [Class-Obf](https://github.com/jar-analyzer/class-obf) to version v1.4.0.
- [Improvement] JNDI, JRMP, etc. modules will now provide a warning if the port is not open.
- [Improvement] Improved frontend icon display.
- [Improvement] Refactored backend code.
- [Bugfix] Fixed the Groovy Jar generation issue. Fastjson Groovy Jars can now be generated through OtherPayload ->
  GroovyJarConvert.

## 1.2.4

- [Feature] Synchronized update to Class-Obf v1.3.1 (https://github.com/jar-analyzer/class-obf) @4ra1n
- [Feature] Synchronously update java-memshell-generator to version v1.0.9
- [Feature] Added XmlDeSerPayload @unam4
- [Feature] Added OpengaussJdbc chain @guchangan1
- [Feature] Customize web login password, customize whether to disable authentication.
- [Optimization] java-memshell-generator (Jmg) optimizes error message prompts; supports automatically generating random
  string parameters to reduce signatures.

## 1.2.3

- [Feature] Support for bytecode obfuscation, integrated with the Class-Obf project by @4ra1n
- [Feature] Added ExpressionPayload and JDBCPayload for easier generation of expression-related Payloads and JDBC
  URL-related Payloads by @Ar3h
- [Improvement] Enhanced FakeMySQL logging with more detailed output by @Ar3h
- [Bugfix] Fixed front-end expansion issue by @Ar3h

## 1.2.2

What's new:

- [Feature] Support internationalization, the page supports English switching, and the language can be switched in the
  upper right corner after landing on the page @Ar3h
- [Feature] Added 'OneForAllEcho' Gadget, which is a bytecode type, which can realize one-click echo in Tomcat,
  WebLogic, Jetty, and Spring environments @4ra1n
- [Feature] Added 'XMLDecoder' Payload generation @4ra1n
- [New Chain] Added three Getter chains: HutoolJndiDSFactory、hutoolSimpleDSFactory、hutoolPooledDSFactory @unam4
- [Improve] Java deserialization support for full UTF8 overlong (see PPPYSO project) @Ar3h
- [Optimization] Optimized the prompt of the front-end Gadget option, the front-end uses cyan to remind that Gadget is
  not applicable to some situations, and you need to read the detailed description and make your own judgment @Ar3h
- [Improve] Split out the DNSLogWithInfo chain, which is specially used to echo the gadget chain information through
  DNSLog, which is convenient for judging the available chain in the stud chain @Ar3h
- [Improve] Add cache to the front-end to reduce the number of requests and improve the speed @Ar3h
- [BUG] Fixed the serious bug that DNSLog and DNSLogAndHttp could not be used normally

