import 'package:file_picker/file_picker.dart';
import 'package:keychat/features/chat/domain/chat_attachment.dart';
import 'package:mime/mime.dart';

const int maxAttachmentBytes = 10 * 1024 * 1024;
const int maxAttachmentsPerMessage = 5;

class AttachmentDraft {
  const AttachmentDraft({
    required this.sourcePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.kind,
  });

  final String sourcePath;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final ChatAttachmentKind kind;
}

abstract interface class AttachmentPicker {
  Future<List<AttachmentDraft>> pick(ChatAttachmentKind kind);
}

class FilePickerAttachmentPicker implements AttachmentPicker {
  const FilePickerAttachmentPicker();

  @override
  Future<List<AttachmentDraft>> pick(ChatAttachmentKind kind) async {
    final result = await FilePicker.platform.pickFiles(
      type: kind == ChatAttachmentKind.image ? FileType.image : FileType.any,
      allowMultiple: true,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return const [];

    return result.files.map((selected) {
      final sourcePath = selected.path;
      if (sourcePath == null || sourcePath.isEmpty) {
        throw const AttachmentSelectionException('unavailable_path');
      }
      if (selected.size > maxAttachmentBytes) {
        throw const AttachmentSelectionException('too_large');
      }
      return AttachmentDraft(
        sourcePath: sourcePath,
        fileName: selected.name,
        mimeType: lookupMimeType(sourcePath) ?? 'application/octet-stream',
        fileSize: selected.size,
        kind: kind,
      );
    }).toList(growable: false);
  }
}

class AttachmentSelectionException implements Exception {
  const AttachmentSelectionException(this.code);

  final String code;
}
