# KeyChat - AGENTS.md

## 项目定位

本地优先 BYOK AI 对话客户端（Android + iOS）。用户自行配置 API Key，直接调用 AI Provider，不经过自有服务器。

## 开发命令

```bash
flutter analyze          # 静态分析，必须通过
flutter test             # 运行测试
dart format .            # 格式化
flutter run              # 启动（当前主要用 Android 模拟器）
```

## 项目结构

```
lib/
  main.dart              # 入口，当前为 Flutter 默认模板，尚未改造
test/
  widget_test.dart       # 默认测试
```

业务代码尚未开始开发。当前 `lib/main.dart` 仍是 Flutter 脚手架生成的计数器 Demo。

## 技术栈

- Flutter + Dart（SDK ^3.6.1）
- Android 原生层：Kotlin
- UI 框架：Material 3
- 网络：dio ^5.9.2
- 安全存储：flutter_secure_storage ^10.3.1
- 聊天 UI：flutter_chat_ui ^1.6.15
- 分析：package:flutter_lints/flutter.yaml

暂无数据库，后续计划 Drift + SQLite。

## 目标平台

仅 Android 和 iOS。当前开发环境为 Windows，优先 Android。

禁止添加 Web、Windows、macOS、Linux 平台支持。

## 架构原则

分层结构：UI → 应用/状态 → Domain → Data → Provider Adapter。

- 页面不得直接调用 Provider API，必须经过统一的 ProviderAdapter 接口
- Provider 是配置，Protocol 是代码，Model 是数据
- 第一阶段协议：OpenAI-compatible Chat Completions

## 第一版支持的 Provider

OpenAI、DeepSeek、OpenRouter、Custom OpenAI-compatible Provider。

不要在第一阶段实现所有 Provider。

## 安全要求（API Key）

- 必须使用 flutter_secure_storage 存储
- 禁止写入 SQLite、日志、异常信息、测试快照
- 禁止提交到 Git 或上传到任何服务器
- 请求日志必须隐藏 Authorization Header
- UI 中默认遮挡，必须支持删除

## 开发规则

- 不使用多智能体、不创建 worktree
- 非必要不调用额外 skill
- 不批量删除文件，删除多个文件前先列出等待确认
- 全程中文说明
- 不扩大任务范围，不擅自重构无关代码
- 不一次引入大量依赖
- 每次只完成一个可验证的小迭代
- 优先简单清晰，避免过度工程化和超前抽象
- 不为未来功能提前创建大量空文件
- UI 与 Provider 请求逻辑分离
- 异步操作需要 loading、成功、失败状态
- 错误信息用户友好

## 接到开发任务时

先提供 2-3 个执行方案，说明推荐方案、是否需要多智能体/worktree/skill、预计时间和 token 消耗、主要风险。

## 当前状态

项目刚创建，依赖已安装，尚未开始业务开发。`flutter analyze` 无问题。
