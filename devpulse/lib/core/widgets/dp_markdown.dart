import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DevPulse Markdown Renderer
//
// Parses a subset of CommonMark that covers typical lesson content:
//   # / ## / ###  headings
//   **bold** / *italic* / `inline code`
//   ``` code blocks (with language hint)
//   > blockquotes
//   - / * unordered list items
//   1. ordered list items
//   --- horizontal rule
//   plain paragraphs with mixed inline formatting
// ─────────────────────────────────────────────────────────────────────────────

class DpMarkdown extends StatelessWidget {
  final String data;
  final EdgeInsetsGeometry padding;

  const DpMarkdown({
    super.key,
    required this.data,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final blocks = _parse(data);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < blocks.length; i++) ...[
            _buildBlock(context, blocks[i]),
            if (i < blocks.length - 1) _blockSpacing(blocks[i].type),
          ],
        ],
      ),
    );
  }

  // ── Block spacing ────────────────────────────────────────────────
  Widget _blockSpacing(_BlockType type) {
    switch (type) {
      case _BlockType.h1: return const SizedBox(height: 16);
      case _BlockType.h2: return const SizedBox(height: 12);
      case _BlockType.h3: return const SizedBox(height: 10);
      case _BlockType.hr: return const SizedBox(height: 16);
      case _BlockType.codeBlock: return const SizedBox(height: 16);
      case _BlockType.blockquote: return const SizedBox(height: 14);
      default: return const SizedBox(height: 10);
    }
  }

  // ── Block renderer ───────────────────────────────────────────────
  Widget _buildBlock(BuildContext context, _Block block) {
    switch (block.type) {
      case _BlockType.h1:
        return Text(block.text,
            style: AppTextStyles.displayLgMobile(color: AppColors.onSurface)
                .copyWith(fontSize: 22, height: 1.3));

      case _BlockType.h2:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(block.text,
              style: AppTextStyles.headlineMd(color: AppColors.onSurface)
                  .copyWith(fontSize: 18, height: 1.4)),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ]);

      case _BlockType.h3:
        return Text(block.text,
            style: AppTextStyles.headlineMd(color: AppColors.primary)
                .copyWith(fontSize: 15, height: 1.4));

      case _BlockType.hr:
        return Divider(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
          thickness: 1,
        );

      case _BlockType.codeBlock:
        return _CodeBlock(code: block.text, language: block.extra);

      case _BlockType.blockquote:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.08),
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(8)),
            border: const Border(
              left: BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
          child: _InlineText(
            text: block.text,
            baseStyle: AppTextStyles.bodyMd(color: AppColors.onSurface)
                .copyWith(fontStyle: FontStyle.italic, height: 1.65),
          ),
        );

      case _BlockType.ulItem:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 10),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(
              child: _InlineText(
                text: block.text,
                baseStyle: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)
                    .copyWith(height: 1.65),
              ),
            ),
          ],
        );

      case _BlockType.olItem:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${block.extra ?? ''}.',
                style: AppTextStyles.bodyMd(color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w700, height: 1.65),
              ),
            ),
            Expanded(
              child: _InlineText(
                text: block.text,
                baseStyle: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)
                    .copyWith(height: 1.65),
              ),
            ),
          ],
        );

      case _BlockType.paragraph:
        return _InlineText(
          text: block.text,
          baseStyle: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)
              .copyWith(height: 1.75),
        );
    }
  }

  // ── Parser ────────────────────────────────────────────────────────
  static List<_Block> _parse(String raw) {
    final lines = raw.split('\n');
    final blocks = <_Block>[];
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // Code block
      if (line.trimLeft().startsWith('```')) {
        final lang = line.trim().replaceFirst('```', '').trim();
        final codeLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          codeLines.add(lines[i]);
          i++;
        }
        blocks.add(_Block(_BlockType.codeBlock, codeLines.join('\n'), extra: lang.isNotEmpty ? lang : null));
        i++;
        continue;
      }

      // HR
      if (RegExp(r'^[-*_]{3,}\s*$').hasMatch(line.trim())) {
        blocks.add(_Block(_BlockType.hr, ''));
        i++;
        continue;
      }

      // Headings
      final h3 = RegExp(r'^### (.+)');
      final h2 = RegExp(r'^## (.+)');
      final h1 = RegExp(r'^# (.+)');
      if (h3.hasMatch(line)) {
        blocks.add(_Block(_BlockType.h3, h3.firstMatch(line)!.group(1)!.trim()));
        i++; continue;
      }
      if (h2.hasMatch(line)) {
        blocks.add(_Block(_BlockType.h2, h2.firstMatch(line)!.group(1)!.trim()));
        i++; continue;
      }
      if (h1.hasMatch(line)) {
        blocks.add(_Block(_BlockType.h1, h1.firstMatch(line)!.group(1)!.trim()));
        i++; continue;
      }

      // Blockquote — merge consecutive > lines
      if (line.startsWith('>')) {
        final qLines = <String>[];
        while (i < lines.length && lines[i].startsWith('>')) {
          qLines.add(lines[i].replaceFirst(RegExp(r'^>\s?'), ''));
          i++;
        }
        blocks.add(_Block(_BlockType.blockquote, qLines.join(' ')));
        continue;
      }

      // UL
      if (RegExp(r'^[-*+] ').hasMatch(line)) {
        blocks.add(_Block(_BlockType.ulItem,
            line.replaceFirst(RegExp(r'^[-*+] '), '')));
        i++; continue;
      }

      // OL
      final olMatch = RegExp(r'^(\d+)\. (.+)').firstMatch(line);
      if (olMatch != null) {
        blocks.add(_Block(_BlockType.olItem, olMatch.group(2)!,
            extra: olMatch.group(1)));
        i++; continue;
      }

      // Empty line — skip
      if (line.trim().isEmpty) { i++; continue; }

      // Paragraph — merge consecutive non-special lines
      final paraLines = <String>[];
      while (i < lines.length) {
        final l = lines[i];
        if (l.trim().isEmpty) break;
        if (l.startsWith('#') || l.startsWith('>') ||
            RegExp(r'^[-*+] ').hasMatch(l) ||
            RegExp(r'^\d+\. ').hasMatch(l) ||
            l.trim().startsWith('```') ||
            RegExp(r'^[-*_]{3,}\s*$').hasMatch(l.trim())) break;
        paraLines.add(l);
        i++;
      }
      if (paraLines.isNotEmpty) {
        blocks.add(_Block(_BlockType.paragraph, paraLines.join(' ')));
      }
    }

    return blocks;
  }
}

// ── Block model ───────────────────────────────────────────────────
enum _BlockType { h1, h2, h3, paragraph, codeBlock, blockquote, ulItem, olItem, hr }

class _Block {
  final _BlockType type;
  final String text;
  final String? extra; // language for code block, number for ol

  const _Block(this.type, this.text, {this.extra});
}

// ── Inline text renderer (bold, italic, inline code) ─────────────
class _InlineText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;

  const _InlineText({required this.text, required this.baseStyle});

  @override
  Widget build(BuildContext context) {
    return RichText(text: TextSpan(children: _parseInline(text, baseStyle)));
  }

  static List<InlineSpan> _parseInline(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    // Pattern matches: **bold** | *italic* | `code` in order
    final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`([^`]+)`');
    int cursor = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start), style: base));
      }

      if (match.group(1) != null) {
        // **bold**
        spans.add(TextSpan(
          text: match.group(1),
          style: base.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ));
      } else if (match.group(2) != null) {
        // *italic*
        spans.add(TextSpan(
          text: match.group(2),
          style: base.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(3) != null) {
        // `inline code`
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Text(
              match.group(3)!,
              style: AppTextStyles.codeBlock(color: AppColors.primaryFixedDim)
                  .copyWith(fontSize: base.fontSize != null ? base.fontSize! - 1 : 12),
            ),
          ),
        ));
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: text, style: base));
    return spans;
  }
}

// ── Code Block widget ─────────────────────────────────────────────
class _CodeBlock extends StatefulWidget {
  final String code;
  final String? language;

  const _CodeBlock({required this.code, this.language});

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title bar ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                _dot(const Color(0xFFFF5F57)),
                const SizedBox(width: 5),
                _dot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 5),
                _dot(const Color(0xFF28C840)),
                if (widget.language != null) ...[
                  const SizedBox(width: 12),
                  Text(widget.language!,
                      style: AppTextStyles.labelSm(
                              color: AppColors.onSurfaceVariant)
                          .copyWith(fontSize: 11)),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: _copy,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? Row(
                            key: const ValueKey('check'),
                            children: [
                              Icon(Icons.check_rounded,
                                  size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('Copied',
                                  style: AppTextStyles.labelSm(
                                          color: AppColors.primary)
                                      .copyWith(fontSize: 11)),
                            ],
                          )
                        : Row(
                            key: const ValueKey('copy'),
                            children: [
                              const Icon(Icons.content_copy,
                                  size: 13,
                                  color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text('Copy',
                                  style: AppTextStyles.labelSm(
                                          color: AppColors.onSurfaceVariant)
                                      .copyWith(fontSize: 11)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          // ── Code content ──────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: Text(
              widget.code,
              style: AppTextStyles.codeBlock(color: const Color(0xFFE6EDF3))
                  .copyWith(fontSize: 13, height: 1.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.55), shape: BoxShape.circle),
      );
}
