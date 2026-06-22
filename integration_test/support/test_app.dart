import 'package:flutter/material.dart';
import 'package:keychat/features/chat/data/chat_client_resolver.dart';
import 'package:keychat/features/chat/data/chat_history_store.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/providers/data/api_key_store.dart';
import 'package:keychat/features/providers/data/connection_tester_resolver.dart';
import 'package:keychat/features/providers/data/provider_config_store.dart';
import 'package:keychat/features/providers/presentation/providers_page.dart';
import 'package:keychat/features/settings/presentation/settings_page.dart';

class TestAppShell extends StatefulWidget {
  final ApiKeyStore apiKeyStore;
  final ProviderConfigStore configStore;
  final ChatHistoryStore historyStore;
  final ChatClientResolver chatClientResolver;
  final ConnectionTesterResolver connectionTesterResolver;

  const TestAppShell({
    super.key,
    required this.apiKeyStore,
    required this.configStore,
    required this.historyStore,
    required this.chatClientResolver,
    required this.connectionTesterResolver,
  });

  @override
  State<TestAppShell> createState() => _TestAppShellState();
}

class _TestAppShellState extends State<TestAppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ChatPage(
        chatClientResolver: widget.chatClientResolver,
        apiKeyStore: widget.apiKeyStore,
        configStore: widget.configStore,
        historyStore: widget.historyStore,
      ),
      ProvidersPage(
        apiKeyStore: widget.apiKeyStore,
        configStore: widget.configStore,
        connectionTesterResolver: widget.connectionTesterResolver,
      ),
      const SettingsPage(),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Providers',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
