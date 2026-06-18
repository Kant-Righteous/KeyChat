import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/providers/presentation/providers_page.dart';

void main() {
  testWidgets('ProvidersPage shows title, empty state and add button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProvidersPage(),
      ),
    );

    expect(find.text('Providers'), findsOneWidget);
    expect(find.text('No providers configured'), findsOneWidget);
    expect(find.text('Add Provider'), findsOneWidget);
  });
}
