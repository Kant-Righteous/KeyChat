enum ModelInputModality {
  image,
  file,
}

enum AttachmentCapabilityStatus {
  unknown,
  supported,
  unsupported,
}

enum AttachmentCapabilitySource {
  detected,
  manual,
}

final class ModelAttachmentCapability {
  const ModelAttachmentCapability({
    required this.providerId,
    required this.modelId,
    required this.modality,
    required this.status,
    required this.source,
    required this.updatedAt,
  });

  final String providerId;
  final String modelId;
  final ModelInputModality modality;
  final AttachmentCapabilityStatus status;
  final AttachmentCapabilitySource source;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ModelAttachmentCapability &&
            other.providerId == providerId &&
            other.modelId == modelId &&
            other.modality == modality &&
            other.status == status &&
            other.source == source &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        providerId,
        modelId,
        modality,
        status,
        source,
        updatedAt,
      );
}
