import 'dart:math' as math;

import 'package:flutter/material.dart';

const String talkHighlightMarker = '==';

class TalkHighlightEditResult {
  const TalkHighlightEditResult({required this.text, required this.selection});

  final String text;
  final TextSelection selection;
}

class TalkHighlightingTextEditingController extends TextEditingController {
  TalkHighlightingTextEditingController({super.text});

  static final RegExp _highlightPattern = RegExp(
    '${RegExp.escape(talkHighlightMarker)}(.*?)${RegExp.escape(talkHighlightMarker)}',
    dotAll: true,
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final effectiveStyle = style ?? const TextStyle();
    final theme = Theme.of(context);
    final markerStyle = effectiveStyle.copyWith(
      color: Colors.white24,
      fontWeight: FontWeight.w600,
    );
    final highlightedStyle = effectiveStyle.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.24),
    );

    if (text.isEmpty) {
      return TextSpan(style: effectiveStyle, text: text);
    }

    final spans = <InlineSpan>[];
    var currentIndex = 0;

    for (final match in _highlightPattern.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: effectiveStyle,
          ),
        );
      }

      final highlightedText = match.group(1) ?? '';
      spans.add(TextSpan(text: talkHighlightMarker, style: markerStyle));
      spans.add(TextSpan(text: highlightedText, style: highlightedStyle));
      spans.add(TextSpan(text: talkHighlightMarker, style: markerStyle));

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(
        TextSpan(text: text.substring(currentIndex), style: effectiveStyle),
      );
    }

    return TextSpan(style: effectiveStyle, children: spans);
  }
}

TalkHighlightEditResult toggleTalkHighlight({
  required String text,
  required TextSelection selection,
}) {
  final textLength = text.length;
  final normalizedSelection = selection.isValid
      ? TextSelection(
          baseOffset: _clampOffset(selection.baseOffset, textLength),
          extentOffset: _clampOffset(selection.extentOffset, textLength),
        )
      : TextSelection.collapsed(offset: textLength);
  final start = math.min(
    normalizedSelection.baseOffset,
    normalizedSelection.extentOffset,
  );
  final end = math.max(
    normalizedSelection.baseOffset,
    normalizedSelection.extentOffset,
  );

  if (start == end) {
    final updatedText = text.replaceRange(
      start,
      end,
      '$talkHighlightMarker$talkHighlightMarker',
    );
    return TalkHighlightEditResult(
      text: updatedText,
      selection: TextSelection.collapsed(
        offset: start + talkHighlightMarker.length,
      ),
    );
  }

  final selectedText = text.substring(start, end);
  final markerLength = talkHighlightMarker.length;
  final trimmedSelection = _trimSelectionBounds(
    text: text,
    start: start,
    end: end,
  );

  if (_selectionContainsMarkers(selectedText)) {
    final innerText = selectedText.substring(
      markerLength,
      selectedText.length - markerLength,
    );
    final updatedText = text.replaceRange(start, end, innerText);
    return TalkHighlightEditResult(
      text: updatedText,
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + innerText.length,
      ),
    );
  }

  if (_selectionContainsMarkers(trimmedSelection.text)) {
    final innerText = trimmedSelection.text.substring(
      markerLength,
      trimmedSelection.text.length - markerLength,
    );
    final updatedText = text.replaceRange(
      trimmedSelection.start,
      trimmedSelection.end,
      innerText,
    );
    return TalkHighlightEditResult(
      text: updatedText,
      selection: TextSelection(
        baseOffset: trimmedSelection.start,
        extentOffset: trimmedSelection.start + innerText.length,
      ),
    );
  }

  final hasSurroundingMarkers =
      trimmedSelection.start >= markerLength &&
      trimmedSelection.end + markerLength <= text.length &&
      text.substring(
            trimmedSelection.start - markerLength,
            trimmedSelection.start,
          ) ==
          talkHighlightMarker &&
      text.substring(
            trimmedSelection.end,
            trimmedSelection.end + markerLength,
          ) ==
          talkHighlightMarker;

  if (hasSurroundingMarkers) {
    final updatedText = text.replaceRange(
      trimmedSelection.end,
      trimmedSelection.end + markerLength,
      '',
    );
    final finalText = updatedText.replaceRange(
      trimmedSelection.start - markerLength,
      trimmedSelection.start,
      '',
    );
    return TalkHighlightEditResult(
      text: finalText,
      selection: TextSelection(
        baseOffset: trimmedSelection.start - markerLength,
        extentOffset: trimmedSelection.end - markerLength,
      ),
    );
  }

  final updatedText = text.replaceRange(
    trimmedSelection.start,
    trimmedSelection.end,
    '$talkHighlightMarker${trimmedSelection.text}$talkHighlightMarker',
  );
  return TalkHighlightEditResult(
    text: updatedText,
    selection: TextSelection(
      baseOffset: trimmedSelection.start + markerLength,
      extentOffset: trimmedSelection.end + markerLength,
    ),
  );
}

int _clampOffset(int value, int length) {
  if (value < 0) return 0;
  if (value > length) return length;
  return value;
}

bool _selectionContainsMarkers(String selectedText) {
  return selectedText.length >= talkHighlightMarker.length * 2 &&
      selectedText.startsWith(talkHighlightMarker) &&
      selectedText.endsWith(talkHighlightMarker);
}

_TrimmedSelection _trimSelectionBounds({
  required String text,
  required int start,
  required int end,
}) {
  final selectedText = text.substring(start, end);
  final leftTrimmed = selectedText.trimLeft();
  final rightTrimmed = selectedText.trimRight();
  final leadingWhitespace = selectedText.length - leftTrimmed.length;
  final trailingWhitespace = selectedText.length - rightTrimmed.length;
  final trimmedStart = start + leadingWhitespace;
  final trimmedEnd = end - trailingWhitespace;

  if (trimmedStart >= trimmedEnd) {
    return _TrimmedSelection(start: start, end: end, text: selectedText);
  }

  return _TrimmedSelection(
    start: trimmedStart,
    end: trimmedEnd,
    text: text.substring(trimmedStart, trimmedEnd),
  );
}

class _TrimmedSelection {
  const _TrimmedSelection({
    required this.start,
    required this.end,
    required this.text,
  });

  final int start;
  final int end;
  final String text;
}
