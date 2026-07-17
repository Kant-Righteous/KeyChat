import 'dart:io';

import 'package:flutter/material.dart';
import 'package:keychat/features/chat/data/attachment_picker.dart';
import 'package:keychat/features/chat/domain/chat_attachment.dart';

Future<void> _showImagePreview(
  BuildContext context, {
  required String localPath,
  required String fileName,
}) async {
  await showDialog<void>(
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

class PendingAttachmentPreview extends StatelessWidget {
  const PendingAttachmentPreview({
    super.key,
    this.previewKey = const Key('pending_attachment_preview'),
    this.removeKey = const Key('remove_pending_attachment'),
    required this.draft,
    required this.removeTooltip,
    required this.onRemove,
  });

  final AttachmentDraft draft;
  final Key previewKey;
  final Key removeKey;
  final String removeTooltip;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _AttachmentCard(
      key: previewKey,
      fileName: draft.fileName,
      mimeType: draft.mimeType,
      fileSize: draft.fileSize,
      localPath: draft.sourcePath,
      kind: draft.kind,
      imageKey: const Key('pending_attachment_image'),
      fileKey: const Key('pending_attachment_file'),
      trailing: IconButton(
        key: removeKey,
        onPressed: onRemove,
        tooltip: removeTooltip,
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}

class MessageAttachmentsView extends StatelessWidget {
  const MessageAttachmentsView({
    super.key,
    required this.attachments,
  });

  final List<ChatAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final attachment in attachments) _buildAttachment(attachment),
      ],
    );
  }

  Widget _buildAttachment(ChatAttachment attachment) {
    final card = _AttachmentCard(
      key: ValueKey('message_attachment_${attachment.id}'),
      fileName: attachment.fileName,
      mimeType: attachment.mimeType,
      fileSize: attachment.fileSize,
      localPath: attachment.localPath,
      kind: attachment.kind,
      imageKey: const Key('message_attachment_image'),
      fileKey: const Key('message_attachment_file'),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: attachment.kind == ChatAttachmentKind.image
          ? Align(alignment: Alignment.centerLeft, child: card)
          : card,
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    super.key,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.localPath,
    required this.kind,
    required this.imageKey,
    required this.fileKey,
    this.trailing,
  });

  final String fileName;
  final String mimeType;
  final int fileSize;
  final String localPath;
  final ChatAttachmentKind kind;
  final Key imageKey;
  final Key fileKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isImage = kind == ChatAttachmentKind.image;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isImage)
              Semantics(
                key: imageKey,
                label: fileName,
                button: true,
                child: GestureDetector(
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
            else
              Icon(
                Icons.insert_drive_file_outlined,
                key: fileKey,
                size: 32,
                color: colorScheme.primary,
              ),
            if (!isImage) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$mimeType · ${formatAttachmentSize(fileSize)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            if (isImage && trailing != null) const SizedBox(width: 8),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
    return card;
  }
}

String formatAttachmentSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kib = bytes / 1024;
  if (kib < 1024) return '${kib.toStringAsFixed(1)} KiB';
  return '${(kib / 1024).toStringAsFixed(1)} MiB';
}
