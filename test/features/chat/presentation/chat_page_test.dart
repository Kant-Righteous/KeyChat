import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';

void main() {
  testWidgets('ChatPage shows KeyChat title and empty state',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChatPage(),
      ),
    );

    expect(find.text('KeyChat'), findsOneWidget);
    expect(find.text('No conversations yet'), findsOneWidget);
  });
}
