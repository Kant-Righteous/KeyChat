<div align="center">
  <img src="assets/branding/keychat_icon.png" alt="KeyChat 图标" width="96">
</div>

# KeyChat

[English](./README.md) | **简体中文**

KeyChat 是一个面向 Android 和 iOS 的本地优先 BYOK AI 对话客户端。应用会直接连接用户配置的 AI Provider，不使用 KeyChat 自有后端。

项目目前仍在开发中。

## 当前范围

- 支持 OpenAI、DeepSeek、OpenRouter 和自定义 OpenAI-compatible Provider
- 对话记录和 Provider 配置保存在本地
- API Key 通过系统安全存储保存
- 支持流式响应、Markdown 渲染和文件附件
- 支持自定义 Agent
- 支持英文和简体中文界面

## 开发

环境要求：Flutter，且 Dart SDK 兼容 `^3.6.1`。

```bash
flutter pub get
flutter run
```

提交修改前：

```bash
flutter analyze
flutter test
dart format .
```

项目仅支持 Android 和 iOS。

## 安全

API Key 不得写入数据库、日志、异常信息或测试快照。请求日志中的 Authorization Header 必须隐藏。
