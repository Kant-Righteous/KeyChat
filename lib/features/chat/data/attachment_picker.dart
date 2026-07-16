import 'package:file_picker/file_picker.dart';
import 'package:keychat/features/chat/domain/chat_attachment.dart';
import 'package:mime/mime.dart';

const int maxAttachmentBytes = 10 * 1024 * 1024;

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
  Future<AttachmentDraft?> pick(ChatAttachmentKind kind);
}

class FilePickerAttachmentPicker implements AttachmentPicker {
  const FilePickerAttachmentPicker();

  @override
  Future<AttachmentDraft?> pick(ChatAttachmentKind kind) async {
    final result = await FilePicker.platform.pickFiles(
      type: kind == ChatAttachmentKind.image ? FileType.image : FileType.any,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final selected = result.files.single;
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
  }
}

class AttachmentSelectionException implements Exception {
  const AttachmentSelectionException(this.code);

  final String code;
}
