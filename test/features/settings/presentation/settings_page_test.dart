import 'package:flutter_test/flutter_test.dart';
import '../../../test_helpers.dart';
import 'package:keychat/features/settings/presentation/settings_page.dart';
import 'package:keychat/features/settings/presentation/usage_guide_page.dart';

void main() {
  testWidgets('SettingsPage shows title and setting items',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(
        home: SettingsPage(onLocaleChanged: (locale) {}),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('About KeyChat'), findsOneWidget);
    expect(find.text('Appearance'), findsNothing);
    expect(find.text('Privacy'), findsNothing);
  });

  testWidgets('UsageGuidePage shows the concise English guide',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestApp(home: const UsageGuidePage()),
    );

    expect(find.text('Quick Start'), findsOneWidget);
    expect(find.text('Configure a Provider'), findsOneWidget);
    expect(find.textContaining('Kimi, MiMo, GLM, Gemini, or Qwen'),
        findsOneWidget);
    expect(
        find.textContaining('does not save the configuration'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Chat and Agents'), 300);
    expect(find.text('Chat and Agents'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Security Tips'), 200);
    expect(find.text('Security Tips'), findsOneWidget);
  });

  testWidgets('UsageGuidePage shows the concise Chinese guide',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildTestAppZh(home: const UsageGuidePage()),
    );

    expect(find.text('快速开始'), findsOneWidget);
    expect(find.text('配置提供商'), findsOneWidget);
    expect(find.textContaining('Kimi、MiMo、GLM、Gemini、Qwen'), findsOneWidget);
    expect(find.textContaining('测试连接不会自动保存配置'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('聊天与智能体'), 300);
    expect(find.text('聊天与智能体'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('安全提示'), 200);
    expect(find.text('安全提示'), findsOneWidget);
  });
}
