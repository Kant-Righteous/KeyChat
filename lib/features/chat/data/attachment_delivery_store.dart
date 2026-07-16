enum AttachmentDeliveryStatus {
  accepted,
  rejected,
}

abstract interface class AttachmentDeliveryStore {
  Future<AttachmentDeliveryStatus?> readStatus({
    required String attachmentId,
    required String providerId,
    required String modelId,
  });

  Future<void> saveStatus({
    required String attachmentId,
    required String providerId,
    required String modelId,
    required AttachmentDeliveryStatus status,
  });
}

final class InMemoryAttachmentDeliveryStore implements AttachmentDeliveryStore {
  final Map<({String attachmentId, String providerId, String modelId}),
      AttachmentDeliveryStatus> _statuses = {};

  @override
  Future<AttachmentDeliveryStatus?> readStatus({
    required String attachmentId,
    required String providerId,
    required String modelId,
  }) async {
    return _statuses[(
      attachmentId: attachmentId,
      providerId: providerId,
      modelId: modelId,
    )];
  }

  @override
  Future<void> saveStatus({
    required String attachmentId,
    required String providerId,
    required String modelId,
    required AttachmentDeliveryStatus status,
  }) async {
    _statuses[(
      attachmentId: attachmentId,
      providerId: providerId,
      modelId: modelId,
    )] = status;
  }
}
