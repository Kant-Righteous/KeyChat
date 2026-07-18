# Attachment Capability Autodetection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Provider-level attachment gating with model-level automatic capability learning and a safe text-only retry after explicit attachment rejection.

**Architecture:** Add a model capability domain/store backed by Drift v7, with manual and detected records resolved independently for image and file inputs. Unknown capability sends attachments; the Dio client maps only explicit attachment rejection responses to a non-sensitive error enum; ChatPage retries the same generation target without attachments after confirmation and learns unsupported only when that retry succeeds.

**Tech Stack:** Flutter, Dart 3.6+, Material 3, Dio 5, Drift/SQLite, flutter_test.

## Global Constraints

- Android and iOS only; do not add Web, Windows, macOS, or Linux support.
- Keep attachment files in the App local documents directory and metadata in Drift; never store file bytes in SQLite.
- Never persist or log API keys, Base URLs in message snapshots, Authorization headers, raw request bodies, or raw response bodies.
- Do not add OCR, PDF/Word/Excel parsing, search, vectors, cloud file upload, batch attachment management, release signing, or Vivo device testing.
- Use one agent, the current branch, no worktree, and minimal focused changes.
- Every production behavior follows RED → GREEN → REFACTOR.

---

### Task 1: Model-level capability domain, store, and Drift v7

**Files:**
- Create: `lib/features/providers/domain/model_attachment_capability.dart`
- Create: `lib/features/providers/data/model_attachment_capability_store.dart`
- Create: `lib/features/providers/data/drift/drift_model_attachment_capability_store.dart`
- Modify: `lib/features/providers/data/drift/app_database.dart`
- Regenerate: `lib/features/providers/data/drift/app_database.g.dart`
- Create: `test/features/providers/data/model_attachment_capability_store_test.dart`
- Modify: `test/features/providers/data/drift_schema_test.dart`
- Modify: `test/features/providers/data/drift_migration_test.dart`

**Interfaces:**
- Produces `ModelInputModality`, `AttachmentCapabilityStatus`, `AttachmentCapabilitySource`, `ModelAttachmentCapability`, `ModelAttachmentCapabilityStore`, and an in-memory implementation.
- The storage key is Provider + model + modality + source, so detected and manual rows coexist.

- [ ] **Step 1: Write failing domain/store tests**

```dart
test('manual and detected capability records coexist', () async {
  final store = InMemoryModelAttachmentCapabilityStore();
  await store.saveCapability(detectedSupported);
  await store.saveCapability(manualUnsupported);

  expect(
    await store.readCapability(
      providerId: 'custom',
      modelId: 'vision-1',
      modality: ModelInputModality.image,
      source: AttachmentCapabilitySource.detected,
    ),
    detectedSupported,
  );
  expect(
    await store.readCapability(
      providerId: 'custom',
      modelId: 'vision-1',
      modality: ModelInputModality.image,
      source: AttachmentCapabilitySource.manual,
    ),
    manualUnsupported,
  );
});
```

Also test that deleting manual reveals but does not delete detected, and resetting detected records affects only the exact Provider/model.

- [ ] **Step 2: Run the new store test and verify RED**

Run: `flutter test test/features/providers/data/model_attachment_capability_store_test.dart`

Expected: compilation fails because the capability types and store do not exist.

- [ ] **Step 3: Implement the domain and in-memory store**

```dart
enum ModelInputModality { image, file }
enum AttachmentCapabilityStatus { unknown, supported, unsupported }
enum AttachmentCapabilitySource { detected, manual }

final class ModelAttachmentCapability {
  const ModelAttachmentCapability({
    required this.providerId,
    required this.modelId,
    required this.modality,
    required this.status,
    required this.source,
    required this.updatedAt,
  });
  final String providerId;
  final String modelId;
  final ModelInputModality modality;
  final AttachmentCapabilityStatus status;
  final AttachmentCapabilitySource source;
  final DateTime updatedAt;
}
```

Define exact store methods `readCapability`, `saveCapability`, `deleteCapability`, and `deleteDetectedForModel`.

- [ ] **Step 4: Run the store tests and verify GREEN**

Run: `flutter test test/features/providers/data/model_attachment_capability_store_test.dart`

Expected: all tests pass.

- [ ] **Step 5: Write failing Drift v7 schema and migration tests**

Assert schema version 7, six non-sensitive columns, coexistence of manual/detected rows, Provider cascade deletion, and v6 true legacy flags migrating to manual-supported for `default_model` while false creates no row.

- [ ] **Step 6: Run migration tests and verify RED**

Run: `flutter test test/features/providers/data/drift_schema_test.dart test/features/providers/data/drift_migration_test.dart`

Expected: schema version remains 6 and the new table is absent.

- [ ] **Step 7: Implement Drift v7 and the Drift store**

```dart
class ModelAttachmentCapabilities extends Table {
  TextColumn get providerId => text().references(
    ProviderConfigs, #providerId, onDelete: KeyAction.cascade)();
  TextColumn get modelId => text()();
  TextColumn get modality => text()();
  TextColumn get status => text()();
  TextColumn get source => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {providerId, modelId, modality, source};
}
```

Upgrade v6 by creating the table and executing bounded `INSERT ... SELECT` statements for true flags only. Parse enum storage values defensively with generic errors that contain no row data.

- [ ] **Step 8: Regenerate Drift code and verify GREEN**

Run: `dart run build_runner build --delete-conflicting-outputs`

Run: `flutter test test/features/providers/data/model_attachment_capability_store_test.dart test/features/providers/data/drift_schema_test.dart test/features/providers/data/drift_migration_test.dart`

Expected: all targeted tests pass.

- [ ] **Step 9: Commit Task 1**

Stage only the files listed in this task and commit with `feat: 添加模型级附件能力存储`.

### Task 2: Capability resolution and preset fallback

**Files:**
- Create: `lib/features/providers/domain/model_attachment_capability_resolver.dart`
- Modify: `lib/features/providers/data/provider_presets.dart`
- Create: `test/features/providers/domain/model_attachment_capability_resolver_test.dart`
- Modify: `test/features/providers/presentation/provider_capabilities_test.dart`

**Interfaces:**
- Consumes Task 1 capability types and store.
- Produces `resolve({providerId, modelId, modality})`, `saveDetected`, `saveManual`, and `clearManual`.

- [ ] **Step 1: Write failing precedence tests**

Test manual unsupported over detected supported, deleting manual revealing detected, detected over preset, known preset suggesting supported, unknown model resolving unknown, and image/file independence.

- [ ] **Step 2: Run resolver tests and verify RED**

Run: `flutter test test/features/providers/domain/model_attachment_capability_resolver_test.dart`

Expected: resolver type is missing.

- [ ] **Step 3: Implement the resolver**

```dart
Future<ResolvedAttachmentCapability> resolve({
  required String providerId,
  required String modelId,
  required ModelInputModality modality,
}) async {
  final manual = await store.readCapability(
    providerId: providerId,
    modelId: modelId,
    modality: modality,
    source: AttachmentCapabilitySource.manual,
  );
  if (manual != null) return ResolvedAttachmentCapability.fromRecord(manual);

  final detected = await store.readCapability(
    providerId: providerId,
    modelId: modelId,
    modality: modality,
    source: AttachmentCapabilitySource.detected,
  );
  if (detected != null) {
    return ResolvedAttachmentCapability.fromRecord(detected);
  }
  return presetSuggestion(providerId, modelId, modality);
}
```

A false preset suggestion resolves unknown, never unsupported.

- [ ] **Step 4: Run resolver and preset tests and verify GREEN**

Run: `flutter test test/features/providers/domain/model_attachment_capability_resolver_test.dart test/features/providers/presentation/provider_capabilities_test.dart`

Expected: all targeted tests pass.

- [ ] **Step 5: Commit Task 2**

Stage the four listed files and commit with `feat: 解析模型附件能力优先级`.

### Task 3: Safe attachment-rejection classification

**Files:**
- Modify: `lib/features/chat/data/chat_completion_client.dart`
- Modify: `lib/features/chat/data/dio_chat_completion_client.dart`
- Modify: `test/features/chat/data/chat_completion_client_test.dart`

**Interfaces:**
- Produces `ChatCompletionErrorType.attachmentRejected` and `Set<ChatAttachmentKind> rejectedAttachmentKinds` on failure results/events.

- [ ] **Step 1: Write failing Dio mapping tests**

Create fixtures for explicit image unsupported, explicit file unsupported, generic multimodal rejection, file-too-large, unrelated 400, 401/403/429/5xx, and a raw response containing a secret. Assert only explicit rejection is classified and no raw text reaches `userMessage`.

- [ ] **Step 2: Run Dio client tests and verify RED**

Run: `flutter test test/features/chat/data/chat_completion_client_test.dart --plain-name "attachment rejection"`

Expected: `attachmentRejected` does not exist.

- [ ] **Step 3: Implement bounded transient classification**

Only inspect statuses 400, 415, and 422. Convert response data to at most 4096 lowercase characters in memory, reject size-limit phrases, and require both a modality token and an unsupported/invalid-content token.

```dart
final class AttachmentRejection {
  const AttachmentRejection(this.kinds);
  final Set<ChatAttachmentKind> kinds;
}
```

Return only `Provider rejected attachment input`. Apply the classifier to complete and streaming mapping before ordinary status mapping; do not log or persist inspected data.

- [ ] **Step 4: Run Dio tests and verify GREEN**

Run: `flutter test test/features/chat/data/chat_completion_client_test.dart`

Expected: all Dio client tests pass.

- [ ] **Step 5: Commit Task 3**

Stage the three listed files and commit with `feat: 识别附件拒绝响应`.

### Task 4: Chat send, fallback retry, and capability learning

**Files:**
- Modify: `lib/features/chat/data/chat_attachment_request_encoder.dart`
- Modify: `lib/features/chat/presentation/chat_page.dart`
- Modify: `lib/app/app_shell.dart`
- Modify: `test/features/chat/data/chat_attachment_request_encoder_test.dart`
- Modify: `test/features/chat/presentation/chat_attachment_test.dart`

**Interfaces:**
- Consumes the store, resolver, and attachment rejection error.
- `_GenerationTarget` gains `forceTextOnly` and `unsupportedKindsToLearnOnSuccess`.
- `ChatPage` gains optional `ModelAttachmentCapabilityStore`; AppShell injects the Drift implementation.

- [ ] **Step 1: Write failing unknown-capability tests**

Assert an unknown model sends an attachment even when legacy Provider booleans are false. Add independent image/file filtering tests for known unsupported status.

- [ ] **Step 2: Run attachment tests and verify RED**

Run: `flutter test test/features/chat/data/chat_attachment_request_encoder_test.dart test/features/chat/presentation/chat_attachment_test.dart`

Expected: current code prompts before sending or strips the unknown attachment.

- [ ] **Step 3: Implement capability-aware encoding and known-unsupported preflight**

Resolve the exact Provider/model image and file states. Pass `status != unsupported` to the encoder. Replace the current boolean confirmation with:

```dart
enum _AttachmentPreflightDecision { sendAttachments, textOnly, cancel }
```

Persist the user message and attachment once; use `forceTextOnly` only on the generation target.

- [ ] **Step 4: Run the targeted attachment tests and verify GREEN**

Run the same two files. Expected: unknown and known capability behavior passes.

- [ ] **Step 5: Write failing rejection fallback tests**

Cover Normal, Retry, and Regenerate. Assert first request has attachments; explicit rejection shows a dialog; confirmation makes a second request with no attachments; one user message remains; the local attachment remains; fallback success learns unsupported; fallback failure/cancel learns nothing; unrelated errors do not prompt; partial output does not retry.

- [ ] **Step 6: Run fallback tests and verify RED**

Run: `flutter test test/features/chat/presentation/chat_attachment_test.dart`

Expected: current code ends after the first failure and cannot learn capability.

- [ ] **Step 7: Implement same-turn text-only retry**

Track actual sent kinds in the generation closure. On no-content `attachmentRejected`, finish the attempt and ask for confirmation. Learn explicit rejected kinds, or the only sent kind for a generic rejection. Retry the same target with `forceTextOnly: true` and never append the user message again.

On assistant completion:
- attachment attempt: best-effort save detected supported for actual sent kinds;
- fallback: best-effort save detected unsupported only for learnable kinds;
- store failure: preserve successful chat completion.

- [ ] **Step 8: Run attachment and chat regression tests and verify GREEN**

Run: `flutter test test/features/chat/presentation/chat_attachment_test.dart test/features/chat/presentation/chat_page_test.dart test/features/chat/presentation/chat_scroll_test.dart test/features/chat/presentation/chat_model_switching_test.dart`

Expected: all targeted tests pass.

- [ ] **Step 9: Commit Task 4**

Stage the five listed files and commit with `feat: 自动探测并回退附件请求`.

### Task 5: Model-specific three-state Provider configuration

**Files:**
- Modify: `lib/features/providers/presentation/provider_config_page.dart`
- Modify: `lib/features/providers/presentation/providers_page.dart`
- Modify: `lib/app/app_shell.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`
- Modify: `test/features/providers/presentation/provider_capabilities_test.dart`
- Modify: `test/features/providers/presentation/provider_config_page_test.dart`

**Interfaces:**
- UI values are automatic, supports, and unsupported for image/file on the exact default model.

- [ ] **Step 1: Write failing widget tests**

Test Custom Provider manual supports/unsupported, model-specific independence, automatic removing only manual rows and revealing detected state, reset deleting only detected rows, and English/Chinese labels.

- [ ] **Step 2: Run Provider UI tests and verify RED**

Run: `flutter test test/features/providers/presentation/provider_capabilities_test.dart test/features/providers/presentation/provider_config_page_test.dart`

Expected: only boolean switches exist and no reset action exists.

- [ ] **Step 3: Implement three-state controls and reset**

Use compact controls with stable keys `image_capability_mode`, `file_capability_mode`, and `reset_detected_capabilities`. Persist Provider config first, then exact-model manual rows; automatic deletes manual rows. Disable controls while saving/testing and use generic safe errors.

Keep legacy booleans for schema compatibility and derive their saved true value only from manual supported; chat request decisions ignore them.

- [ ] **Step 4: Add English and Chinese copy**

Add labels for automatic detection, learned supported/unsupported, manual supports/unsupported, reset detection, attachment rejected, and retry without attachments. Run `flutter gen-l10n`.

- [ ] **Step 5: Run Provider UI tests and verify GREEN**

Run the two targeted files. Expected: all tests pass in both locales.

- [ ] **Step 6: Commit Task 5**

Stage the seven listed files and commit with `feat: 配置模型附件能力模式`.

### Task 6: Final security and regression verification

**Files:** Modify only if a verification failure identifies a scoped defect.

- [ ] **Step 1: Run formatting**

Run: `dart format .`. Expected: exit code 0.

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`. Expected: `No issues found!`.

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`. Expected: all tests pass, including Stop, Retry, Regenerate, History, New Chat, Agent, model switching, directory, export, migration, security, and language tests.

- [ ] **Step 4: Build the Debug APK**

Run: `flutter build apk --debug`. Expected: `build/app/outputs/flutter-apk/app-debug.apk` exists. Do not run Vivo device tests.

- [ ] **Step 5: Audit the final diff**

Run: `git diff --check` and `git status --short`. Confirm no raw response/request logging, API key persistence, attachment byte columns, unrelated refactors, platform additions, or release-signing changes.
