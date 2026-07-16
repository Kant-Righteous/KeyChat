import 'dart:io';

import 'package:flutter/material.dart';
import 'package:keychat/features/chat/data/attachment_picker.dart';
import 'package:keychat/features/chat/domain/chat_attachment.dart';

class PendingAttachmentPreview extends StatelessWidget {
  const PendingAttachmentPreview({
    super.key,
    required this.draft,
    required this.removeTooltip,
    required this.onRemove,
  });

  final AttachmentDraft draft;
  final String removeTooltip;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _AttachmentCard(
      key: const Key('pending_attachment_preview'),
      fileName: draft.fileName,
      mimeType: draft.mimeType,
      fileSize: draft.fileSize,
      localPath: draft.sourcePath,
      kind: draft.kind,
      imageKey: const Key('pending_attachment_image'),
      fileKey: const Key('pending_attachment_file'),
      trailing: IconButton(
        key: const Key('remove_pending_attachment'),
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
        for (final attachment in attachments)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _AttachmentCard(
              key: ValueKey('message_attachment_${attachment.id}'),
              fileName: attachment.fileName,
              mimeType: attachment.mimeType,
              fileSize: attachment.fileSize,
              localPath: attachment.localPath,
              kind: attachment.kind,
              imageKey: const Key('message_attachment_image'),
              fileKey: const Key('message_attachment_file'),
            ),
          ),
      ],
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
    return DecoratedBox(
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
            if (kind == ChatAttachmentKind.image)
              ClipRRect(
                key: imageKey,
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
              )
            else
              Icon(
                Icons.insert_drive_file_outlined,
                key: fileKey,
                size: 32,
                color: colorScheme.primary,
              ),
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
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

String formatAttachmentSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kib = bytes / 1024;
  if (kib < 1024) return '${kib.toStringAsFixed(1)} KiB';
  return '${(kib / 1024).toStringAsFixed(1)} MiB';
}
