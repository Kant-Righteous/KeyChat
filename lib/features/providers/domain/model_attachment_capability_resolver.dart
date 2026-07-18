import 'package:keychat/features/providers/data/model_attachment_capability_store.dart';
import 'package:keychat/features/providers/domain/model_attachment_capability.dart';

final class ResolvedAttachmentCapability {
  const ResolvedAttachmentCapability({
    required this.status,
    this.source,
  });

  factory ResolvedAttachmentCapability.fromRecord(
    ModelAttachmentCapability record,
  ) {
    return ResolvedAttachmentCapability(
      status: record.status,
      source: record.source,
    );
  }

  final AttachmentCapabilityStatus status;
  final AttachmentCapabilitySource? source;
}

final class ModelAttachmentCapabilityResolver {
  ModelAttachmentCapabilityResolver({
    required ModelAttachmentCapabilityStore store,
    DateTime Function()? clock,
  })  : _store = store,
        _clock = clock ?? DateTime.now;

  final ModelAttachmentCapabilityStore _store;
  final DateTime Function() _clock;

  Future<ResolvedAttachmentCapability> resolve({
    required String providerId,
    required String modelId,
    required ModelInputModality modality,
  }) async {
    final manual = await _store.readCapability(
      providerId: providerId,
      modelId: modelId,
      modality: modality,
      source: AttachmentCapabilitySource.manual,
    );
    if (manual != null) {
      return ResolvedAttachmentCapability.fromRecord(manual);
    }

    final detected = await _store.readCapability(
      providerId: providerId,
      modelId: modelId,
      modality: modality,
      source: AttachmentCapabilitySource.detected,
    );
    if (detected != null) {
      return ResolvedAttachmentCapability.fromRecord(detected);
    }

    return ResolvedAttachmentCapability(
      status: presetAttachmentCapabilityStatus(
        providerId,
        modelId,
        modality,
      ),
    );
  }

  Future<void> saveDetected({
    required String providerId,
    required String modelId,
    required ModelInputModality modality,
    required AttachmentCapabilityStatus status,
  }) {
    return _save(
      providerId: providerId,
      modelId: modelId,
      modality: modality,
      status: status,
      source: AttachmentCapabilitySource.detected,
    );
  }

  Future<void> saveManual({
    required String providerId,
    required String modelId,
    required ModelInputModality modality,
    required AttachmentCapabilityStatus status,
  }) {
    return _save(
      providerId: providerId,
      modelId: modelId,
      modality: modality,
      status: status,
      source: AttachmentCapabilitySource.manual,
    );
  }

  Future<void> clearManual({
    required String providerId,
    required String modelId,
    required ModelInputModality modality,
  }) {
    return _store.deleteCapability(
      providerId: providerId,
      modelId: modelId,
      modality: modality,
      source: AttachmentCapabilitySource.manual,
    );
  }

  Future<void> resetDetected({
    required String providerId,
    required String modelId,
  }) {
    return _store.deleteDetectedForModel(
      providerId: providerId,
      modelId: modelId,
    );
  }

  Future<void> _save({
    required String providerId,
    required String modelId,
    required ModelInputModality modality,
    required AttachmentCapabilityStatus status,
    required AttachmentCapabilitySource source,
  }) {
    return _store.saveCapability(ModelAttachmentCapability(
      providerId: providerId,
      modelId: modelId,
      modality: modality,
      status: status,
      source: source,
      updatedAt: _clock(),
    ));
  }
}

AttachmentCapabilityStatus presetAttachmentCapabilityStatus(
  String providerId,
  String modelId,
  ModelInputModality modality,
) {
  final model = modelId.trim().toLowerCase();
  if (model.isEmpty ||
      providerId == 'custom' ||
      providerId.startsWith('custom_') ||
      providerId == 'deepseek') {
    return AttachmentCapabilityStatus.unknown;
  }

  final supportsImages = <String>[
    'gpt-4o',
    'gpt-4.1',
    'gpt-5',
    'o1',
    'o3',
    'o4',
    'gemini',
    'claude-3',
    'claude-sonnet-4',
    'claude-opus-4',
    'qwen-vl',
    'glm-4v',
  ].any(model.contains);

  final supported = modality == ModelInputModality.image
      ? supportsImages
      : providerId == 'openrouter' && supportsImages;
  return supported
      ? AttachmentCapabilityStatus.supported
      : AttachmentCapabilityStatus.unknown;
}
