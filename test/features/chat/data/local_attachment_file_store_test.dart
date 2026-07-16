import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/attachment_picker.dart';
import 'package:keychat/features/chat/data/local_attachment_file_store.dart';
import 'package:keychat/features/chat/domain/chat_attachment.dart';

void main() {
  test('copies attachment bytes into the app-local attachment directory',
      () async {
    final source = File('pubspec.yaml').absolute;
    final root = Directory('build/attachment_store_test').absolute;
    final store = LocalAttachmentFileStore(
      rootDirectoryProvider: () async => root,
    );
    final attachment = await store.persist(
      draft: AttachmentDraft(
        sourcePath: source.path,
        fileName: 'pubspec.yaml',
        mimeType: 'text/yaml',
        fileSize: await source.length(),
        kind: ChatAttachmentKind.file,
      ),
      attachmentId: 'attachment_copy_test',
      messageId: 'message_copy_test',
      conversationId: 'conversation_copy_test',
    );

    expect(attachment.localPath, isNot(source.path));
    expect(attachment.localPath, startsWith(root.path));
    expect(await File(attachment.localPath).exists(), true);
    expect(
      await File(attachment.localPath).readAsBytes(),
      await source.readAsBytes(),
    );
  });

  test('rejects an attachment larger than the MVP limit before copying',
      () async {
    final store = LocalAttachmentFileStore(
      rootDirectoryProvider: () async => Directory('build').absolute,
    );

    expect(
      () => store.persist(
        draft: const AttachmentDraft(
          sourcePath: 'does-not-need-to-exist',
          fileName: 'too-large.bin',
          mimeType: 'application/octet-stream',
          fileSize: maxAttachmentBytes + 1,
          kind: ChatAttachmentKind.file,
        ),
        attachmentId: 'too_large',
        messageId: 'message',
        conversationId: 'conversation',
      ),
      throwsA(
        isA<AttachmentSelectionException>().having(
          (error) => error.code,
          'code',
          'too_large',
        ),
      ),
    );
  });
}
