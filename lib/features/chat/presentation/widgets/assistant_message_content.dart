import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class AssistantMessageContent extends StatelessWidget {
  const AssistantMessageContent({
    required this.source,
    super.key,
  });

  final String source;

  static final _codeBlockDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    color: Colors.grey.shade100,
  );

  static final _inlineCodeStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    backgroundColor: Colors.grey.shade100,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MarkdownBody(
      data: source,
      selectable: true,
      onTapLink: (text, href, title) {
        if (href == null) return;
        final uri = Uri.tryParse(href);
        if (uri == null) return;
        if (uri.scheme != 'http' && uri.scheme != 'https') return;
        launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
        h1: theme.textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.bold),
        h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        h4: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        h5: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        h6: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        code: _inlineCodeStyle.copyWith(
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        codeblockDecoration: _codeBlockDecoration.copyWith(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.outline,
              width: 3,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
        tableBorder: TableBorder.all(
          color: theme.colorScheme.outline,
          width: 1,
        ),
        tableHead: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        tableBody: theme.textTheme.bodyMedium,
        tableCellsPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        a: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline,
              width: 1,
            ),
          ),
        ),
        listBullet: theme.textTheme.bodyMedium,
        img: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
