import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/app/app.dart';
import '../features/settings/data/fake_locale_service.dart';

void main() {
  group('KeyChatApp startup', () {
    testWidgets('locale load runs only once', (WidgetTester tester) async {
      final fakeService = FakeLocaleService();
      await tester.pumpWidget(KeyChatApp(localeService: fakeService));
      await tester.pump();

      expect(fakeService.loadCallCount, 1);
    });

    testWidgets('shows Chinese UI after successful load',
        (WidgetTester tester) async {
      await tester.pumpWidget(KeyChatApp(localeService: FakeLocaleService()));
      await tester.pump();
      await tester.pump();

      // After load completes, should show Chinese UI
      expect(find.text('聊天'), findsOneWidget);
    });

    testWidgets('shows English UI when saved locale is English',
        (WidgetTester tester) async {
      await tester.pumpWidget(KeyChatApp(
          localeService: FakeLocaleService(initialLocale: const Locale('en'))));
      await tester.pump();
      await tester.pump();

      expect(find.text('Chat'), findsOneWidget);
    });

    testWidgets('falls back to Chinese on load failure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          KeyChatApp(localeService: FakeLocaleService(shouldFail: true)));
      await tester.pump();
      await tester.pump();

      // Should fall back to Chinese
      expect(find.text('聊天'), findsOneWidget);
    });

    testWidgets('does not stay on splash after failure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
          KeyChatApp(localeService: FakeLocaleService(shouldFail: true)));
      await tester.pump();
      await tester.pump();

      // Should have moved past splash
      expect(find.text('正在初始化…'), findsNothing);
    });
  });
}
