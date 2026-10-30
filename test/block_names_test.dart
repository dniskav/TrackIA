import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/chat_archive_store.dart';
import 'package:trackia/domain/activity.dart';
import 'package:trackia/domain/block_names.dart';

void main() {
  final activity = jsonEncode({
    'name': 'Leer',
    'repeated': false,
    'restSeconds': 0,
    'fields': <Object>[],
  });

  group('blocks are read under both names', () {
    for (final prefix in ['trackia', 'gymia']) {
      test('```$prefix-activity is a proposal', () {
        final proposal = ActivityDefinition.proposal(
          '```$prefix-activity\n$activity\n```',
        );
        expect(proposal?.name, 'Leer');
      });

      test('```$prefix-archive is a directive', () {
        final directive = chatDirective(
          '```$prefix-archive\n'
              '{"title":"Fase","summary":"Resumen","reason":"Largo"}\n```',
          'archive',
        );
        expect(directive?['title'], 'Fase');
      });
    }

    test('two blocks, one of each name, still count as two', () {
      final both =
          '```trackia-activity\n$activity\n```\n```gymia-activity\n$activity\n```';
      expect(ActivityDefinition.proposal(both), isNull);
    });
  });

  group('helpers', () {
    test('hasBlock sees a block that is still being written', () {
      expect(hasBlock('texto ```trackia-sync\n{"a"', 'sync'), isTrue);
      expect(hasBlock('texto ```gymia-sync\n{"a"', 'sync'), isTrue);
      expect(hasBlock('texto ```trackia-sync', 'archive'), isFalse);
      expect(hasBlock('sin bloques', 'sync'), isFalse);
    });

    test('the user never sees command blocks, old or new', () {
      String shown(String text) =>
          text.replaceAll(hiddenBlockPattern, '').trim();
      expect(shown('Hola ```gymia-activity\n{}\n```'), 'Hola');
      expect(shown('Hola ```trackia-activity\n{}\n```'), 'Hola');
      expect(shown('Hola ```trackia-sync\n{"parcial"'), 'Hola');
      expect(shown('Hola ```gymia-cualquier-cosa\n{}\n```'), 'Hola');
    });

    test('companion and game blocks are left to their own cards', () {
      const text = 'Hola ```trackia-companion\n{}\n```';
      expect(text.replaceAll(hiddenBlockPattern, ''), text);
    });
  });
}
