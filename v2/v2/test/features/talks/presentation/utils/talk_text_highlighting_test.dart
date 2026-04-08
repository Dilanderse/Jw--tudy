import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_study_v2/features/talks/presentation/utils/talk_text_highlighting.dart';

void main() {
  group('toggleTalkHighlight', () {
    test('wraps selected text with highlight markers', () {
      const selection = TextSelection(baseOffset: 0, extentOffset: 10);

      final result = toggleTalkHighlight(
        text: 'Jean 3:16 est central',
        selection: selection,
      );

      expect(result.text, '==Jean 3:16== est central');
      expect(
        result.selection,
        const TextSelection(baseOffset: 2, extentOffset: 11),
      );
    });

    test('removes highlight markers around the selected text', () {
      const selection = TextSelection(baseOffset: 2, extentOffset: 11);

      final result = toggleTalkHighlight(
        text: '==Jean 3:16== est central',
        selection: selection,
      );

      expect(result.text, 'Jean 3:16 est central');
      expect(
        result.selection,
        const TextSelection(baseOffset: 0, extentOffset: 9),
      );
    });

    test('inserts empty highlight markers at the caret position', () {
      const selection = TextSelection.collapsed(offset: 5);

      final result = toggleTalkHighlight(text: 'Texte', selection: selection);

      expect(result.text, 'Texte====');
      expect(result.selection, const TextSelection.collapsed(offset: 7));
    });
  });
}
