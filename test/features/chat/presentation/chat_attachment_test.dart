import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keychat/features/chat/data/attachment_delivery_store.dart';
import 'package:keychat/features/chat/data/attachment_picker.dart';
import 'package:keychat/features/chat/data/chat_attachment_request_encoder.dart';
import 'package:keychat/features/chat/data/chat_completion_client.dart';
import 'package:keychat/features/chat/data/local_attachment_file_store.dart';
import 'package:keychat/features/chat/domain/chat_attachment.dart';
import 'package:keychat/features/chat/domain/chat_conversation.dart';
import 'package:keychat/features/chat/domain/chat_context_builder.dart';
import 'package:keychat/features/chat/presentation/chat_page.dart';
import 'package:keychat/features/chat/presentation/widgets/attachment_preview.dart';
import 'package:keychat/features/providers/data/provider_config.dart';
import 'package:keychat/features/providers/data/model_attachment_capability_store.dart';
import 'package:keychat/features/providers/domain/model_attachment_capability.dart';
import 'package:keychat/features/providers/domain/provider_protocol.dart';

import '../../../test_helpers.dart';
import '../../agents/data/fake_agent_profile_store.dart';
import '../../providers/data/fake_api_key_store.dart';
import '../../providers/data/fake_provider_config_store.dart';
import '../data/fake_chat_client_resolver.dart';
import '../data/fake_chat_history_store.dart';

class _RecordingChatClient implements ChatCompletionClient {
  int streamCallCount = 0;
  List<ChatRequestMessage>? lastMessages;
  final List<List<ChatRequestMessage>> messageCalls = [];
  final List<List<ChatStreamEvent>> scriptedEventBatches = [];
  StreamController<ChatStreamEvent>? streamController;
  ChatStreamFailure? nextFailure;

  @override
  Future<ChatCompletionResult> complete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    ChatCancellationToken? cancellationToken,
  }) async {
    return const ChatCompletionResult.success(assistantContent: 'Done');
  }

  @override
  Stream<ChatStreamEvent> streamComplete({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<ChatRequestMessage> messages,
    ChatCancellationToken? cancellationToken,
  }) {
    streamCallCount++;
    lastMessages = messages;
    messageCalls.add(messages);
    if (streamController != null) return streamController!.stream;
    if (scriptedEventBatches.isNotEmpty) {
      return Stream.fromIterable(scriptedEventBatches.removeAt(0));
    }
    if (nextFailure != null) {
      return Stream.fromIterable([nextFailure!]);
    }
    return Stream.fromIterable(const [
      ChatStreamDelta('Done'),
      ChatStreamCompleted(),
    ]);
  }
}

class _FakeAttachmentPicker implements AttachmentPicker {
  AttachmentDraft? nextDraft;
  List<AttachmentDraft> nextDrafts = const [];

  @override
  Future<List<AttachmentDraft>> pick(ChatAttachmentKind kind) async {
    if (nextDrafts.isNotEmpty) return nextDrafts;
    return [if (nextDraft != null) nextDraft!];
  }
}

class _PassthroughAttachmentFileStore implements AttachmentFileStore {
  @override
  Future<ChatAttachment> persist({
    required AttachmentDraft draft,
    required String attachmentId,
    required String messageId,
    required String conversationId,
  }) async {
    return ChatAttachment(
      id: attachmentId,
      fileName: draft.fileName,
      mimeType: draft.mimeType,
      fileSize: draft.fileSize,
      localPath: draft.sourcePath,
      kind: draft.kind,
      messageId: messageId,
      conversationId: conversationId,
    );
  }
}

void main() {
  group('ChatPage attachments', () {
    late FakeApiKeyStore apiKeyStore;
    late FakeProviderConfigStore configStore;
    late _RecordingChatClient chatClient;
    late FakeChatHistoryStore historyStore;
    late _FakeAttachmentPicker picker;
    late InMemoryModelAttachmentCapabilityStore capabilityStore;

    setUp(() async {
      apiKeyStore = FakeApiKeyStore();
      configStore = FakeProviderConfigStore();
      chatClient = _RecordingChatClient();
      historyStore = FakeChatHistoryStore();
      picker = _FakeAttachmentPicker();
      capabilityStore = InMemoryModelAttachmentCapabilityStore();
      await apiKeyStore.saveKey('openai', 'test-key');
    });

    Future<void> pumpChat(
      WidgetTester tester, {
      bool supportsImages = true,
      bool supportsFiles = true,
      Locale locale = const Locale('en'),
      ChatContextBuilder? contextBuilder,
    }) async {
      await configStore.saveConfig(ProviderConfigData(
        providerId: 'openai',
        displayName: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        defaultModel: 'gpt-4o',
        protocol: ProviderProtocol.openAiCompatible,
        supportsImageInput: supportsImages,
        supportsFileInput: supportsFiles,
        updatedAt: DateTime(2024),
      ));
      await tester.pumpWidget(buildTestApp(
        locale: locale,
        home: ChatPage(
          chatClientResolver: FakeChatClientResolver(
            openAiCompatibleClient: chatClient,
          ),
          apiKeyStore: apiKeyStore,
          configStore: configStore,
          modelAttachmentCapabilityStore: capabilityStore,
          historyStore: historyStore,
          agentStore: FakeAgentProfileStore(),
          contextBuilder: contextBuilder,
          attachmentPicker: picker,
          attachmentFileStore: _PassthroughAttachmentFileStore(),
          attachmentRequestEncoder: ChatAttachmentRequestEncoder(
            bytesReader: (_) async => [1, 2, 3],
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> chooseAttachment(
      WidgetTester tester,
      AttachmentDraft draft,
      Key choiceKey,
    ) async {
      picker.nextDraft = draft;
      await tester.tap(find.byKey(const Key('attachment_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(choiceKey));
      await tester.pumpAndSettle();
    }

    Future<void> chooseAttachments(
      WidgetTester tester,
      List<AttachmentDraft> drafts,
      Key choiceKey,
    ) async {
      picker.nextDraft = null;
      picker.nextDrafts = drafts;
      await tester.tap(find.byKey(const Key('attachment_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(choiceKey));
      await tester.pumpAndSettle();
    }

    testWidgets('attachment icon is right of model selector and above send',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpChat(tester);

      final attachment = find.byKey(const Key('attachment_button'));
      final selector = find.byKey(const Key('model_selector'));
      final send = find.byTooltip('Send');
      expect(attachment, findsOneWidget);
      expect(find.byTooltip('Add attachment'), findsOneWidget);
      expect(tester.getSemantics(attachment).label, contains('Add attachment'));
      expect(tester.getTopLeft(attachment).dx,
          greaterThan(tester.getTopLeft(selector).dx));
      expect(tester.getTopLeft(attachment).dy,
          lessThan(tester.getTopLeft(send).dy));
      semantics.dispose();
    });

    testWidgets('shows image preview and removes pending attachment',
        (tester) async {
      await pumpChat(tester);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'assets/branding/keychat_icon.png',
          fileName: 'photo.png',
          mimeType: 'image/png',
          fileSize: 2048,
          kind: ChatAttachmentKind.image,
        ),
        const Key('choose_image_attachment'),
      );

      expect(find.byKey(const Key('pending_attachment_image')), findsOneWidget);
      expect(find.text('photo.png'), findsOneWidget);
      await tester.tap(find.byKey(const Key('remove_pending_attachment_0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pending_attachment_preview')), findsNothing);
    });

    testWidgets('selects removes and sends multiple images', (tester) async {
      await pumpChat(tester);
      await chooseAttachments(
        tester,
        const [
          AttachmentDraft(
            sourcePath: 'assets/branding/keychat_icon.png',
            fileName: 'first.png',
            mimeType: 'image/png',
            fileSize: 1200,
            kind: ChatAttachmentKind.image,
          ),
          AttachmentDraft(
            sourcePath: 'pubspec.lock',
            fileName: 'second.jpg',
            mimeType: 'image/jpeg',
            fileSize: 2400,
            kind: ChatAttachmentKind.image,
          ),
        ],
        const Key('choose_image_attachment'),
      );

      expect(find.byType(PendingAttachmentPreview), findsNWidgets(2));
      expect(find.text('first.png'), findsOneWidget);
      expect(find.text('second.jpg'), findsOneWidget);
      await tester.tap(find.byKey(const Key('remove_pending_attachment_0')));
      await tester.pumpAndSettle();
      expect(find.text('first.png'), findsNothing);
      expect(find.text('second.jpg'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'Describe it');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      expect(chatClient.lastMessages!.last.attachments, hasLength(1));
      expect(
        chatClient.lastMessages!.last.attachments.single.fileName,
        'second.jpg',
      );
      final messages = await historyStore.readMessages(
        historyStore.latestConversationId!,
      );
      expect(messages.first.attachments, hasLength(1));
      expect(messages.first.attachments.single.fileName, 'second.jpg');
    });

    testWidgets('limits one user message to five attachments', (tester) async {
      await pumpChat(tester);
      await chooseAttachments(
        tester,
        List.generate(
          6,
          (index) => AttachmentDraft(
            sourcePath: 'image_$index.png',
            fileName: 'image_$index.png',
            mimeType: 'image/png',
            fileSize: 1000,
            kind: ChatAttachmentKind.image,
          ),
        ),
        const Key('choose_image_attachment'),
      );

      expect(find.text('image_5.png'), findsNothing);
      final attachmentButton = tester.widget<IconButton>(find.descendant(
        of: find.byKey(const Key('attachment_button')).last,
        matching: find.byType(IconButton),
      ));
      expect(attachmentButton.onPressed, isNull);
      expect(
        find.text('You can attach up to 5 files per message.'),
        findsOneWidget,
      );
    });

    testWidgets('shows ordinary file card before sending', (tester) async {
      await pumpChat(tester);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'pubspec.yaml',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 1536,
          kind: ChatAttachmentKind.file,
        ),
        const Key('choose_file_attachment'),
      );

      expect(find.byKey(const Key('pending_attachment_file')), findsOneWidget);
      expect(find.text('notes.txt'), findsOneWidget);
      expect(find.textContaining('text/plain'), findsOneWidget);
      expect(find.textContaining('1.5 KiB'), findsOneWidget);
    });

    testWidgets('multimodal send keeps attachment in bubble and request',
        (tester) async {
      await pumpChat(tester);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'assets/branding/keychat_icon.png',
          fileName: 'photo.png',
          mimeType: 'image/png',
          fileSize: 2048,
          kind: ChatAttachmentKind.image,
        ),
        const Key('choose_image_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'Describe it');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('message_attachment_image')), findsOneWidget);
      expect(chatClient.streamCallCount, 1);
      expect(chatClient.lastMessages!.last.attachments, hasLength(1));
      expect(
        chatClient.lastMessages!.last.attachments.single.kind,
        ChatAttachmentKind.image,
      );
      final messages = await historyStore.readMessages(
        historyStore.latestConversationId!,
      );
      expect(messages.first.attachments, hasLength(1));
    });

    testWidgets('unknown model sends attachment despite legacy false flags',
        (tester) async {
      await pumpChat(tester, supportsImages: false, supportsFiles: false);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'pubspec.yaml',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 1536,
          kind: ChatAttachmentKind.file,
        ),
        const Key('choose_file_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'Summarize it');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      expect(find.text('Attachment may not be supported'), findsNothing);
      expect(chatClient.streamCallCount, 1);
      expect(chatClient.lastMessages!.last.attachments, hasLength(1));
      final messages = await historyStore.readMessages(
        historyStore.latestConversationId!,
      );
      expect(messages.first.attachments, hasLength(1));
    });

    testWidgets('known unsupported model still tries the current attachment',
        (tester) async {
      await capabilityStore.saveCapability(ModelAttachmentCapability(
        providerId: 'openai',
        modelId: 'gpt-4o',
        modality: ModelInputModality.file,
        status: AttachmentCapabilityStatus.unsupported,
        source: AttachmentCapabilitySource.manual,
        updatedAt: DateTime(2026),
      ));
      await pumpChat(tester, supportsImages: true, supportsFiles: true);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'pubspec.yaml',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 1536,
          kind: ChatAttachmentKind.file,
        ),
        const Key('choose_file_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'Summarize it');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      expect(find.text('Attachment may not be supported'), findsNothing);
      expect(chatClient.streamCallCount, 1);
      expect(chatClient.lastMessages!.last.attachments, hasLength(1));
      final messages = await historyStore.readMessages(
        historyStore.latestConversationId!,
      );
      expect(messages.first.attachments, hasLength(1));
    });

    testWidgets('attachment rejection records only the rejected attachment',
        (tester) async {
      chatClient.scriptedEventBatches.addAll([
        [
          const ChatStreamFailure(
            errorType: ChatCompletionErrorType.attachmentRejected,
            userMessage: 'Provider rejected attachment input',
            rejectedAttachmentKinds: {ChatAttachmentKind.file},
          ),
        ],
        const [ChatStreamDelta('Done'), ChatStreamCompleted()],
      ]);
      await pumpChat(tester, supportsImages: false, supportsFiles: false);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'pubspec.yaml',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 1536,
          kind: ChatAttachmentKind.file,
        ),
        const Key('choose_file_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'Summarize it');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('attachment_rejected_dialog')), findsOne);
      expect(find.text('Provider rejected the attachment'), findsOneWidget);
      expect(chatClient.streamCallCount, 1);
      await tester.tap(find.byKey(const Key('retry_without_attachments')));
      await tester.pumpAndSettle();

      expect(chatClient.streamCallCount, 2);
      expect(chatClient.messageCalls.first.last.attachments, hasLength(1));
      expect(chatClient.messageCalls.last.last.attachments, isEmpty);
      final learned = await capabilityStore.readCapability(
        providerId: 'openai',
        modelId: 'gpt-4o',
        modality: ModelInputModality.file,
        source: AttachmentCapabilitySource.detected,
      );
      expect(learned, isNull);
      final messages = await historyStore.readMessages(
        historyStore.latestConversationId!,
      );
      expect(messages.where((message) => message.role == ChatRole.user),
          hasLength(1));
      expect(messages.first.attachments, hasLength(1));
      expect(
        await historyStore.readStatus(
          attachmentId: messages.first.attachments.single.id,
          providerId: 'openai',
          modelId: 'gpt-4o',
        ),
        AttachmentDeliveryStatus.rejected,
      );
    });

    testWidgets('successful attachment request learns supported',
        (tester) async {
      await pumpChat(tester, supportsImages: false, supportsFiles: false);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'pubspec.yaml',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 1536,
          kind: ChatAttachmentKind.file,
        ),
        const Key('choose_file_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'Summarize it');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      final learned = await capabilityStore.readCapability(
        providerId: 'openai',
        modelId: 'gpt-4o',
        modality: ModelInputModality.file,
        source: AttachmentCapabilitySource.detected,
      );
      expect(learned?.status, AttachmentCapabilityStatus.supported);
    });

    testWidgets('trimmed historical attachment is not learned as sent',
        (tester) async {
      await _seedAttachmentConversation(
        historyStore,
        includeAssistant: true,
      );
      await pumpChat(
        tester,
        contextBuilder: ChatContextBuilder(maxEstimatedTokens: 5),
      );

      await tester.enterText(find.byType(TextField).last, 'Now');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      expect(
        chatClient.lastMessages!.expand((message) => message.attachments),
        isEmpty,
      );
      expect(
        await capabilityStore.readCapability(
          providerId: 'openai',
          modelId: 'gpt-4o',
          modality: ModelInputModality.file,
          source: AttachmentCapabilitySource.detected,
        ),
        isNull,
      );
    });

    testWidgets('cancelling attachment rejection does not learn unsupported',
        (tester) async {
      chatClient.scriptedEventBatches.add([
        const ChatStreamFailure(
          errorType: ChatCompletionErrorType.attachmentRejected,
          userMessage: 'Provider rejected attachment input',
          rejectedAttachmentKinds: {ChatAttachmentKind.file},
        ),
      ]);
      await pumpChat(tester);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'pubspec.yaml',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 1536,
          kind: ChatAttachmentKind.file,
        ),
        const Key('choose_file_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'Summarize it');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancel_attachment_retry')));
      await tester.pumpAndSettle();

      expect(chatClient.streamCallCount, 1);
      expect(
        await capabilityStore.readCapability(
          providerId: 'openai',
          modelId: 'gpt-4o',
          modality: ModelInputModality.file,
          source: AttachmentCapabilitySource.detected,
        ),
        isNull,
      );
    });

    testWidgets('rejected historical attachment does not block a later one',
        (tester) async {
      chatClient.scriptedEventBatches.addAll([
        [
          const ChatStreamFailure(
            errorType: ChatCompletionErrorType.attachmentRejected,
            userMessage: 'Provider rejected attachment input',
            rejectedAttachmentKinds: {ChatAttachmentKind.image},
          ),
        ],
        const [ChatStreamDelta('Done'), ChatStreamCompleted()],
      ]);
      await pumpChat(tester);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'assets/branding/keychat_icon.png',
          fileName: 'rejected.png',
          mimeType: 'image/png',
          fileSize: 1200,
          kind: ChatAttachmentKind.image,
        ),
        const Key('choose_image_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'First');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancel_attachment_retry')));
      await tester.pumpAndSettle();

      picker.nextDrafts = const [];
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'pubspec.lock',
          fileName: 'legal.jpg',
          mimeType: 'image/jpeg',
          fileSize: 2400,
          kind: ChatAttachmentKind.image,
        ),
        const Key('choose_image_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'Second');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      expect(chatClient.messageCalls, hasLength(2));
      final secondAttachments = chatClient.messageCalls.last
          .expand((message) => message.attachments)
          .toList();
      expect(secondAttachments, hasLength(1));
      expect(secondAttachments.single.fileName, 'legal.jpg');
      final messages = await historyStore.readMessages(
        historyStore.latestConversationId!,
      );
      expect(messages.where((message) => message.role == ChatRole.user),
          hasLength(2));
      expect(messages.first.attachments.single.fileName, 'rejected.png');
      expect(messages[1].attachments.single.fileName, 'legal.jpg');
    });

    testWidgets('rejected historical attachment does not block later text',
        (tester) async {
      chatClient.scriptedEventBatches.addAll([
        [
          const ChatStreamFailure(
            errorType: ChatCompletionErrorType.attachmentRejected,
            userMessage: 'Provider rejected attachment input',
            rejectedAttachmentKinds: {ChatAttachmentKind.image},
          ),
        ],
        const [ChatStreamDelta('Done'), ChatStreamCompleted()],
      ]);
      await pumpChat(tester);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'assets/branding/keychat_icon.png',
          fileName: 'rejected.png',
          mimeType: 'image/png',
          fileSize: 1200,
          kind: ChatAttachmentKind.image,
        ),
        const Key('choose_image_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'First');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancel_attachment_retry')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Continue normally');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      expect(chatClient.messageCalls, hasLength(2));
      expect(
        chatClient.messageCalls.last.expand((message) => message.attachments),
        isEmpty,
      );
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('failed text-only retry does not learn unsupported',
        (tester) async {
      chatClient.scriptedEventBatches.addAll([
        [
          const ChatStreamFailure(
            errorType: ChatCompletionErrorType.attachmentRejected,
            userMessage: 'Provider rejected attachment input',
            rejectedAttachmentKinds: {ChatAttachmentKind.file},
          ),
        ],
        [
          const ChatStreamFailure(
            errorType: ChatCompletionErrorType.serverError,
            userMessage: 'Provider server error',
          ),
        ],
      ]);
      await pumpChat(tester);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'pubspec.yaml',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 1536,
          kind: ChatAttachmentKind.file,
        ),
        const Key('choose_file_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'Summarize it');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('retry_without_attachments')));
      await tester.pumpAndSettle();

      expect(chatClient.streamCallCount, 2);
      expect(
        await capabilityStore.readCapability(
          providerId: 'openai',
          modelId: 'gpt-4o',
          modality: ModelInputModality.file,
          source: AttachmentCapabilitySource.detected,
        ),
        isNull,
      );
    });

    testWidgets('unrelated failure does not offer text-only retry',
        (tester) async {
      chatClient.nextFailure = const ChatStreamFailure(
        errorType: ChatCompletionErrorType.invalidResponse,
        userMessage: 'Invalid provider response',
      );
      await pumpChat(tester);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'pubspec.yaml',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 1536,
          kind: ChatAttachmentKind.file,
        ),
        const Key('choose_file_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'Summarize it');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('attachment_rejected_dialog')), findsNothing);
      expect(chatClient.streamCallCount, 1);
    });

    testWidgets('partial response rejection does not retry or learn',
        (tester) async {
      chatClient.scriptedEventBatches.add([
        const ChatStreamDelta('Partial'),
        const ChatStreamFailure(
          errorType: ChatCompletionErrorType.attachmentRejected,
          userMessage: 'Provider rejected attachment input',
          rejectedAttachmentKinds: {ChatAttachmentKind.file},
        ),
      ]);
      await pumpChat(tester);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'pubspec.yaml',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 1536,
          kind: ChatAttachmentKind.file,
        ),
        const Key('choose_file_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'Summarize it');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('attachment_rejected_dialog')), findsNothing);
      expect(chatClient.streamCallCount, 1);
      expect(
        await capabilityStore.readCapability(
          providerId: 'openai',
          modelId: 'gpt-4o',
          modality: ModelInputModality.file,
          source: AttachmentCapabilitySource.detected,
        ),
        isNull,
      );
    });

    testWidgets('restores attachment in a historical user bubble',
        (tester) async {
      await _seedAttachmentConversation(
        historyStore,
        includeAssistant: true,
      );
      await pumpChat(tester);

      expect(find.byKey(const Key('message_attachment_file')), findsOneWidget);
      expect(find.text('notes.txt'), findsOneWidget);
    });

    testWidgets('retry reuses original user attachment rules', (tester) async {
      await _seedAttachmentConversation(historyStore);
      await pumpChat(tester);

      await tester.tap(find.byTooltip('Retry'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(chatClient.lastMessages!.last.attachments, hasLength(1));
      expect(
        chatClient.lastMessages!.last.attachments.single.kind,
        ChatAttachmentKind.file,
      );
    });

    testWidgets(
        'retry falls back after attachment rejection without duplicate user',
        (tester) async {
      chatClient.scriptedEventBatches.addAll([
        [
          const ChatStreamFailure(
            errorType: ChatCompletionErrorType.attachmentRejected,
            userMessage: 'Provider rejected attachment input',
            rejectedAttachmentKinds: {ChatAttachmentKind.file},
          ),
        ],
        const [ChatStreamDelta('Done'), ChatStreamCompleted()],
      ]);
      await _seedAttachmentConversation(historyStore);
      await pumpChat(tester);

      await tester.tap(find.byTooltip('Retry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('retry_without_attachments')));
      await tester.pumpAndSettle();

      expect(chatClient.messageCalls, hasLength(2));
      expect(chatClient.messageCalls.first.last.attachments, hasLength(1));
      expect(chatClient.messageCalls.last.last.attachments, isEmpty);
      final messages = await historyStore.readMessages(
        historyStore.latestConversationId!,
      );
      expect(
        messages.where((message) => message.role == ChatRole.user),
        hasLength(1),
      );
      expect(messages.first.attachments, hasLength(1));
    });

    testWidgets('regenerate keeps original user attachment context',
        (tester) async {
      await _seedAttachmentConversation(
        historyStore,
        includeAssistant: true,
      );
      await pumpChat(tester);

      await tester.tap(find.byTooltip('Regenerate response'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(chatClient.lastMessages!.last.attachments, hasLength(1));
      expect(
        chatClient.lastMessages!.last.attachments.single.fileName,
        'notes.txt',
      );
    });

    testWidgets('regenerate falls back without losing attachment context',
        (tester) async {
      chatClient.scriptedEventBatches.addAll([
        [
          const ChatStreamFailure(
            errorType: ChatCompletionErrorType.attachmentRejected,
            userMessage: 'Provider rejected attachment input',
            rejectedAttachmentKinds: {ChatAttachmentKind.file},
          ),
        ],
        const [ChatStreamDelta('Done'), ChatStreamCompleted()],
      ]);
      await _seedAttachmentConversation(
        historyStore,
        includeAssistant: true,
      );
      await pumpChat(tester);

      await tester.tap(find.byTooltip('Regenerate response'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('retry_without_attachments')));
      await tester.pumpAndSettle();

      expect(chatClient.messageCalls, hasLength(2));
      expect(chatClient.messageCalls.first.last.attachments, hasLength(1));
      expect(chatClient.messageCalls.last.last.attachments, isEmpty);
      final messages = await historyStore.readMessages(
        historyStore.latestConversationId!,
      );
      expect(messages.first.attachments, hasLength(1));
      expect(
        messages.where((message) => message.role == ChatRole.assistant),
        hasLength(1),
      );
    });

    testWidgets('unsupported retry still tries the original attachment',
        (tester) async {
      await _seedAttachmentConversation(historyStore);
      await capabilityStore.saveCapability(ModelAttachmentCapability(
        providerId: 'openai',
        modelId: 'gpt-4o',
        modality: ModelInputModality.file,
        status: AttachmentCapabilityStatus.unsupported,
        source: AttachmentCapabilitySource.detected,
        updatedAt: DateTime(2026),
      ));
      await pumpChat(tester, supportsImages: false, supportsFiles: false);

      await tester.tap(find.byTooltip('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Attachment may not be supported'), findsNothing);
      expect(chatClient.streamCallCount, 1);
      expect(chatClient.lastMessages!.last.attachments, hasLength(1));
      final messages = await historyStore.readMessages(
        historyStore.latestConversationId!,
      );
      expect(messages.first.attachments, hasLength(1));
    });

    testWidgets('attachment button is disabled while generating',
        (tester) async {
      chatClient.streamController = StreamController<ChatStreamEvent>();
      await pumpChat(tester);
      await tester.enterText(find.byType(TextField).last, 'Wait');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump(const Duration(milliseconds: 200));

      final button = tester.widget<IconButton>(find.descendant(
        of: find.byKey(const Key('attachment_button')).last,
        matching: find.byType(IconButton),
      ));
      expect(button.onPressed, isNull);
      unawaited(chatClient.streamController!.close());
    });

    testWidgets(
        'stop keeps user message and attachment without empty assistant',
        (tester) async {
      chatClient.streamController = StreamController<ChatStreamEvent>();
      await pumpChat(tester);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'pubspec.yaml',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 1536,
          kind: ChatAttachmentKind.file,
        ),
        const Key('choose_file_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'Wait');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      await tester.tap(find.byTooltip('Stop generating'));
      await tester.pumpAndSettle();

      final messages = await historyStore.readMessages(
        historyStore.latestConversationId!,
      );
      expect(messages, hasLength(1));
      expect(messages.single.role, ChatRole.user);
      expect(messages.single.attachments, hasLength(1));
      unawaited(chatClient.streamController!.close());
    });

    testWidgets('failure keeps user attachment without empty assistant',
        (tester) async {
      chatClient.nextFailure = const ChatStreamFailure(
        errorType: ChatCompletionErrorType.serverError,
        userMessage: 'Provider server error',
      );
      await pumpChat(tester);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'pubspec.yaml',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 1536,
          kind: ChatAttachmentKind.file,
        ),
        const Key('choose_file_attachment'),
      );
      await tester.enterText(find.byType(TextField).last, 'Fail safely');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();

      final messages = await historyStore.readMessages(
        historyStore.latestConversationId!,
      );
      expect(messages, hasLength(1));
      expect(messages.single.role, ChatRole.user);
      expect(messages.single.attachments, hasLength(1));
    });

    testWidgets('new chat removes pending attachment', (tester) async {
      await pumpChat(tester);
      await chooseAttachment(
        tester,
        const AttachmentDraft(
          sourcePath: 'pubspec.yaml',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 1536,
          kind: ChatAttachmentKind.file,
        ),
        const Key('choose_file_attachment'),
      );
      expect(
          find.byKey(const Key('pending_attachment_preview')), findsOneWidget);

      await tester.tap(find.byTooltip('New Chat'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pending_attachment_preview')), findsNothing);
    });

    testWidgets('attachment labels switch to Chinese', (tester) async {
      await pumpChat(tester, locale: const Locale('zh'));
      expect(find.byTooltip('添加附件'), findsOneWidget);
      await tester.tap(find.byKey(const Key('attachment_button')));
      await tester.pumpAndSettle();
      expect(find.text('选择图片'), findsOneWidget);
      expect(find.text('选择文件'), findsOneWidget);
    });
  });
}

Future<void> _seedAttachmentConversation(
  FakeChatHistoryStore store, {
  bool includeAssistant = false,
}) async {
  final conversation = ChatConversation(
    id: 'conv_attachment_history',
    title: 'Attachment history',
    providerId: 'openai',
    model: 'gpt-4o',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
  await store.createConversationWithFirstMessage(
    conversation: conversation,
    firstMessage: ChatMessage(
      id: 'user_attachment_history',
      role: ChatRole.user,
      content: 'Read it',
      providerIdSnapshot: 'openai',
      providerNameSnapshot: 'OpenAI',
      modelIdSnapshot: 'gpt-4o',
      attachments: const [
        ChatAttachment(
          id: 'file_history',
          fileName: 'notes.txt',
          mimeType: 'text/plain',
          fileSize: 1536,
          localPath: 'pubspec.yaml',
          kind: ChatAttachmentKind.file,
          messageId: 'user_attachment_history',
          conversationId: 'conv_attachment_history',
        ),
      ],
      createdAt: DateTime(2024),
    ),
  );
  if (includeAssistant) {
    await store.appendMessage(
      conversationId: conversation.id,
      message: ChatMessage(
        id: 'assistant_attachment_history',
        role: ChatRole.assistant,
        content: 'Previous answer',
        providerIdSnapshot: 'openai',
        providerNameSnapshot: 'OpenAI',
        modelIdSnapshot: 'gpt-4o',
        createdAt: DateTime(2024, 1, 1, 0, 1),
      ),
    );
  }
}
