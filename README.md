<div align="center">
  <img src="assets/branding/keychat_icon.png" alt="KeyChat icon" width="96">
</div>

# KeyChat

**English** | [简体中文](./README.zh-CN.md)

KeyChat is a local-first BYOK AI chat client for Android and iOS. It connects directly to the AI provider configured by the user and does not use a KeyChat backend.

The project is currently under development.

## Current scope

- OpenAI, DeepSeek, OpenRouter, and custom OpenAI-compatible providers
- Local conversation history and provider configuration
- API key storage through the platform's secure storage
- Streaming responses, Markdown rendering, and file attachments
- Custom agent profiles
- English and Simplified Chinese interfaces

## Development

Requirements: Flutter with a Dart SDK compatible with `^3.6.1`.

```bash
flutter pub get
flutter run
```

Before submitting changes:

```bash
flutter analyze
flutter test
dart format .
```

Only Android and iOS are supported.

## Security

API keys must not be written to the database, logs, exception messages, or test snapshots. Authorization headers must be redacted from request logs.
