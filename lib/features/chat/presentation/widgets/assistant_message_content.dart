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

enum _MermaidDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

class _MermaidNodeToken {
  const _MermaidNodeToken({
    required this.id,
    this.explicitLabel,
  });

  final String id;
  final String? explicitLabel;

  static _MermaidNodeToken? tryParse(String source) {
    var value = source.trim();
    final classSuffix = value.indexOf(':::');
    if (classSuffix >= 0) {
      value = value.substring(0, classSuffix).trim();
    }

    final idMatch = RegExp(r'^([A-Za-z0-9_-]+)').firstMatch(value);
    if (idMatch == null) return null;

    final id = idMatch.group(1)!;
    final shape = value.substring(idMatch.end).trim();
    if (shape.isEmpty) {
      return _MermaidNodeToken(id: id);
    }

    String? label;
    if (shape.startsWith('((') && shape.endsWith('))')) {
      label = shape.substring(2, shape.length - 2);
    } else if (shape.startsWith('[') && shape.endsWith(']')) {
      label = shape.substring(1, shape.length - 1);
    } else if (shape.startsWith('(') && shape.endsWith(')')) {
      label = shape.substring(1, shape.length - 1);
    } else if (shape.startsWith('{') && shape.endsWith('}')) {
      label = shape.substring(1, shape.length - 1);
    } else {
      return null;
    }

    label = label.trim();
    if (label.length >= 2 &&
        ((label.startsWith('"') && label.endsWith('"')) ||
            (label.startsWith("'") && label.endsWith("'")))) {
      label = label.substring(1, label.length - 1);
    }
    label = label.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );

    return _MermaidNodeToken(
      id: id,
      explicitLabel: label.isEmpty ? id : label,
    );
  }
}

class _MermaidEdge {
  const _MermaidEdge({
    required this.from,
    required this.to,
    this.label,
  });

  final String from;
  final String to;
  final String? label;
}

class _MermaidDiagram {
  const _MermaidDiagram({
    required this.direction,
    required this.edges,
  });

  final _MermaidDirection direction;
  final List<_MermaidEdge> edges;

  static final _headerPattern = RegExp(
    r'^(?:graph|flowchart)\s+(LR|RL|TD|TB|BT)$',
    caseSensitive: false,
  );
  static final _pipeEdgePattern = RegExp(
    r'^(.+?)\s*(-->|==>|-\.->|---)\s*(?:\|([^|]*)\|\s*)?(.+)$',
  );
  static final _textEdgePattern = RegExp(
    r'^(.+?)\s+--\s+(.+?)\s+-->\s+(.+)$',
  );

  static _MermaidDiagram? tryParse(String source) {
    final statements = source
        .replaceAll('\r\n', '\n')
        .split(RegExp(r'[\n;]'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('%%'))
        .toList();
    if (statements.isEmpty) return null;

    final header = _headerPattern.firstMatch(statements.first);
    if (header == null) return null;

    final direction = switch (header.group(1)!.toUpperCase()) {
      'LR' => _MermaidDirection.leftToRight,
      'RL' => _MermaidDirection.rightToLeft,
      'BT' => _MermaidDirection.bottomToTop,
      _ => _MermaidDirection.topToBottom,
    };
    final knownLabels = <String, String>{};
    final edges = <_MermaidEdge>[];

    for (final statement in statements.skip(1)) {
      final textMatch = _textEdgePattern.firstMatch(statement);
      final pipeMatch =
          textMatch == null ? _pipeEdgePattern.firstMatch(statement) : null;
      if (pipeMatch == null && textMatch == null) {
        final node = _MermaidNodeToken.tryParse(statement);
        if (node?.explicitLabel == null) return null;
        knownLabels[node!.id] = node.explicitLabel!;
        continue;
      }

      final fromSource = (pipeMatch ?? textMatch)!.group(1)!;
      final toSource = pipeMatch?.group(4) ?? textMatch?.group(3);
      final edgeLabel = pipeMatch?.group(3) ?? textMatch?.group(2);
      final from = _MermaidNodeToken.tryParse(fromSource);
      final to = _MermaidNodeToken.tryParse(toSource!);
      if (from == null || to == null) return null;

      final fromLabel = from.explicitLabel ?? knownLabels[from.id] ?? from.id;
      final toLabel = to.explicitLabel ?? knownLabels[to.id] ?? to.id;
      if (from.explicitLabel != null) {
        knownLabels[from.id] = from.explicitLabel!;
      }
      if (to.explicitLabel != null) {
        knownLabels[to.id] = to.explicitLabel!;
      }
      final normalizedEdgeLabel = edgeLabel?.trim();

      edges.add(
        _MermaidEdge(
          from: fromLabel,
          to: toLabel,
          label: normalizedEdgeLabel == null || normalizedEdgeLabel.isEmpty
              ? null
              : normalizedEdgeLabel,
        ),
      );
    }

    if (edges.isEmpty) return null;
    return _MermaidDiagram(direction: direction, edges: edges);
  }
}

class _MermaidCodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final classes = element.attributes['class']?.split(' ') ?? const [];
    if (!classes.contains('language-mermaid')) return null;

    final diagram = _MermaidDiagram.tryParse(element.textContent);
    if (diagram == null) return null;
    return _MermaidDiagramView(diagram: diagram);
  }
}

class _MermaidDiagramView extends StatelessWidget {
  const _MermaidDiagramView({required this.diagram});

  final _MermaidDiagram diagram;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('mermaid-diagram'),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < diagram.edges.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            _MermaidEdgeView(
              edge: diagram.edges[index],
              direction: diagram.direction,
            ),
          ],
        ],
      ),
    );
  }
}

class _MermaidEdgeView extends StatelessWidget {
  const _MermaidEdgeView({
    required this.edge,
    required this.direction,
  });

  final _MermaidEdge edge;
  final _MermaidDirection direction;

  @override
  Widget build(BuildContext context) {
    return switch (direction) {
      _MermaidDirection.leftToRight => _buildHorizontal(reverse: false),
      _MermaidDirection.rightToLeft => _buildHorizontal(reverse: true),
      _MermaidDirection.topToBottom => _buildVertical(reverse: false),
      _MermaidDirection.bottomToTop => _buildVertical(reverse: true),
    };
  }

  Widget _buildHorizontal({required bool reverse}) {
    final first = reverse ? edge.to : edge.from;
    final last = reverse ? edge.from : edge.to;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _MermaidNodeView(label: first)),
        SizedBox(
          width: 72,
          child: _MermaidArrowView(
            label: edge.label,
            icon: reverse ? Icons.arrow_back : Icons.arrow_forward,
          ),
        ),
        Expanded(child: _MermaidNodeView(label: last)),
      ],
    );
  }

  Widget _buildVertical({required bool reverse}) {
    final first = reverse ? edge.to : edge.from;
    final last = reverse ? edge.from : edge.to;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: _MermaidNodeView(label: first),
        ),
        _MermaidArrowView(
          label: edge.label,
          icon: reverse ? Icons.arrow_upward : Icons.arrow_downward,
        ),
        SizedBox(
          width: double.infinity,
          child: _MermaidNodeView(label: last),
        ),
      ],
    );
  }
}

class _MermaidNodeView extends StatelessWidget {
  const _MermaidNodeView({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        softWrap: true,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

class _MermaidArrowView extends StatelessWidget {
  const _MermaidArrowView({
    required this.icon,
    this.label,
  });

  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null)
            Text(
              label!,
              textAlign: TextAlign.center,
              softWrap: true,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          Icon(
            icon,
            size: 24,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
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
        'code': _MermaidCodeElementBuilder(),
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
