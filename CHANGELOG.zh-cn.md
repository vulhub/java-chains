## 1.4.0

**Added**

- 集成部分 FastjsonPayload
- 添加以下表达式注入 Payload
    - FreeMarker
    - JXPath @unam4
    - Thymeleaf @unam4
    - Aviator @ReaJason
    - JINJava @ReaJason
    - Velocity @ReaJason
- 使用 Exploit 模块时，直接生成 Payload 会自动判断端口是否开启，若服务端口未开启则自动开启对应服务。涉及 Exploit
  模块：JNDI、FakeMySQL、JRMPListener、HTTPServer、TCPServer

**Changed**

- java-chains 迁移至 vulhub 项目下
- 项目从 web-chains 更名 java-chains
- [class-obf](https://github.com/jar-analyzer/class-obf) 混淆项目 从 v1.4.0 更新至 v1.5.0
- 删除 WriteFile 字节码

## 1.3.1

**新增**

- SpringAopAspectjweaver 链

**Bug修复**

- 修复在 1.3.0 版本中 Payload 参数不生效问题
- 修复一些 Gadget 参数设置报错问题

**优化**

- 提高脏数据 overlong utf8 大包生成速度
- 在二次反序列化中支持混淆
- 部分链的描述
- Context 输出框新增额外信息
- 前端UI显示
- i18n

## 1.3.0

- [功能] 新增 [SerializationDumper](https://github.com/NickstaDB/SerializationDumper) 解析Java序列化数据，并自定义修改任意类
  SUID 等功能
- [功能] 开放 Chains 插件编写，参考：https://github.com/Java-Chains/chains-plugin-demo ，前端支持reload重加载插件
- [功能] 新增 Hessian2ToStringPayload，通过 except 可触发toString链
- [功能] 前端提供展示所有 Payload、Gadget 基础信息
- [功能] 新增 CommonsBeanutils5 Gadget，适用于 cb 1.10 版本
- [功能] 新增 FakeMySQLReadPayload 读文件利用，同时兼容 fileread_/etc/passwd 格式
  ，参考 https://github.com/4ra1n/mysql-fake-server
- [功能] Generate 生成模块提供 URL Encoding 编码选项
- [功能] gadget 注解中新增 preTags 字段，可用于指定前面的链
- [功能] 同步更新 [Class-Obf](https://github.com/jar-analyzer/class-obf) v1.4.0 版本
- [优化] JNDI、JRMP 等模块若端口未开放则会进行提醒
- [优化] 前端图标展示
- [优化] 整理后端代码
- [Bugfix] 修复Groovy生成Jar的问题。现在可以通过 OtherPayload -> GroovyJarConvert 中生成 Fastjson Groovy Jar

## 1.2.4

- [功能] 同步更新 Class-Obf v1.3.1 版本 (https://github.com/jar-analyzer/class-obf) @4ra1n
- [功能] 同步更新 java-memshell-generator(Jmg) v1.0.9 版本
- [功能] 新增 XmlDeSerPayload @unam4
- [功能] 新增 OpengaussJdbc 链 @guchangan1
- [功能] 自定义web登录密码，自定义是否关闭鉴权
- [优化] java-memshell-generator(Jmg) 优化报错提示；支持自动生成随机字符串参数，用于减少特征

## 1.2.3

- [功能] 支持字节码混淆，集成 Class-Obf(https://github.com/jar-analyzer/class-obf)项目 @4ra1n
- [功能] 新增 ExpressionPayload、JDBCPayload，方便生成表达式相关Payload以及JDBC URL相关Payload @Ar3h
- [优化] FakeMySQL日志更详细的输出 @Ar3h
- [BUG] 修复前端展开BUG @Ar3h

## 1.2.2

更新内容：

- [功能] 支持国际化，页面支持英文切换，登陆页面后右上角可进行切换语言 @Ar3h
- [功能] 新增 `OneForAllEcho` Gadget，属于字节码类型，可实现Tomcat、WebLogic、Jetty、Spring环境下的一键回显 @4ra1n
- [功能] 新增 `XMLDecoder` Payload 生成 @4ra1n
- [新链] 新增 HutoolJndiDSFactory、hutoolSimpleDSFactory、hutoolPooledDSFactory 三条hutools相关Getter链 @unam4
- [优化] Java反序列化支持完全 UTF8 Overlong（参考 PPPYSO 项目） @Ar3h
- [优化] 优化前端Gadget选项提示，前端使用青色提醒Gadget存在一些不适用的情况，需要阅读详细说明后自行判断 @Ar3h
- [优化] 拆分出 DNSLogWithInfo 链，专门用于通过DNSLog回显gadget链信息，方便在梭哈链中进行判断可用链 @Ar3h
- [优化] 前端添加缓存，减少请求量，提高速度 @Ar3h
- [BUG] 修复 DNSLog、DNSLogAndHttp 无法正常使用的严重BUG

感谢以下用户的贡献:

- Ar3h (https://github.com/Ar3h)
- 4ra1n (https://github.com/4ra1n)
- unam4 (https://github.com/unam4)

推荐使用 Docker 一键启动

## 1.2.1

更新内容：

- [功能] 新增 `Hessian LazyValueWithSleep` 链 @unam4
- [功能] 新增 `TomcatEcho` 回显 (可在 `Jeg` 无法使用时使用) @匿名
- [优化] 优化预设链的描述 @Ar3h
- [优化] 优化 `JNDI` 相关以及部分 `Gadget` 的描述 @Ar3h

感谢以下用户的贡献:

- Ar3h (https://github.com/Ar3h)
- unam4 (https://github.com/unam4)
- 某匿名安全研究师傅

使用 `java -jar java-chains.jar` 即可启动

推荐使用 `docker` 一键启动

## 1.2.0

更新内容：

- [重要] 新增预设链功能，常用链可实现一键勾选 @Ar3h
- [重要] 所有选项和配置添加详细的描述提示信息 @Ar3h
- [功能] 支持下载 `payload` 为文件功能 @Ar3h
- [功能] `OtherPayload` 新增 `JMG` 格式的 `JSP` @Ar3h
- [功能] `OtherPayload` 新增 `Java` 两种命令处理 @4ra1n
- [BUG] 修复前端 `gadget` 参数描述信息显示异常问题 @Ar3h
- [BUG] 修复前端部分 `payload` 传参错误搭导致无效生成 @Ar3h
- [BUG] 修复 `JSP` 模板无法正常使用的 `BUG` @Ar3h
- [BUG] 没有导入 `aspectj` 依赖导致部分 `gadget` 错误 @Ar3h
- [优化] 优化部分 `gadget` 的优先级排序 @Ar3h
- [优化] 支持展示 `jmg` 的提示输出信息 @Ar3h
- [优化] 登录用户名固定 `admin` 仅随机登陆密码 @4ra1n
- [优化] 安全方面删除 `security path` 功能 @4ra1n @ssrsec
- [优化] 前端默认使用更好看的黑色主题 @Ar3h
- [优化] 前端界面 `run` 和 `copy` 按钮位置优化 @Ar3h

感谢以下用户的贡献:

- Ar3h (https://github.com/Ar3h)
- 4ra1n (https://github.com/4ra1n)
- 说书人 (https://github.com/ssrsec)

使用 `java -jar java-chains.jar` 即可启动

推荐使用 `docker` 一键启动

## 1.1.0

更新内容：

- [重要] 前端大重构和优化 @Ar3h
- [重要] 提供 `docker` 一键启动命令 @Ar3h @4ra1n
- [重要] 提供了从 `jar` 文件加载的简易插件系统 @Ar3h
- [重要] 新增 `h2 without js` 全版本通杀链 @unam4
- [功能] 基于 `spring security` 的登录功能 @springkill @4ra1n
- [功能] 新增两种 `equals` 和 `c3p0 jndi/jdbc` 链 @unam4
- [功能] `hessian` 新增 `groovy` 利用链 @Ar3h
- [功能] 字节码可添加 `main` 静态入口函数 @Ar3h
- [BUG] 无法正确显示 `favicon.ico` 图标问题 @xcxmiku
- [优化] `server` 探测新增 `netty` 框架探测 @Ar3h
- [优化] 高版本 `Oralce JDK` 可以使用 `BCEL` 相关 @4ra1n
- [优化] 优化某些仅 `unix` 类型的 `gadget` 提示信息 @4ra1n
- [优化] 格式化输出日志，为日志附加颜色 @springkill
- [优化] 启动时检测 `java` 版本给出警告 @4ra1n
- [优化] 优化拦截器逻辑 @ssrsec
- [优化] 优化 `base64` 通用性 @ssrsec
- [文档] 编写新版本使用文档 @ssrsec

感谢以下用户的贡献:

- Ar3h (https://github.com/Ar3h)
- 某匿名安全研究师傅
- unam4 (https://github.com/unam4)
- 小晨曦 (https://github.com/xcxmiku)
- 4ra1n (https://github.com/4ra1n)
- springkill (https://github.com/springkill)
- 说书人 (https://github.com/ssrsec)

使用 `java -jar java-chains.jar` 即可启动（仅支持 `java 8` 环境）

推荐使用 `docker` 一键启动（请参考 `README` 页面）

其中 `chains-config.zip` 是补充插件，解压后放在 `jar` 同级目录即可

## 1.0.0

初始开源版本