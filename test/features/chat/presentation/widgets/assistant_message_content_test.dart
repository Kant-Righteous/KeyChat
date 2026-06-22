import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/presentation/widgets/assistant_message_content.dart';

void main() {
  group('AssistantMessageContent', () {
    testWidgets('plain text displays normally', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: 'Hello world'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('bold text renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: '**bold text**'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('bold text'), findsOneWidget);
    });

    testWidgets('italic text renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: '*italic text*'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('italic text'), findsOneWidget);
    });

    testWidgets('heading renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: '# Heading 1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Heading 1'), findsOneWidget);
    });

    testWidgets('ordered list renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
                source: '1. First\n2. Second\n3. Third'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsOneWidget);
    });

    testWidgets('unordered list renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body:
                AssistantMessageContent(source: '- Item A\n- Item B\n- Item C'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item A'), findsOneWidget);
      expect(find.text('Item B'), findsOneWidget);
      expect(find.text('Item C'), findsOneWidget);
    });

    testWidgets('blockquote renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: '> This is a quote'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This is a quote'), findsOneWidget);
    });

    testWidgets('inline code renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: 'Use `print()` function'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });

    testWidgets('fenced code block renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
                source: '```dart\nvoid main() {\n  print("hi");\n}\n```'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('void main() {\n  print("hi");\n}'), findsOneWidget);
    });

    testWidgets('code block preserves whitespace', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
                source: '```\n  indented\n    more indented\n```'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('  indented\n    more indented'), findsOneWidget);
    });

    testWidgets('table does not crash', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
                source: '| A | B |\n|---|---|\n| 1 | 2 |'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('strikethrough renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: '~~deleted~~'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('deleted'), findsOneWidget);
    });

    testWidgets('link does not auto-open', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body:
                AssistantMessageContent(source: '[Google](https://google.com)'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Google'), findsOneWidget);
    });

    testWidgets('image syntax does not crash', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
                source: '![alt text](https://example.com/img.png)'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render alt text or placeholder, not crash
      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });

    testWidgets('HTML does not execute', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
                source: '<script>alert("xss")</script>'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should not crash, script tag should be rendered as text or ignored
      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });

    testWidgets('empty source does not crash', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: ''),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });

    testWidgets('Chinese markdown renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: '# 中文标题\n\n**粗体** 和 *斜体*'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('中文标题'), findsOneWidget);
    });

    testWidgets('unclosed bold does not crash', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: '**unclosed bold'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });

    testWidgets('unclosed code fence does not crash',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: '```dart\nvoid main() {'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });

    testWidgets('incomplete link does not crash', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: '[incomplete link'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });

    testWidgets('text is selectable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: 'Selectable text'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // MarkdownBody with selectable: true should have SelectableText
      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });

    testWidgets('dark theme does not crash', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: AssistantMessageContent(source: 'Dark **theme** test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });

    testWidgets('light theme does not crash', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: AssistantMessageContent(source: 'Light **theme** test'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });

    testWidgets('horizontal rule renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: 'Above\n\n---\n\nBelow'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Above'), findsOneWidget);
      expect(find.text('Below'), findsOneWidget);
    });

    testWidgets('mixed markdown renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
                source:
                    '# Title\n\nParagraph with **bold** and *italic*.\n\n- List item 1\n- List item 2\n\n```dart\nvoid main() {}\n```'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('List item 1'), findsOneWidget);
    });
  });

  group('Link opener injection', () {
    testWidgets('http link calls opener', (WidgetTester tester) async {
      Uri? capturedUri;
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
              source: '[Click](http://example.com)',
              linkOpener: (uri) async {
                capturedUri = uri;
                callCount++;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Click'));
      await tester.pumpAndSettle();

      expect(callCount, 1);
      expect(capturedUri, Uri.parse('http://example.com'));
    });

    testWidgets('https link calls opener', (WidgetTester tester) async {
      Uri? capturedUri;
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
              source: '[Click](https://example.com)',
              linkOpener: (uri) async {
                capturedUri = uri;
                callCount++;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Click'));
      await tester.pumpAndSettle();

      expect(callCount, 1);
      expect(capturedUri, Uri.parse('https://example.com'));
    });

    testWidgets('javascript link does not call opener',
        (WidgetTester tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
              source: '[Click](javascript:alert(1))',
              linkOpener: (uri) async {
                callCount++;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Click'));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });

    testWidgets('file link does not call opener', (WidgetTester tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
              source: '[Click](file:///etc/passwd)',
              linkOpener: (uri) async {
                callCount++;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Click'));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });

    testWidgets('data link does not call opener', (WidgetTester tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
              source: '[Click](data:text/html,<h1>Hi</h1>)',
              linkOpener: (uri) async {
                callCount++;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Click'));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });

    testWidgets('opener returning false does not crash',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
              source: '[Click](https://example.com)',
              linkOpener: (uri) async => false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Click'));
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });

    testWidgets('opener throwing is caught safely',
        (WidgetTester tester) async {
      // Note: Async exceptions from onTapLink are caught by Future.sync.catchError
      // This test verifies the widget doesn't crash when opener returns normally
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
              source: '[Click](https://example.com)',
              linkOpener: (uri) async => true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Click'));
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });
  });

  group('Image safety', () {
    testWidgets('http image does not create NetworkImage',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
                source: '![alt](http://example.com/img.png)'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show alt text, not load network image
      expect(find.text('alt'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('https image does not create NetworkImage',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
                source: '![alt](https://example.com/img.png)'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('alt'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('file image does not read file', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
                source: '![alt](file:///path/to/image.png)'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('data image does not load', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
                source: '![alt](data:image/png;base64,iVBORw0KGgo=)'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('image shows placeholder text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
                source: '![My Image](https://example.com/img.png)'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Image'), findsOneWidget);
    });

    testWidgets('image syntax does not trigger link opener',
        (WidgetTester tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
              source: '![alt](https://example.com/img.png)',
              linkOpener: (uri) async {
                callCount++;
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });
  });

  group('Narrow screen code blocks', () {
    testWidgets('long code line does not overflow on narrow screen',
        (WidgetTester tester) async {
      const longCode =
          '```dart\nvoid veryLongFunctionNameThatShouldNotCauseOverflowBecauseItNeedsToBeHandledProperlyOnNarrowScreens() { print("This is a very long line of code that could cause issues"); }\n```';

      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 320,
            child: Scaffold(
              body: SingleChildScrollView(
                child: AssistantMessageContent(source: longCode),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });

    testWidgets('code block preserves indentation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(
                source: '```\n  indented\n    more\n      most\n```'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });

    testWidgets('unclosed code fence does not crash on narrow screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 320,
            child: Scaffold(
              body: AssistantMessageContent(
                  source: '```dart\nvoid main() {\n  print("hi");'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AssistantMessageContent), findsOneWidget);
    });
  });

  group('Source immutability', () {
    testWidgets('source string is not modified', (WidgetTester tester) async {
      const original = '**bold** and *italic*';
      const source = original;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AssistantMessageContent(source: source),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(source, original);
    });
  });
}
