# 图片附件简单预览 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让待发送区域与已发送消息中的图片缩略图都能打开可缩放、可关闭的全屏预览。

**Architecture:** 保持附件数据和聊天页面调用方式不变，仅在现有附件展示组件内为图片缩略图增加点击入口。预览使用 Flutter 原生 `showDialog`、`Dialog.fullscreen`、`InteractiveViewer` 和 `Image.file`，文件附件继续保持当前行为。

**Tech Stack:** Flutter、Dart 3.6.1、Material 3、flutter_test

## Global Constraints

- 仅支持 Android 和 iOS，不添加 Web、Windows、macOS 或 Linux 平台支持。
- 不增加第三方依赖。
- 不修改附件存储、发送、Provider 请求或数据库逻辑。
- 待发送与已发送图片都使用现有本地路径；不得记录或上传附件内容。
- 单智能体、当前分支执行，不创建 worktree。
- 目标代码和测试文件已有未提交修改；只做增量编辑，不回退、覆盖或自动提交这些既有修改。

---

### Task 1: 图片缩略图全屏预览

**Files:**
- Modify: `lib/features/chat/presentation/widgets/attachment_preview.dart:25-180`
- Test: `test/features/chat/presentation/chat_attachment_test.dart:204-356`

**Interfaces:**
- Consumes: `AttachmentDraft.sourcePath`、`ChatAttachment.localPath`、现有 `_AttachmentCard.localPath` 和 `fileName`。
- Produces: 私有 `Future<void> _showImagePreview(BuildContext context, {required String localPath, required String fileName})`；稳定测试键 `image_preview_dialog`、`image_preview_interactive_viewer`、`close_image_preview`。

- [ ] **Step 1: 为待发送图片写失败测试**

在现有 `shows image preview and removes pending attachment` 测试中，确认缩略图后增加以下断言，再继续原有删除断言：

```dart
await tester.tap(find.byKey(const Key('pending_attachment_image')));
await tester.pumpAndSettle();

expect(find.byKey(const Key('image_preview_dialog')), findsOneWidget);
expect(
  find.byKey(const Key('image_preview_interactive_viewer')),
  findsOneWidget,
);

await tester.tap(find.byKey(const Key('close_image_preview')));
await tester.pumpAndSettle();
expect(find.byKey(const Key('image_preview_dialog')), findsNothing);
```

- [ ] **Step 2: 为已发送图片写失败测试**

在现有 `multimodal send keeps attachment in bubble and request` 测试确认消息缩略图后增加：

```dart
await tester.tap(find.byKey(const Key('message_attachment_image')));
await tester.pumpAndSettle();

expect(find.byKey(const Key('image_preview_dialog')), findsOneWidget);
expect(find.byType(InteractiveViewer), findsOneWidget);

await tester.pageBack();
await tester.pumpAndSettle();
expect(find.byKey(const Key('image_preview_dialog')), findsNothing);
```

- [ ] **Step 3: 为文件附件保持不可预览写失败保护测试**

在现有文件附件预览测试中点击文件图标并断言不会打开图片预览：

```dart
await tester.tap(find.byKey(const Key('pending_attachment_file')));
await tester.pumpAndSettle();
expect(find.byKey(const Key('image_preview_dialog')), findsNothing);
```

- [ ] **Step 4: 运行目标测试并确认失败原因**

Run:

```powershell
flutter test test/features/chat/presentation/chat_attachment_test.dart --plain-name "shows image preview and removes pending attachment"
flutter test test/features/chat/presentation/chat_attachment_test.dart --plain-name "multimodal send keeps attachment in bubble and request"
```

Expected: 两项测试都因找不到 `image_preview_dialog` 而失败；文件附件保护测试保持通过。

- [ ] **Step 5: 实现最小全屏预览**

在 `attachment_preview.dart` 顶层新增私有方法：

```dart
Future<void> _showImagePreview(
  BuildContext context, {
  required String localPath,
  required String fileName,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black,
    builder: (dialogContext) => Dialog.fullscreen(
      key: const Key('image_preview_dialog'),
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: InteractiveViewer(
                key: const Key('image_preview_interactive_viewer'),
                minScale: 1,
                maxScale: 4,
                child: Image.file(
                  File(localPath),
                  fit: BoxFit.contain,
                  semanticLabel: fileName,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                key: const Key('close_image_preview'),
                onPressed: () => Navigator.of(dialogContext).pop(),
                tooltip:
                    MaterialLocalizations.of(dialogContext).closeButtonTooltip,
                color: Colors.white,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

将 `_AttachmentCard` 的图片分支改为只让缩略图响应点击，并保留现有键、圆角、尺寸和错误占位：

```dart
if (isImage)
  Semantics(
    label: fileName,
    button: true,
    child: GestureDetector(
      key: imageKey,
      behavior: HitTestBehavior.opaque,
      onTap: () => _showImagePreview(
        context,
        localPath: localPath,
        fileName: fileName,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(localPath),
          width: 72,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => SizedBox(
            width: 72,
            height: 56,
            child: Icon(
              Icons.broken_image_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    ),
  )
```

图片分支已有按钮语义后，让 `_AttachmentCard.build` 直接返回 `card`，避免重复语义标签：

```dart
return card;
```

- [ ] **Step 6: 格式化并运行目标测试**

Run:

```powershell
dart format lib/features/chat/presentation/widgets/attachment_preview.dart test/features/chat/presentation/chat_attachment_test.dart
flutter test test/features/chat/presentation/chat_attachment_test.dart
```

Expected: 格式化成功，`chat_attachment_test.dart` 中所有测试通过。

- [ ] **Step 7: 运行项目级验证**

Run:

```powershell
flutter analyze
flutter test
```

Expected: 静态分析无问题，完整测试全部通过。若完整测试存在与本次无关的既有失败，只记录测试名、关键错误和与本次修改无关的证据，不扩大修复范围。

- [ ] **Step 8: 检查最终差异且不自动提交脏文件**

Run:

```powershell
git diff --check -- lib/features/chat/presentation/widgets/attachment_preview.dart test/features/chat/presentation/chat_attachment_test.dart
git diff --stat -- lib/features/chat/presentation/widgets/attachment_preview.dart test/features/chat/presentation/chat_attachment_test.dart
```

Expected: 无空白错误，差异范围仅包含附件组件和对应测试。由于两个目标文件在任务开始前已有未提交修改，本任务不自动暂存或提交，避免把用户既有修改捎带进新提交。
