import 'package:flutter/material.dart';
import 'package:keychat/features/agents/data/drift_agent_profile_store.dart';
import 'package:keychat/features/agents/presentation/agents_page.dart';
import 'package:keychat/features/chat/application/generation_keep_alive.dart';
import 'package:keychat/features/chat/data/chat_client_resolver.dart';
import 'package:keychat/features/chat/data/dio_chat_completion_client.dart';
import 'package:keychat/features/chat/data/drift_chat_history_store.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/providers/data/connection_tester_resolver.dart';
import 'package:keychat/features/providers/data/dio_provider_connection_tester.dart';
import 'package:keychat/features/providers/data/drift/app_database.dart';
import 'package:keychat/features/providers/data/drift/drift_provider_config_store.dart';
import 'package:keychat/features/providers/data/drift/drift_model_attachment_capability_store.dart';
import 'package:keychat/features/providers/data/secure_api_key_store.dart';
import 'package:keychat/features/providers/presentation/providers_page.dart';
import 'package:keychat/features/settings/presentation/settings_page.dart';
import 'package:keychat/l10n/generated/app_localizations.dart';

class AppShell extends StatefulWidget {
  final void Function(Locale) onLocaleChanged;

  const AppShell({super.key, required this.onLocaleChanged});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late final SecureApiKeyStore _apiKeyStore;
  late final AppDatabase _database;
  late final DriftProviderConfigStore _configStore;
  late final DriftModelAttachmentCapabilityStore _modelCapabilityStore;
  late final DioProviderConnectionTester _connectionTester;
  late final DioChatCompletionClient _chatClient;
  late final DriftChatHistoryStore _historyStore;
  late final DefaultChatClientResolver _chatClientResolver;
  late final DefaultConnectionTesterResolver _connectionTesterResolver;
  late final DriftAgentProfileStore _agentStore;
  late final AndroidGenerationKeepAlive _generationKeepAlive;

  @override
  void initState() {
    super.initState();
    _apiKeyStore = SecureApiKeyStore();
    _database = AppDatabase();
    _configStore = DriftProviderConfigStore(_database);
    _modelCapabilityStore = DriftModelAttachmentCapabilityStore(_database);
    _connectionTester = DioProviderConnectionTester();
    _chatClient = DioChatCompletionClient();
    _historyStore = DriftChatHistoryStore(_database);
    _chatClientResolver = DefaultChatClientResolver(
      openAiCompatibleClient: _chatClient,
    );
    _connectionTesterResolver = DefaultConnectionTesterResolver(
      openAiCompatibleTester: _connectionTester,
    );
    _agentStore = DriftAgentProfileStore(_database);
    _generationKeepAlive = AndroidGenerationKeepAlive();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pages = [
      ChatPage(
        chatClientResolver: _chatClientResolver,
        apiKeyStore: _apiKeyStore,
        configStore: _configStore,
        modelAttachmentCapabilityStore: _modelCapabilityStore,
        historyStore: _historyStore,
        agentStore: _agentStore,
        connectionTesterResolver: _connectionTesterResolver,
        generationKeepAlive: _generationKeepAlive,
      ),
      ProvidersPage(
        apiKeyStore: _apiKeyStore,
        configStore: _configStore,
        modelAttachmentCapabilityStore: _modelCapabilityStore,
        connectionTesterResolver: _connectionTesterResolver,
      ),
      AgentsPage(agentStore: _agentStore),
      SettingsPage(onLocaleChanged: widget.onLocaleChanged),
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
            tooltip: '',
          ),
          NavigationDestination(
            icon: const Icon(Icons.cloud_outlined),
            selectedIcon: const Icon(Icons.cloud),
            label: l10n.providers,
            tooltip: '',
          ),
          NavigationDestination(
            icon: const Icon(Icons.smart_toy_outlined),
            selectedIcon: const Icon(Icons.smart_toy),
            label: l10n.agents,
            tooltip: '',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settings,
            tooltip: '',
          ),
        ],
      ),
    );
  }
}
