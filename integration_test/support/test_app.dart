import 'package:flutter/material.dart';
import 'package:keychat/features/agents/data/agent_profile_store.dart';
import 'package:keychat/features/agents/presentation/agents_page.dart';
import 'package:keychat/features/chat/data/chat_client_resolver.dart';
import 'package:keychat/features/chat/data/chat_history_store.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/providers/data/api_key_store.dart';
import 'package:keychat/features/providers/data/connection_tester_resolver.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';
import 'package:keychat/features/providers/presentation/providers_page.dart';
import 'package:keychat/features/settings/presentation/settings_page.dart';
import 'package:keychat/l10n/generated/app_localizations.dart';

class TestAppShell extends StatefulWidget {
  final ApiKeyStore apiKeyStore;
  final ProviderConfigStore configStore;
  final ChatHistoryStore historyStore;
  final ChatClientResolver chatClientResolver;
  final ConnectionTesterResolver connectionTesterResolver;
  final AgentProfileStore agentStore;
  final void Function(Locale)? onLocaleChanged;

  const TestAppShell({
    super.key,
    required this.apiKeyStore,
    required this.configStore,
    required this.historyStore,
    required this.chatClientResolver,
    required this.connectionTesterResolver,
    required this.agentStore,
    this.onLocaleChanged,
  });

  @override
  State<TestAppShell> createState() => _TestAppShellState();
}

class _TestAppShellState extends State<TestAppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pages = [
      ChatPage(
        chatClientResolver: widget.chatClientResolver,
        apiKeyStore: widget.apiKeyStore,
        configStore: widget.configStore,
        historyStore: widget.historyStore,
        agentStore: widget.agentStore,
      ),
      ProvidersPage(
        apiKeyStore: widget.apiKeyStore,
        configStore: widget.configStore,
        connectionTesterResolver: widget.connectionTesterResolver,
      ),
      AgentsPage(agentStore: widget.agentStore),
      SettingsPage(onLocaleChanged: widget.onLocaleChanged ?? (locale) {}),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_outlined),
            selectedIcon: const Icon(Icons.chat),
            label: l10n.chat,
          ),
          NavigationDestination(
            icon: const Icon(Icons.cloud_outlined),
            selectedIcon: const Icon(Icons.cloud),
            label: l10n.providers,
          ),
          NavigationDestination(
            icon: const Icon(Icons.smart_toy_outlined),
            selectedIcon: const Icon(Icons.smart_toy),
            label: l10n.agents,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}
