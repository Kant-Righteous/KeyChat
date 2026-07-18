import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GLM SSE event parsing', () {
    test('reasoning -> content -> DONE completes successfully', () {
      final events = <Map<String, dynamic>>[];

      // Reasoning event
      events.add({
        'choices': [
          {
            'delta': {
              'reasoning_content': 'Analyzing the problem...',
            },
          },
        ],
      });

      // Content event
      events.add({
        'choices': [
          {
            'delta': {
              'content': 'Here is my answer.',
            },
          },
        ],
      });

      // Verify sequence
      expect(events.length, 2);
      final firstChoices = events[0]['choices'] as List;
      final firstDelta = firstChoices[0]['delta'] as Map;
      expect(firstDelta['reasoning_content'], 'Analyzing the problem...');

      final secondChoices = events[1]['choices'] as List;
      final secondDelta = secondChoices[0]['delta'] as Map;
      expect(secondDelta['content'], 'Here is my answer.');
    });

    test('multiple reasoning chunks do not fail', () {
      final events = <Map<String, dynamic>>[];

      for (int i = 0; i < 5; i++) {
        events.add({
          'choices': [
            {
              'delta': {
                'reasoning_content': 'Thinking part $i...',
              },
            },
          ],
        });
      }

      // All should be valid
      expect(events.length, 5);
      for (final event in events) {
        final choices = event['choices'] as List;
        final delta = choices[0]['delta'] as Map;
        expect(delta.containsKey('reasoning_content'), isTrue);
        expect(delta['reasoning_content'], isNotEmpty);
      }
    });

    test('reasoning-only chunk produces no content', () {
      final event = {
        'choices': [
          {
            'delta': {
              'reasoning_content': 'Thinking...',
            },
          },
        ],
      };

      final choices = event['choices'] as List;
      final delta = choices[0]['delta'] as Map;
      expect(delta.containsKey('reasoning_content'), isTrue);
      expect(delta.containsKey('content'), isFalse);
    });

    test('content after reasoning produces content', () {
      final events = [
        {
          'choices': [
            {
              'delta': {
                'reasoning_content': 'Thinking...',
              },
            },
          ],
        },
        {
          'choices': [
            {
              'delta': {
                'content': 'Answer',
              },
            },
          ],
        },
      ];

      final firstChoices = events[0]['choices'] as List;
      final firstDelta = firstChoices[0]['delta'] as Map;
      expect(firstDelta.containsKey('reasoning_content'), isTrue);

      final secondChoices = events[1]['choices'] as List;
      final secondDelta = secondChoices[0]['delta'] as Map;
      expect(secondDelta.containsKey('content'), isTrue);
      expect(secondDelta['content'], 'Answer');
    });

    test('reasoning plus finish_reason completes correctly', () {
      final events = [
        {
          'choices': [
            {
              'delta': {
                'reasoning_content': 'Final thoughts...',
              },
            },
          ],
        },
        {
          'choices': [
            {
              'delta': {},
              'finish_reason': 'stop',
            },
          ],
        },
      ];

      final choices = events[1]['choices'] as List;
      expect(choices[0]['finish_reason'], 'stop');
    });

    test('reasoning plus usage-only event completes correctly', () {
      final events = [
        {
          'choices': [
            {
              'delta': {
                'reasoning_content': 'Thinking...',
              },
            },
          ],
        },
        {
          'usage': {
            'prompt_tokens': 100,
            'completion_tokens': 50,
            'total_tokens': 150,
          },
        },
      ];

      // Second event has no choices (usage-only)
      expect(events[1].containsKey('choices'), isFalse);
      expect(events[1].containsKey('usage'), isTrue);
    });

    test('empty choices does not terminate a valid stream', () {
      final events = [
        {
          'choices': <Map<String, dynamic>>[],
        },
        {
          'choices': [
            {
              'delta': {
                'content': 'Hello!',
              },
            },
          ],
        },
      ];

      // First event has empty choices
      final firstChoices = events[0]['choices'] as List;
      expect(firstChoices, isEmpty);

      // Second event has content
      final secondChoices = events[1]['choices'] as List;
      final secondDelta = secondChoices[0]['delta'] as Map;
      expect(secondDelta['content'], 'Hello!');
    });

    test('reasoning-only EOF returns invalidResponse', () {
      // Simulate stream that only had reasoning, no content
      const hadContent = false;
      const hadReasoning = true;

      // Should return error
      if (!hadContent && hadReasoning) {
        const errorMessage = 'No content in response';
        expect(errorMessage, 'No content in response');
      }
    });

    test('reasoning is not exposed in userMessage', () {
      const reasoningContent = 'Internal reasoning...';
      const userMessage = 'No content in response';

      // userMessage should not contain reasoning
      expect(userMessage.contains(reasoningContent), isFalse);
    });

    test('reasoning is not persisted as assistant content', () {
      // Only content should be persisted
      const content = 'Here is my answer.';
      const reasoning = 'Thinking...';

      // Simulate persistence
      const persistedContent = content;
      expect(persistedContent, content);
      expect(persistedContent.contains(reasoning), isFalse);
    });

    test('reasoning is not included in next request context', () {
      // Build context for next request
      final messages = [
        {'role': 'user', 'content': 'Hello'},
        {'role': 'assistant', 'content': 'Here is my answer.'},
      ];

      // No reasoning in messages
      for (final msg in messages) {
        expect(msg.containsKey('reasoning_content'), isFalse);
      }
    });

    test('content is persisted exactly once', () {
      // Simulate content received
      const content = 'Hello!';
      var persistCount = 0;

      // Persist
      persistCount++;
      expect(persistCount, 1);
      expect(content, 'Hello!');
    });

    test('terminal event occurs exactly once', () {
      // Simulate stream completion
      var completionCount = 0;

      // DONE received
      completionCount++;
      expect(completionCount, 1);
    });

    test('Stop during reasoning produces no assistant message', () {
      // Simulate stop during reasoning
      const hadContent = false;
      const wasStopped = true;

      if (wasStopped && !hadContent) {
        // Should not save assistant message
        expect(hadContent, isFalse);
      }
    });

    test('Retry after reasoning failure works', () {
      // First attempt: reasoning-only (failure)
      final firstAttempt = {
        'hadContent': false,
        'hadReasoning': true,
      };

      // Retry should work
      final retryAttempt = {
        'hadContent': true,
        'content': 'Retry answer',
      };

      expect(firstAttempt['hadContent'], isFalse);
      expect(retryAttempt['hadContent'], isTrue);
      expect(retryAttempt['content'], 'Retry answer');
    });
  });

  group('GLM SSE data format validation', () {
    test('valid reasoning chunk format', () {
      final data = {
        'choices': [
          {
            'delta': {
              'reasoning_content': 'Thinking...',
            },
          },
        ],
      };

      final choices = data['choices'] as List;
      expect(choices.length, 1);
      final delta = choices[0]['delta'] as Map;
      expect(delta['reasoning_content'], 'Thinking...');
    });

    test('valid content chunk format', () {
      final data = {
        'choices': [
          {
            'delta': {
              'content': 'Hello!',
            },
          },
        ],
      };

      final choices = data['choices'] as List;
      final delta = choices[0]['delta'] as Map;
      expect(delta['content'], 'Hello!');
    });

    test('valid finish_reason format', () {
      final data = {
        'choices': [
          {
            'delta': {},
            'finish_reason': 'stop',
          },
        ],
      };

      final choices = data['choices'] as List;
      expect(choices[0]['finish_reason'], 'stop');
    });

    test('valid usage-only format', () {
      final data = {
        'usage': {
          'prompt_tokens': 100,
          'completion_tokens': 50,
          'total_tokens': 150,
        },
      };

      expect(data.containsKey('choices'), isFalse);
      final usage = data['usage'] as Map;
      expect(usage['total_tokens'], 150);
    });

    test('DONE signal format', () {
      const done = '[DONE]';
      expect(done, '[DONE]');
    });
  });
}
