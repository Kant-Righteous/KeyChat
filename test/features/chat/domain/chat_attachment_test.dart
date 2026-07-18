import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/domain/chat_attachment.dart';

void main() {
  group('ChatRequestMessage multimodal JSON', () {
    test('encodes image as an OpenAI-compatible image_url data URL', () {
      final json = const ChatRequestMessage(
        role: 'user',
        content: 'Describe this image',
        attachments: [
          ChatRequestAttachment(
            attachmentId: 'image-1',
            kind: ChatAttachmentKind.image,
            fileName: 'photo.png',
            mimeType: 'image/png',
            base64Data: 'aW1hZ2U=',
          ),
        ],
      ).toJson();

      expect(json['content'], [
        {'type': 'text', 'text': 'Describe this image'},
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/png;base64,aW1hZ2U='},
        },
      ]);
    });

    test('encodes an image-only message without an empty text part', () {
      final json = const ChatRequestMessage(
        role: 'user',
        content: '',
        attachments: [
          ChatRequestAttachment(
            attachmentId: 'image-1',
            kind: ChatAttachmentKind.image,
            fileName: 'photo.png',
            mimeType: 'image/png',
            base64Data: 'aW1hZ2U=',
          ),
        ],
      ).toJson();

      expect(json['content'], [
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/png;base64,aW1hZ2U='},
        },
      ]);
    });

    test('encodes ordinary file as an inline file content part', () {
      final json = const ChatRequestMessage(
        role: 'user',
        content: 'Read this file',
        attachments: [
          ChatRequestAttachment(
            attachmentId: 'file-1',
            kind: ChatAttachmentKind.file,
            fileName: 'notes.txt',
            mimeType: 'text/plain',
            base64Data: 'aGVsbG8=',
          ),
        ],
      ).toJson();

      expect(json['content'], [
        {'type': 'text', 'text': 'Read this file'},
        {
          'type': 'file',
          'file': {
            'filename': 'notes.txt',
            'file_data': 'data:text/plain;base64,aGVsbG8=',
          },
        },
      ]);
    });

    test('keeps legacy string content when there are no attachments', () {
      expect(
        const ChatRequestMessage(role: 'user', content: 'Hello').toJson(),
        {'role': 'user', 'content': 'Hello'},
      );
    });
  });
}
