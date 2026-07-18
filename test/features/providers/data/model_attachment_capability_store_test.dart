import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/model_attachment_capability_store.dart';
import 'package:keychat/features/providers/domain/model_attachment_capability.dart';

void main() {
  group('InMemoryModelAttachmentCapabilityStore', () {
    final detectedSupported = ModelAttachmentCapability(
      providerId: 'custom',
      modelId: 'vision-1',
      modality: ModelInputModality.image,
      status: AttachmentCapabilityStatus.supported,
      source: AttachmentCapabilitySource.detected,
      updatedAt: DateTime.utc(2026, 7, 16),
    );
    final manualUnsupported = ModelAttachmentCapability(
      providerId: 'custom',
      modelId: 'vision-1',
      modality: ModelInputModality.image,
      status: AttachmentCapabilityStatus.unsupported,
      source: AttachmentCapabilitySource.manual,
      updatedAt: DateTime.utc(2026, 7, 16, 0, 1),
    );

    test('manual and detected capability records coexist', () async {
      final store = InMemoryModelAttachmentCapabilityStore();
      await store.saveCapability(detectedSupported);
      await store.saveCapability(manualUnsupported);

      expect(
        await store.readCapability(
          providerId: 'custom',
          modelId: 'vision-1',
          modality: ModelInputModality.image,
          source: AttachmentCapabilitySource.detected,
        ),
        same(detectedSupported),
      );
      expect(
        await store.readCapability(
          providerId: 'custom',
          modelId: 'vision-1',
          modality: ModelInputModality.image,
          source: AttachmentCapabilitySource.manual,
        ),
        same(manualUnsupported),
      );
    });

    test('deleting manual record preserves detected record', () async {
      final store = InMemoryModelAttachmentCapabilityStore();
      await store.saveCapability(detectedSupported);
      await store.saveCapability(manualUnsupported);

      await store.deleteCapability(
        providerId: 'custom',
        modelId: 'vision-1',
        modality: ModelInputModality.image,
        source: AttachmentCapabilitySource.manual,
      );

      expect(
        await store.readCapability(
          providerId: 'custom',
          modelId: 'vision-1',
          modality: ModelInputModality.image,
          source: AttachmentCapabilitySource.manual,
        ),
        isNull,
      );
      expect(
        await store.readCapability(
          providerId: 'custom',
          modelId: 'vision-1',
          modality: ModelInputModality.image,
          source: AttachmentCapabilitySource.detected,
        ),
        same(detectedSupported),
      );
    });

    test('reset detected records is scoped to exact provider and model',
        () async {
      final store = InMemoryModelAttachmentCapabilityStore();
      await store.saveCapability(detectedSupported);
      await store.saveCapability(manualUnsupported);
      final otherModel = ModelAttachmentCapability(
        providerId: 'custom',
        modelId: 'vision-2',
        modality: ModelInputModality.file,
        status: AttachmentCapabilityStatus.supported,
        source: AttachmentCapabilitySource.detected,
        updatedAt: DateTime.utc(2026, 7, 16, 0, 2),
      );
      await store.saveCapability(otherModel);

      await store.deleteDetectedForModel(
        providerId: 'custom',
        modelId: 'vision-1',
      );

      expect(
        await store.readCapability(
          providerId: 'custom',
          modelId: 'vision-1',
          modality: ModelInputModality.image,
          source: AttachmentCapabilitySource.detected,
        ),
        isNull,
      );
      expect(
        await store.readCapability(
          providerId: 'custom',
          modelId: 'vision-1',
          modality: ModelInputModality.image,
          source: AttachmentCapabilitySource.manual,
        ),
        same(manualUnsupported),
      );
      expect(
        await store.readCapability(
          providerId: 'custom',
          modelId: 'vision-2',
          modality: ModelInputModality.file,
          source: AttachmentCapabilitySource.detected,
        ),
        same(otherModel),
      );
    });
  });
}
