import 'dart:io';

import 'package:keychat/features/chat/data/attachment_picker.dart';
import 'package:keychat/features/chat/domain/chat_attachment.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef AttachmentRootDirectoryProvider = Future<Directory> Function();

abstract interface class AttachmentFileStore {
  Future<ChatAttachment> persist({
    required AttachmentDraft draft,
    required String attachmentId,
    required String messageId,
    required String conversationId,
  });
}

class LocalAttachmentFileStore implements AttachmentFileStore {
  LocalAttachmentFileStore({
    AttachmentRootDirectoryProvider? rootDirectoryProvider,
  }) : _rootDirectoryProvider =
            rootDirectoryProvider ?? getApplicationDocumentsDirectory;

  final AttachmentRootDirectoryProvider _rootDirectoryProvider;

  @override
  Future<ChatAttachment> persist({
    required AttachmentDraft draft,
    required String attachmentId,
    required String messageId,
    required String conversationId,
  }) async {
    if (draft.fileSize > maxAttachmentBytes) {
      throw const AttachmentSelectionException('too_large');
    }
    final source = File(draft.sourcePath);
    if (!await source.exists()) {
      throw const AttachmentSelectionException('unavailable_path');
    }

    final root = await _rootDirectoryProvider();
    final destinationDirectory = Directory(
      p.join(root.path, 'attachments', conversationId, messageId),
    );
    await destinationDirectory.create(recursive: true);
    final safeFileName = p.basename(draft.fileName).replaceAll(
          RegExp(r'[^A-Za-z0-9._\-\u4e00-\u9fff]'),
          '_',
        );
    final destination = File(
      p.join(destinationDirectory.path, '$attachmentId-$safeFileName'),
    );
    await source.copy(destination.path);

    return ChatAttachment(
      id: attachmentId,
      fileName: draft.fileName,
      mimeType: draft.mimeType,
      fileSize: draft.fileSize,
      localPath: destination.path,
      kind: draft.kind,
      messageId: messageId,
      conversationId: conversationId,
    );
  }
}
