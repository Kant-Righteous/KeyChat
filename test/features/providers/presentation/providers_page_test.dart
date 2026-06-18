import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/presentation/providers_page.dart';
import 'package:keychat/features/providers/presentation/provider_config_page.dart';

void main() {
  testWidgets('ProvidersPage shows 4 provider presets',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProvidersPage(),
      ),
    );

    expect(find.text('Providers'), findsOneWidget);
    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('DeepSeek'), findsOneWidget);
    expect(find.text('OpenRouter'), findsOneWidget);
    expect(find.text('Custom Provider'), findsOneWidget);
  });

  testWidgets('Tapping OpenAI opens config page', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProvidersPage(),
      ),
    );

    await tester.tap(find.text('OpenAI'));
    await tester.pumpAndSettle();

    expect(find.byType(ProviderConfigPage), findsOneWidget);
    expect(find.text('OpenAI'), findsWidgets);
  });
}
