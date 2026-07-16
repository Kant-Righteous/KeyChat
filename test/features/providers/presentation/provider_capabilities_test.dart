import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/data/provider_presets.dart';
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

  testWidgets('Custom Provider can save image and file capability switches',
      (tester) async {
    final apiKeyStore = FakeApiKeyStore();
    final configStore = FakeProviderConfigStore();
    final preset = providerPresets.firstWhere((item) => item.id == 'custom');

    await tester.pumpWidget(buildTestApp(
      home: ProviderConfigPage(
        preset: preset,
        apiKeyStore: apiKeyStore,
        configStore: configStore,
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
    final imageSwitch = find.byKey(const Key('supports_image_input_switch'));
    final fileSwitch = find.byKey(const Key('supports_file_input_switch'));
    expect(imageSwitch, findsOneWidget);
    expect(fileSwitch, findsOneWidget);
    await tester.ensureVisible(imageSwitch);
    await tester.tap(imageSwitch);
    await tester.ensureVisible(fileSwitch);
    await tester.tap(fileSwitch);
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = await configStore.readConfig('custom');
    expect(saved, isNotNull);
    expect(saved!.supportsImageInput, true);
    expect(saved.supportsFileInput, true);
  });
}
