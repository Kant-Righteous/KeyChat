import 'dart:convert';
import 'dart:io';

import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_attachment.dart';

typedef AttachmentBytesReader = Future<List<int>> Function(String path);

class ChatAttachmentRequestEncoder {
  ChatAttachmentRequestEncoder({AttachmentBytesReader? bytesReader})
      : _bytesReader = bytesReader ?? _readFileBytes;

  final AttachmentBytesReader _bytesReader;

  Future<ChatRequestMessage> encode({
    required ChatMessage message,
    required bool supportsImageInput,
    required bool supportsFileInput,
  }) async {
    final requestAttachments = <ChatRequestAttachment>[];
    if (message.role == ChatRole.user) {
      for (final attachment in message.attachments) {
        final isSupported = attachment.kind == ChatAttachmentKind.image
            ? supportsImageInput
            : supportsFileInput;
        if (!isSupported) continue;
        try {
          final bytes = await _bytesReader(attachment.localPath);
          requestAttachments.add(ChatRequestAttachment(
            kind: attachment.kind,
            fileName: attachment.fileName,
            mimeType: attachment.mimeType,
            base64Data: base64Encode(bytes),
          ));
        } catch (_) {
          // A missing local attachment must not prevent sending the text.
        }
      }
    }
    return ChatRequestMessage(
      role: message.role == ChatRole.user ? 'user' : 'assistant',
      content: message.content,
      attachments: requestAttachments,
    );
  }

  static Future<List<int>> _readFileBytes(String path) {
    return File(path).readAsBytes();
  }
}
