enum ChatAttachmentKind {
  image,
  file;

  String get storageValue => name;

  static ChatAttachmentKind fromStorageValue(String value) {
    return ChatAttachmentKind.values.firstWhere(
      (kind) => kind.storageValue == value,
      orElse: () => ChatAttachmentKind.file,
    );
  }
}

class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.localPath,
    required this.kind,
    required this.messageId,
    required this.conversationId,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String localPath;
  final ChatAttachmentKind kind;
  final String messageId;
  final String conversationId;
}

class ChatRequestAttachment {
  const ChatRequestAttachment({
    required this.attachmentId,
    required this.kind,
    required this.fileName,
    required this.mimeType,
    required this.base64Data,
  });

  final String attachmentId;
  final ChatAttachmentKind kind;
  final String fileName;
  final String mimeType;
  final String base64Data;

  Map<String, dynamic> toJson() {
    final dataUrl = 'data:$mimeType;base64,$base64Data';
    if (kind == ChatAttachmentKind.image) {
      return {
        'type': 'image_url',
        'image_url': {'url': dataUrl},
      };
    }
    return {
      'type': 'file',
      'file': {
        'filename': fileName,
        'file_data': dataUrl,
      },
    };
  }
}
