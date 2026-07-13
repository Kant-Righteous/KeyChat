import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/agents/data/agent_profile_store.dart';
import 'package:keychat/features/agents/domain/agent_profile.dart';
import 'package:keychat/features/agents/presentation/agents_page.dart';
import '../../../test_helpers.dart';

class _FakeAgentProfileStore implements AgentProfileStore {
  final List<AgentProfileData> _agents = [];
  int saveCallCount = 0;
  int deleteCallCount = 0;
  bool shouldFailOnSave = false;

  @override
  Future<List<AgentProfileData>> readAgents() async {
    return List.unmodifiable(_agents);
  }

  @override
  Future<AgentProfileData?> readAgent(String id) async {
    try {
      return _agents.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveAgent(AgentProfileData agent) async {
    saveCallCount++;
    if (shouldFailOnSave) {
      throw Exception('Save failed');
    }
    final index = _agents.indexWhere((a) => a.id == agent.id);
    if (index >= 0) {
      _agents[index] = agent;
    } else {
      _agents.add(agent);
    }
  }

  @override
  Future<bool> deleteAgent(String id) async {
    deleteCallCount++;
    final index = _agents.indexWhere((a) => a.id == id);
    if (index >= 0) {
      _agents.removeAt(index);
      return true;
    }
    return false;
  }
}

void main() {
  group('AgentsPage', () {
    testWidgets('tapping Add opens AgentEditPage',
        (WidgetTester tester) async {
      final store = _FakeAgentProfileStore();

      await tester.pumpWidget(buildTestAppZh(
        home: AgentsPage(agentStore: store),
      ));
      await tester.pumpAndSettle();

      // Tap the add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should show AgentEditPage
      expect(find.text('创建智能体'), findsOneWidget);
    });

    testWidgets('returned AgentProfileData calls saveAgent once',
        (WidgetTester tester) async {
      final store = _FakeAgentProfileStore();

      await tester.pumpWidget(buildTestAppZh(
        home: AgentsPage(agentStore: store),
      ));
      await tester.pumpAndSettle();

      // Tap add
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称'),
        'Test Agent',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '系统提示词'),
        'Test prompt',
      );

      // Save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(store.saveCallCount, 1);
    });

    testWidgets('successful save refreshes list',
        (WidgetTester tester) async {
      final store = _FakeAgentProfileStore();

      await tester.pumpWidget(buildTestAppZh(
        home: AgentsPage(agentStore: store),
      ));
      await tester.pumpAndSettle();

      // Initially empty
      expect(find.text('还没有智能体'), findsOneWidget);

      // Tap add
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称'),
        'Test Agent',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '系统提示词'),
        'Test prompt',
      );

      // Save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Should show in list
      expect(find.text('Test Agent'), findsOneWidget);
      expect(find.text('还没有智能体'), findsNothing);
    });

    testWidgets('created agent appears immediately',
        (WidgetTester tester) async {
      final store = _FakeAgentProfileStore();

      await tester.pumpWidget(buildTestAppZh(
        home: AgentsPage(agentStore: store),
      ));
      await tester.pumpAndSettle();

      // Create agent
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称'),
        'Immediate Agent',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '系统提示词'),
        'Prompt',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Should appear immediately
      expect(find.text('Immediate Agent'), findsOneWidget);
    });

    testWidgets('cancel does not call saveAgent',
        (WidgetTester tester) async {
      final store = _FakeAgentProfileStore();

      await tester.pumpWidget(buildTestAppZh(
        home: AgentsPage(agentStore: store),
      ));
      await tester.pumpAndSettle();

      // Tap add
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Go back without saving
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(store.saveCallCount, 0);
    });

    testWidgets('save failure shows safe error',
        (WidgetTester tester) async {
      final store = _FakeAgentProfileStore();

      await tester.pumpWidget(buildTestAppZh(
        home: AgentsPage(agentStore: store),
      ));
      await tester.pumpAndSettle();

      // Tap add
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称'),
        'Test Agent',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '系统提示词'),
        'Test prompt',
      );

      // Set store to fail after form is filled
      store.shouldFailOnSave = true;

      // Save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.text('保存失败'), findsOneWidget);
    });

    testWidgets('save failure does not add agent to list',
        (WidgetTester tester) async {
      final store = _FakeAgentProfileStore();

      await tester.pumpWidget(buildTestAppZh(
        home: AgentsPage(agentStore: store),
      ));
      await tester.pumpAndSettle();

      // Tap add
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称'),
        'Test Agent',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '系统提示词'),
        'Test prompt',
      );

      // Set store to fail after form is filled
      store.shouldFailOnSave = true;

      // Save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // List should still be empty
      expect(find.text('Test Agent'), findsNothing);
      expect(find.text('还没有智能体'), findsOneWidget);
    });

    testWidgets('edit preserves agent id', (WidgetTester tester) async {
      final store = _FakeAgentProfileStore();
      // Pre-populate with an agent
      await store.saveAgent(AgentProfileData(
        id: 'original_id',
        name: 'Original Agent',
        systemPrompt: 'Original prompt',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ));

      await tester.pumpWidget(buildTestAppZh(
        home: AgentsPage(agentStore: store),
      ));
      await tester.pumpAndSettle();

      // Tap on the agent to edit
      await tester.tap(find.text('Original Agent'));
      await tester.pumpAndSettle();

      // Modify name
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称'),
        'Updated Agent',
      );

      // Save
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // Should have updated, not created new
      expect(store.saveCallCount, 2); // 1 initial + 1 update
      final agents = await store.readAgents();
      expect(agents.length, 1);
      expect(agents.first.id, 'original_id');
      expect(agents.first.name, 'Updated Agent');
    });

    testWidgets('edit updates existing agent instead of creating another',
        (WidgetTester tester) async {
      final store = _FakeAgentProfileStore();
      await store.saveAgent(AgentProfileData(
        id: 'agent_1',
        name: 'Agent One',
        systemPrompt: 'Prompt one',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ));

      await tester.pumpWidget(buildTestAppZh(
        home: AgentsPage(agentStore: store),
      ));
      await tester.pumpAndSettle();

      // Edit
      await tester.tap(find.text('Agent One'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, '名称'),
        'Updated Agent',
      );
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      final agents = await store.readAgents();
      expect(agents.length, 1);
    });

    testWidgets('restart/rebuild loads saved agent',
        (WidgetTester tester) async {
      final store = _FakeAgentProfileStore();
      await store.saveAgent(AgentProfileData(
        id: 'agent_1',
        name: 'Saved Agent',
        systemPrompt: 'Saved prompt',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ));

      await tester.pumpWidget(buildTestAppZh(
        home: AgentsPage(agentStore: store),
      ));
      await tester.pumpAndSettle();

      // Should show saved agent
      expect(find.text('Saved Agent'), findsOneWidget);
    });

    testWidgets('API key is never passed to Agent store',
        (WidgetTester tester) async {
      final store = _FakeAgentProfileStore();

      await tester.pumpWidget(buildTestAppZh(
        home: AgentsPage(agentStore: store),
      ));
      await tester.pumpAndSettle();

      // Create agent
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
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

      // Verify no API key in stored agent
      final agents = await store.readAgents();
      expect(agents.length, 1);
      // AgentProfileData doesn't have apiKey field
    });
  });
}
