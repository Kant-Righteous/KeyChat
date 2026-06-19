import 'package:flutter/material.dart';
import 'package:keychat/features/chat/data/dio_chat_completion_client.dart';
import 'package:keychat/features/chat/data/drift_chat_history_store.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/providers/data/dio_provider_connection_tester.dart';
import 'package:keychat/features/providers/data/drift/app_database.dart';
import 'package:keychat/features/providers/data/drift/drift_provider_config_store.dart';
import 'package:keychat/features/providers/data/secure_api_key_store.dart';
import 'package:keychat/features/providers/presentation/providers_page.dart';
import 'package:keychat/features/settings/presentation/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late final SecureApiKeyStore _apiKeyStore;
  late final AppDatabase _database;
  late final DriftProviderConfigStore _configStore;
  late final DioProviderConnectionTester _connectionTester;
  late final DioChatCompletionClient _chatClient;
  late final DriftChatHistoryStore _historyStore;

  @override
  void initState() {
    super.initState();
    _apiKeyStore = SecureApiKeyStore();
    _database = AppDatabase();
    _configStore = DriftProviderConfigStore(_database);
    _connectionTester = DioProviderConnectionTester();
    _chatClient = DioChatCompletionClient();
    _historyStore = DriftChatHistoryStore(_database);
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ChatPage(
        chatClient: _chatClient,
        apiKeyStore: _apiKeyStore,
        configStore: _configStore,
        historyStore: _historyStore,
      ),
      ProvidersPage(
        apiKeyStore: _apiKeyStore,
        configStore: _configStore,
        connectionTester: _connectionTester,
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
