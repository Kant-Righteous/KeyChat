import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/model_attachment_capability_store.dart';
import 'package:keychat/features/providers/domain/model_attachment_capability.dart';
import 'package:keychat/features/providers/domain/model_attachment_capability_resolver.dart';

void main() {
  group('ModelAttachmentCapabilityResolver', () {
    late InMemoryModelAttachmentCapabilityStore store;
    late ModelAttachmentCapabilityResolver resolver;

    setUp(() {
      store = InMemoryModelAttachmentCapabilityStore();
      resolver = ModelAttachmentCapabilityResolver(
        store: store,
        clock: () => DateTime.utc(2026, 7, 16),
      );
    });

    Future<void> save({
      required AttachmentCapabilityStatus status,
      required AttachmentCapabilitySource source,
      ModelInputModality modality = ModelInputModality.image,
      String providerId = 'openai',
      String modelId = 'gpt-4o',
    }) {
      return store.saveCapability(ModelAttachmentCapability(
        providerId: providerId,
        modelId: modelId,
        modality: modality,
        status: status,
        source: source,
        updatedAt: DateTime.utc(2026, 7, 15),
      ));
    }

    test('manual capability overrides detected capability', () async {
      await save(
        status: AttachmentCapabilityStatus.supported,
        source: AttachmentCapabilitySource.detected,
      );
      await save(
        status: AttachmentCapabilityStatus.unsupported,
        source: AttachmentCapabilitySource.manual,
      );

      final result = await resolver.resolve(
        providerId: 'openai',
        modelId: 'gpt-4o',
        modality: ModelInputModality.image,
      );

      expect(result.status, AttachmentCapabilityStatus.unsupported);
      expect(result.source, AttachmentCapabilitySource.manual);
    });

    test('clearing manual capability reveals detected capability', () async {
      await save(
        status: AttachmentCapabilityStatus.supported,
        source: AttachmentCapabilitySource.detected,
      );
      await save(
        status: AttachmentCapabilityStatus.unsupported,
        source: AttachmentCapabilitySource.manual,
      );

      await resolver.clearManual(
        providerId: 'openai',
        modelId: 'gpt-4o',
        modality: ModelInputModality.image,
      );
      final result = await resolver.resolve(
        providerId: 'openai',
        modelId: 'gpt-4o',
        modality: ModelInputModality.image,
      );

      expect(result.status, AttachmentCapabilityStatus.supported);
      expect(result.source, AttachmentCapabilitySource.detected);
    });

    test('detected capability overrides preset suggestion', () async {
      await save(
        status: AttachmentCapabilityStatus.unsupported,
        source: AttachmentCapabilitySource.detected,
      );

      final result = await resolver.resolve(
        providerId: 'openai',
        modelId: 'gpt-4o',
        modality: ModelInputModality.image,
      );

      expect(result.status, AttachmentCapabilityStatus.unsupported);
      expect(result.source, AttachmentCapabilitySource.detected);
    });

    test('known preset suggests supported without persisting a source',
        () async {
      final result = await resolver.resolve(
        providerId: 'openai',
        modelId: 'gpt-4o',
        modality: ModelInputModality.image,
      );

      expect(result.status, AttachmentCapabilityStatus.supported);
      expect(result.source, isNull);
    });

    test('unknown model resolves unknown instead of unsupported', () async {
      final result = await resolver.resolve(
        providerId: 'custom',
        modelId: 'unknown-model',
        modality: ModelInputModality.image,
      );

      expect(result.status, AttachmentCapabilityStatus.unknown);
      expect(result.source, isNull);
    });

    test('image and file capabilities remain independent', () async {
      await save(
        status: AttachmentCapabilityStatus.unsupported,
        source: AttachmentCapabilitySource.detected,
        modality: ModelInputModality.image,
        providerId: 'custom',
        modelId: 'mixed-model',
      );

      final image = await resolver.resolve(
        providerId: 'custom',
        modelId: 'mixed-model',
        modality: ModelInputModality.image,
      );
      final file = await resolver.resolve(
        providerId: 'custom',
        modelId: 'mixed-model',
        modality: ModelInputModality.file,
      );

      expect(image.status, AttachmentCapabilityStatus.unsupported);
      expect(file.status, AttachmentCapabilityStatus.unknown);
    });

    test('save helpers persist detected and manual sources', () async {
      await resolver.saveDetected(
        providerId: 'custom',
        modelId: 'learned-model',
        modality: ModelInputModality.image,
        status: AttachmentCapabilityStatus.supported,
      );
      await resolver.saveManual(
        providerId: 'custom',
        modelId: 'learned-model',
        modality: ModelInputModality.file,
        status: AttachmentCapabilityStatus.unsupported,
      );

      final detected = await store.readCapability(
        providerId: 'custom',
        modelId: 'learned-model',
        modality: ModelInputModality.image,
        source: AttachmentCapabilitySource.detected,
      );
      final manual = await store.readCapability(
        providerId: 'custom',
        modelId: 'learned-model',
        modality: ModelInputModality.file,
        source: AttachmentCapabilitySource.manual,
      );

      expect(detected?.status, AttachmentCapabilityStatus.supported);
      expect(detected?.updatedAt, DateTime.utc(2026, 7, 16));
      expect(manual?.status, AttachmentCapabilityStatus.unsupported);
      expect(manual?.updatedAt, DateTime.utc(2026, 7, 16));
    });
  });
}
