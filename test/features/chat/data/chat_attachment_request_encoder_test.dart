import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_attachment_request_encoder.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_attachment.dart';

void main() {
  test('encodes only attachment kinds supported by the target model', () async {
    var readCount = 0;
    final encoder = ChatAttachmentRequestEncoder(
      bytesReader: (_) async {
        readCount++;
        return [1, 2, 3];
      },
    );
    final message = ChatMessage(
      id: 'user_1',
      role: ChatRole.user,
      content: 'Compare these',
      attachments: const [
        ChatAttachment(
          id: 'image_1',
          fileName: 'photo.png',
          mimeType: 'image/png',
          fileSize: 3,
          localPath: '/image',
          kind: ChatAttachmentKind.image,
          messageId: 'user_1',
          conversationId: 'conv_1',
        ),
        ChatAttachment(
          id: 'file_1',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 3,
          localPath: '/file',
          kind: ChatAttachmentKind.file,
          messageId: 'user_1',
          conversationId: 'conv_1',
        ),
      ],
      createdAt: DateTime(2024),
    );

    final request = await encoder.encode(
      message: message,
      supportsImageInput: true,
      supportsFileInput: false,
    );

    expect(request.attachments, hasLength(1));
    expect(request.attachments.single.kind, ChatAttachmentKind.image);
    expect(readCount, 1);
  });

  test('unsupported model does not read local attachment bytes', () async {
    var readCount = 0;
    final encoder = ChatAttachmentRequestEncoder(
      bytesReader: (_) async {
        readCount++;
        return [1];
      },
    );
    final request = await encoder.encode(
      message: ChatMessage(
        id: 'user_1',
        role: ChatRole.user,
        content: 'Text only',
        attachments: const [
          ChatAttachment(
            id: 'file_1',
            fileName: 'notes.txt',
            mimeType: 'text/plain',
            fileSize: 1,
            localPath: '/file',
            kind: ChatAttachmentKind.file,
            messageId: 'user_1',
            conversationId: 'conv_1',
          ),
        ],
        createdAt: DateTime(2024),
      ),
      supportsImageInput: false,
      supportsFileInput: false,
    );

    expect(request.attachments, isEmpty);
    expect(readCount, 0);
  });
}
