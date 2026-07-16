import 'package:keychat/features/providers/domain/model_attachment_capability.dart';

abstract interface class ModelAttachmentCapabilityStore {
  Future<ModelAttachmentCapability?> readCapability({
    required String providerId,
    required String modelId,
    required ModelInputModality modality,
    required AttachmentCapabilitySource source,
  });

  Future<void> saveCapability(ModelAttachmentCapability capability);

  Future<void> deleteCapability({
    required String providerId,
    required String modelId,
    required ModelInputModality modality,
    required AttachmentCapabilitySource source,
  });

  Future<void> deleteDetectedForModel({
    required String providerId,
    required String modelId,
  });
}

final class InMemoryModelAttachmentCapabilityStore
    implements ModelAttachmentCapabilityStore {
  final Map<
      ({
        String providerId,
        String modelId,
        ModelInputModality modality,
        AttachmentCapabilitySource source,
      }),
      ModelAttachmentCapability> _capabilities = {};

  @override
  Future<ModelAttachmentCapability?> readCapability({
    required String providerId,
    required String modelId,
    required ModelInputModality modality,
    required AttachmentCapabilitySource source,
  }) async {
    return _capabilities[(
      providerId: providerId,
      modelId: modelId,
      modality: modality,
      source: source,
    )];
  }

  @override
  Future<void> saveCapability(ModelAttachmentCapability capability) async {
    _capabilities[(
      providerId: capability.providerId,
      modelId: capability.modelId,
      modality: capability.modality,
      source: capability.source,
    )] = capability;
  }

  @override
  Future<void> deleteCapability({
    required String providerId,
    required String modelId,
    required ModelInputModality modality,
    required AttachmentCapabilitySource source,
  }) async {
    _capabilities.remove((
      providerId: providerId,
      modelId: modelId,
      modality: modality,
      source: source,
    ));
  }

  @override
  Future<void> deleteDetectedForModel({
    required String providerId,
    required String modelId,
  }) async {
    _capabilities.removeWhere((key, _) {
      return key.providerId == providerId &&
          key.modelId == modelId &&
          key.source == AttachmentCapabilitySource.detected;
    });
  }
}
