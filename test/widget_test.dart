import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/app/app.dart';

void main() {
  testWidgets('KeyChatApp shows Chat page by default',
      (WidgetTester tester) async {
    await tester.pumpWidget(const KeyChatApp());

    expect(find.text('KeyChat'), findsOneWidget);
    expect(find.text('No conversations yet'), findsOneWidget);
  });

  testWidgets('KeyChatApp navigates between pages',
      (WidgetTester tester) async {
    await tester.pumpWidget(const KeyChatApp());

    // Tap Providers tab
    await tester.tap(find.text('Providers'));
    await tester.pumpAndSettle();
    expect(find.text('OpenAI'), findsOneWidget);

    // Tap Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);

    // Tap Chat tab
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    expect(find.text('No conversations yet'), findsOneWidget);
  });
}
