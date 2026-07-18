import 'package:drift/drift.dart';
import 'package:keychat/features/providers/data/drift/app_database.dart';
import 'package:keychat/features/providers/data/model_attachment_capability_store.dart';
import 'package:keychat/features/providers/domain/model_attachment_capability.dart';

final class DriftModelAttachmentCapabilityStore
    implements ModelAttachmentCapabilityStore {
  DriftModelAttachmentCapabilityStore(this._db);

  final AppDatabase _db;

  @override
  Future<ModelAttachmentCapability?> readCapability({
    required String providerId,
    required String modelId,
    required ModelInputModality modality,
    required AttachmentCapabilitySource source,
  }) async {
    final query = _db.select(_db.modelAttachmentCapabilities)
      ..where((row) =>
          row.providerId.equals(providerId) &
          row.modelId.equals(modelId) &
          row.modality.equals(modality.name) &
          row.source.equals(source.name));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row);
  }

  @override
  Future<void> saveCapability(ModelAttachmentCapability capability) async {
    await _db.into(_db.modelAttachmentCapabilities).insertOnConflictUpdate(
          ModelAttachmentCapabilitiesCompanion(
            providerId: Value(capability.providerId),
            modelId: Value(capability.modelId),
            modality: Value(capability.modality.name),
            status: Value(capability.status.name),
            source: Value(capability.source.name),
            updatedAt: Value(capability.updatedAt),
          ),
        );
  }

  @override
  Future<void> deleteCapability({
    required String providerId,
    required String modelId,
    required ModelInputModality modality,
    required AttachmentCapabilitySource source,
  }) async {
    await (_db.delete(_db.modelAttachmentCapabilities)
          ..where((row) =>
              row.providerId.equals(providerId) &
              row.modelId.equals(modelId) &
              row.modality.equals(modality.name) &
              row.source.equals(source.name)))
        .go();
  }

  @override
  Future<void> deleteDetectedForModel({
    required String providerId,
    required String modelId,
  }) async {
    await (_db.delete(_db.modelAttachmentCapabilities)
          ..where((row) =>
              row.providerId.equals(providerId) &
              row.modelId.equals(modelId) &
              row.source.equals(AttachmentCapabilitySource.detected.name)))
        .go();
  }

  ModelAttachmentCapability _toDomain(ModelAttachmentCapabilityRow row) {
    final modality = ModelInputModality.values
        .where((value) => value.name == row.modality)
        .firstOrNull;
    final status = AttachmentCapabilityStatus.values
        .where((value) => value.name == row.status)
        .firstOrNull;
    final source = AttachmentCapabilitySource.values
        .where((value) => value.name == row.source)
        .firstOrNull;
    if (modality == null || status == null || source == null) {
      throw StateError('Invalid model attachment capability record');
    }
    return ModelAttachmentCapability(
      providerId: row.providerId,
      modelId: row.modelId,
      modality: modality,
      status: status,
      source: source,
      updatedAt: row.updatedAt,
    );
  }
}
