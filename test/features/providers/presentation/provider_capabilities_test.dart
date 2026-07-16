import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/model_attachment_capability_store.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';
import 'package:keychat/features/providers/domain/model_attachment_capability.dart';
import 'package:keychat/features/providers/presentation/provider_config_page.dart';

import '../../../test_helpers.dart';
import '../data/fake_api_key_store.dart';
import '../data/fake_provider_config_store.dart';

void main() {
  test('known preset models receive conservative default capabilities', () {
    final openAi = defaultInputCapabilities('openai', 'gpt-4o');
    expect(openAi.supportsImageInput, true);
    expect(openAi.supportsFileInput, false);

    final openRouter = defaultInputCapabilities(
      'openrouter',
      'openai/gpt-4o',
    );
    expect(openRouter.supportsImageInput, true);
    expect(openRouter.supportsFileInput, true);

    final custom = defaultInputCapabilities('custom', 'gpt-4o');
    expect(custom.supportsImageInput, false);
    expect(custom.supportsFileInput, false);
  });

  testWidgets('Custom Provider saves model-specific manual capability modes',
      (tester) async {
    final apiKeyStore = FakeApiKeyStore();
    final configStore = FakeProviderConfigStore();
    final capabilityStore = InMemoryModelAttachmentCapabilityStore();
    final preset = providerPresets.firstWhere((item) => item.id == 'custom');

    await tester.pumpWidget(buildTestApp(
      home: ProviderConfigPage(
        preset: preset,
        apiKeyStore: apiKeyStore,
        configStore: configStore,
        modelAttachmentCapabilityStore: capabilityStore,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Base URL'),
      'https://custom.example/v1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Default Model'),
      'custom-vision',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'API Key'),
      'test-marker-abc',
    );
    final imageMode = find.byKey(const Key('image_capability_mode'));
    final fileMode = find.byKey(const Key('file_capability_mode'));
    expect(imageMode, findsOneWidget);
    expect(fileMode, findsOneWidget);
    await tester.ensureVisible(imageMode);
    await tester.tap(imageMode);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supported').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(fileMode);
    await tester.tap(fileMode);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unsupported').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = await configStore.readConfig('custom');
    expect(saved, isNotNull);
    expect(saved!.supportsImageInput, true);
    expect(saved.supportsFileInput, false);
    expect(
      (await capabilityStore.readCapability(
        providerId: 'custom',
        modelId: 'custom-vision',
        modality: ModelInputModality.image,
        source: AttachmentCapabilitySource.manual,
      ))
          ?.status,
      AttachmentCapabilityStatus.supported,
    );
    expect(
      (await capabilityStore.readCapability(
        providerId: 'custom',
        modelId: 'custom-vision',
        modality: ModelInputModality.file,
        source: AttachmentCapabilitySource.manual,
      ))
          ?.status,
      AttachmentCapabilityStatus.unsupported,
    );
  });

  testWidgets('Automatic mode clears a manual model override', (tester) async {
    final apiKeyStore = FakeApiKeyStore();
    final configStore = FakeProviderConfigStore();
    final capabilityStore = InMemoryModelAttachmentCapabilityStore();
    final preset = providerPresets.firstWhere((item) => item.id == 'custom');
    await capabilityStore.saveCapability(ModelAttachmentCapability(
      providerId: 'custom',
      modelId: 'custom-vision',
      modality: ModelInputModality.image,
      status: AttachmentCapabilityStatus.supported,
      source: AttachmentCapabilitySource.manual,
      updatedAt: DateTime(2026),
    ));

    await tester.pumpWidget(buildTestApp(
      home: ProviderConfigPage(
        preset: preset,
        apiKeyStore: apiKeyStore,
        configStore: configStore,
        modelAttachmentCapabilityStore: capabilityStore,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Base URL'),
      'https://custom.example/v1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Default Model'),
      'custom-vision',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'API Key'),
      'test-marker-abc',
    );
    await tester.pumpAndSettle();

    final imageMode = find.byKey(const Key('image_capability_mode'));
    await tester.ensureVisible(imageMode);
    await tester.tap(imageMode);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      await capabilityStore.readCapability(
        providerId: 'custom',
        modelId: 'custom-vision',
        modality: ModelInputModality.image,
        source: AttachmentCapabilitySource.manual,
      ),
      isNull,
    );
  });

  testWidgets('Detected capability can be reset for the current model',
      (tester) async {
    final capabilityStore = InMemoryModelAttachmentCapabilityStore();
    await capabilityStore.saveCapability(ModelAttachmentCapability(
      providerId: 'custom',
      modelId: 'custom-vision',
      modality: ModelInputModality.file,
      status: AttachmentCapabilityStatus.unsupported,
      source: AttachmentCapabilitySource.detected,
      updatedAt: DateTime(2026),
    ));

    await tester.pumpWidget(buildTestApp(
      locale: const Locale('zh'),
      home: ProviderConfigPage(
        preset: providerPresets.firstWhere((item) => item.id == 'custom'),
        apiKeyStore: FakeApiKeyStore(),
        configStore: FakeProviderConfigStore(),
        modelAttachmentCapabilityStore: capabilityStore,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '默认模型'),
      'custom-vision',
    );
    await tester.pumpAndSettle();

    final reset = find.byKey(const Key('reset_detected_capabilities'));
    await tester.ensureVisible(reset);
    expect(find.text('自动检测'), findsWidgets);
    expect(find.text('当前生效状态: 不支持'), findsOneWidget);
    expect(find.text('重置检测结果'), findsOneWidget);
    await tester.tap(reset);
    await tester.pumpAndSettle();

    expect(
      await capabilityStore.readCapability(
        providerId: 'custom',
        modelId: 'custom-vision',
        modality: ModelInputModality.file,
        source: AttachmentCapabilitySource.detected,
      ),
      isNull,
    );
    expect(find.text('当前生效状态: 未知'), findsWidgets);
  });
}
