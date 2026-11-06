import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;
import '../domain/block_names.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class ChatMessageBody extends StatelessWidget {
  const ChatMessageBody({
    super.key,
    required this.text,
    required this.assistant,
    this.onTap,
  });
  final String text;
  final bool assistant;

  /// Toque sobre el texto (SelectableText lo absorbe y no llega al padre).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textDirection =
        Bidi.detectRtlDirectionality(text)
            ? TextDirection.rtl
            : TextDirection.ltr;
    if (!assistant) {
      return Directionality(
        textDirection: textDirection,
        child: SelectableText(text, onTap: onTap),
      );
    }
    final visible = text.replaceAll(hiddenBlockPattern, '').trim();
    final colors = Theme.of(context).colorScheme;
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(color: colors.onSurface, height: 1.4);
    final inset = colors.surfaceContainerHighest;
    return Directionality(
      textDirection: textDirection,
      child: MarkdownBody(
        data: visible,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: textStyle,
          blockquote: textStyle,
          blockquoteDecoration: BoxDecoration(
            color: inset,
            border: Border(left: BorderSide(color: colors.primary, width: 3)),
          ),
          blockquotePadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          code: textStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: inset,
          ),
          codeblockDecoration: BoxDecoration(
            color: inset,
            borderRadius: BorderRadius.circular(8),
          ),
          codeblockPadding: const EdgeInsets.all(12),
          tableBody: textStyle,
          a: textStyle.copyWith(
            color: colors.primary,
            decoration: TextDecoration.underline,
          ),
          tableColumnWidth: const FlexColumnWidth(),
          tableCellsPadding: const EdgeInsets.all(6),
        ),
        // Generated Markdown does not authorize file reads or image downloads.
        // User attachments use the picker.
        imageBuilder: (_, __, alt) => Text(alt ?? 'Imagen'),
      ),
    );
  }
}
