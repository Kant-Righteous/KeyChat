import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/agents/domain/agent_profile.dart';
import 'package:keychat/features/agents/presentation/agent_edit_page.dart';
import '../../../test_helpers.dart';

void main() {
  group('AgentEditPage', () {
    testWidgets('shows create form for new agent', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestAppZh(
        home: const AgentEditPage(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('创建智能体'), findsOneWidget);
      expect(find.text('名称'), findsOneWidget);
      expect(find.text('描述（可选）'), findsOneWidget);
      expect(find.text('系统提示词'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
    });

    testWidgets('shows edit form for existing agent',
        (WidgetTester tester) async {
      final agent = AgentProfileData(
        id: 'test_id',
        name: 'Test Agent',
        description: 'Test description',
        systemPrompt: 'Test system prompt',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      await tester.pumpWidget(buildTestAppZh(
        home: AgentEditPage(agent: agent),
      ));
      await tester.pumpAndSettle();

      expect(find.text('编辑智能体'), findsOneWidget);
      expect(find.text('Test Agent'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
    });

    testWidgets('validates empty name', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestAppZh(
        home: const AgentEditPage(),
      ));
      await tester.pumpAndSettle();

      // Try to save without entering name
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('名称不能为空'), findsOneWidget);
    });

    testWidgets('validates empty system prompt', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestAppZh(
        home: const AgentEditPage(),
      ));
      await tester.pumpAndSettle();

      // Enter name but not system prompt
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称'),
        'Test Agent',
      );

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('系统提示词不能为空'), findsOneWidget);
    });

    testWidgets('returns AgentProfileData on valid save',
        (WidgetTester tester) async {
      AgentProfileData? returnedAgent;

      await tester.pumpWidget(buildTestAppZh(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returnedAgent = await Navigator.push<AgentProfileData>(
                context,
                MaterialPageRoute(
                  builder: (context) => const AgentEditPage(),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open the edit page
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Fill in the form
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称'),
        'Test Agent',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '系统提示词'),
        'Test system prompt',
      );

      // Save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(returnedAgent, isNotNull);
      expect(returnedAgent!.name, 'Test Agent');
      expect(returnedAgent!.systemPrompt, 'Test system prompt');
    });

    testWidgets('does not save when cancelled', (WidgetTester tester) async {
      AgentProfileData? returnedAgent;

      await tester.pumpWidget(buildTestAppZh(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returnedAgent = await Navigator.push<AgentProfileData>(
                context,
                MaterialPageRoute(
                  builder: (context) => const AgentEditPage(),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open the edit page
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Go back without saving
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(returnedAgent, isNull);
    });

    testWidgets('creates unique id for new agent', (WidgetTester tester) async {
      AgentProfileData? agent1;
      AgentProfileData? agent2;

      await tester.pumpWidget(buildTestAppZh(
        home: Builder(
          builder: (context) => Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  agent1 = await Navigator.push<AgentProfileData>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgentEditPage(),
                    ),
                  );
                },
                child: const Text('Create 1'),
              ),
              ElevatedButton(
                onPressed: () async {
                  agent2 = await Navigator.push<AgentProfileData>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgentEditPage(),
                    ),
                  );
                },
                child: const Text('Create 2'),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Create first agent
      await tester.tap(find.text('Create 1'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称'),
        'Agent 1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '系统提示词'),
        'Prompt 1',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Create second agent
      await tester.tap(find.text('Create 2'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称'),
        'Agent 2',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '系统提示词'),
        'Prompt 2',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(agent1, isNotNull);
      expect(agent2, isNotNull);
      expect(agent1!.id, isNot(equals(agent2!.id)));
    });

    testWidgets('preserves id when editing', (WidgetTester tester) async {
      final originalAgent = AgentProfileData(
        id: 'original_id',
        name: 'Original',
        systemPrompt: 'Original prompt',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      AgentProfileData? returnedAgent;

      await tester.pumpWidget(buildTestAppZh(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returnedAgent = await Navigator.push<AgentProfileData>(
                context,
                MaterialPageRoute(
                  builder: (context) => AgentEditPage(agent: originalAgent),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Open edit page
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Modify name
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称'),
        'Updated',
      );

      // Save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(returnedAgent, isNotNull);
      expect(returnedAgent!.id, 'original_id');
      expect(returnedAgent!.name, 'Updated');
    });

    testWidgets('description is optional', (WidgetTester tester) async {
      AgentProfileData? returnedAgent;

      await tester.pumpWidget(buildTestAppZh(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returnedAgent = await Navigator.push<AgentProfileData>(
                context,
                MaterialPageRoute(
                  builder: (context) => const AgentEditPage(),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Fill name and system prompt only
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称'),
        'Test Agent',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '系统提示词'),
        'Test prompt',
      );

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(returnedAgent, isNotNull);
      expect(returnedAgent!.description, isNull);
    });
  });
}
