import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

typedef LinkOpener = Future<bool> Function(Uri uri);

Future<bool> _defaultLinkOpener(Uri uri) async {
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

class _DollarMathSyntax extends md.InlineSyntax {
  _DollarMathSyntax()
      : super(
          r'\$(?!\$|\s)((?:\\.|[^$\n])*?\S)\$(?!\$)',
          startCharacter: 0x24,
        );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math-inline', match[1]!));
    return true;
  }
}

class _ParenthesisMathSyntax extends md.InlineSyntax {
  _ParenthesisMathSyntax() : super(r'\\\((.+?)\\\)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math-inline', match[1]!));
    return true;
  }
}

class _DisplayMathSyntax extends md.BlockSyntax {
  const _DisplayMathSyntax();

  @override
  RegExp get pattern => RegExp(r'^\s*(\$\$|\\\[)');

  md.Element _buildElement(List<String> formulaLines) {
    final element = md.Element.empty('math-block');
    element.attributes['formula'] = formulaLines.join('\n').trim();
    return element;
  }

  @override
  md.Node parse(md.BlockParser parser) {
    final openingLine = parser.current.content.trimLeft();
    final usesDollarDelimiter = openingLine.startsWith(r'$$');
    final openingDelimiter = usesDollarDelimiter ? r'$$' : r'\[';
    final closingDelimiter = usesDollarDelimiter ? r'$$' : r'\]';
    final formulaLines = <String>[];

    var remainder = openingLine.substring(openingDelimiter.length);
    var closingIndex = remainder.indexOf(closingDelimiter);
    if (closingIndex >= 0) {
      formulaLines.add(remainder.substring(0, closingIndex));
      parser.advance();
      return _buildElement(formulaLines);
    }

    if (remainder.isNotEmpty) {
      formulaLines.add(remainder);
    }
    parser.advance();

    while (!parser.isDone) {
      final line = parser.current.content;
      closingIndex = line.indexOf(closingDelimiter);
      if (closingIndex >= 0) {
        formulaLines.add(line.substring(0, closingIndex));
        parser.advance();
        break;
      }
      formulaLines.add(line);
      parser.advance();
    }

    return _buildElement(formulaLines);
  }
}

class _MathElementBuilder extends MarkdownElementBuilder {
  _MathElementBuilder({required this.display});

  final bool display;

  @override
  bool isBlockElement() => display;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final formula =
        (element.attributes['formula'] ?? element.textContent).trim();
    final theme = Theme.of(context);
    final textStyle = (preferredStyle ??
            parentStyle ??
            theme.textTheme.bodyMedium ??
            const TextStyle())
        .copyWith(
      color: theme.colorScheme.onSurface,
      fontSize: display ? 17 : 15,
    );

    final math = Math.tex(
      formula,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: textStyle,
      onErrorFallback: (_) => Text(formula, style: textStyle),
    );

    if (!display) {
      return Semantics(label: formula, child: math);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Semantics(label: formula, child: math),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AssistantMessageContent extends StatelessWidget {
  const AssistantMessageContent({
    required this.source,
    this.linkOpener,
    super.key,
  });

  final String source;
  final LinkOpener? linkOpener;

  LinkOpener get _opener => linkOpener ?? _defaultLinkOpener;

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
      blockSyntaxes: const [_DisplayMathSyntax()],
      inlineSyntaxes: [
        _ParenthesisMathSyntax(),
        _DollarMathSyntax(),
      ],
      builders: {
        'math-inline': _MathElementBuilder(display: false),
        'math-block': _MathElementBuilder(display: true),
      },
      onTapLink: (text, href, title) {
        if (href == null) return;
        final uri = Uri.tryParse(href);
        if (uri == null) return;
        if (uri.scheme != 'http' && uri.scheme != 'https') return;
        Future.sync(() => _opener(uri)).catchError((_) => false);
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
      imageBuilder: (uri, title, alt) {
        return Text(
          alt ?? '[Image]',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        );
      },
    );
  }
}
