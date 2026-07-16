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

  testWidgets('Provider config hides manual attachment capability controls',
      (tester) async {
    final preset = providerPresets.firstWhere((item) => item.id == 'custom');

    await tester.pumpWidget(buildTestApp(
      home: ProviderConfigPage(
        preset: preset,
        apiKeyStore: FakeApiKeyStore(),
        configStore: FakeProviderConfigStore(),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('image_capability_mode')), findsNothing);
    expect(find.byKey(const Key('file_capability_mode')), findsNothing);
    expect(find.byKey(const Key('reset_detected_capabilities')), findsNothing);
    expect(find.text('Supports image input'), findsNothing);
    expect(find.text('Supports file input'), findsNothing);
  });

  testWidgets('Provider config protects form bottom from system navigation',
      (tester) async {
    final preset = providerPresets.firstWhere((item) => item.id == 'custom');

    await tester.pumpWidget(buildTestApp(
      home: ProviderConfigPage(
        preset: preset,
        apiKeyStore: FakeApiKeyStore(),
        configStore: FakeProviderConfigStore(),
      ),
    ));
    await tester.pumpAndSettle();

    final scrollFinder = find.byKey(const Key('provider_config_scroll'));
    final scrollView = tester.widget<SingleChildScrollView>(
      scrollFinder,
    );
    final mediaPadding = MediaQuery.viewPaddingOf(
      tester.element(scrollFinder),
    );
    expect(
      (scrollView.padding! as EdgeInsets).bottom,
      16 + mediaPadding.bottom,
    );
  });
}
