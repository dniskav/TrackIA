import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/l10n/generated/app_localizations.dart';

const _arbDir = 'lib/l10n';
const _locales = ['es', 'en', 'ar'];

/// Longitud mínima para considerar que una coincidencia literal con el español
/// es una frase real (las etiquetas cortas como «OK» o «Ajustes» pueden coincidir).
const _minCopyLength = 26;

/// Umbral de frases largas con palabras en en/ar idénticas al español.
/// Medido el 2026-11-07 sobre los catálogos actuales: 0 coincidencias con
/// palabras (la única coincidencia, «proposalChangeLine», no tiene palabras y
/// se filtra). Por encima de este número el test falla y lista las claves.
const _maxLongCopies = 0;

/// Frases largas idénticas al español que son legítimas en en/ar
/// (nombres propios, marcas, URLs). Añadir aquí solo con justificación.
const _legitimateCopies = <String>{};

Map<String, dynamic> _loadArb(String locale) {
  final file = File('$_arbDir/app_$locale.arb');
  if (!file.existsSync()) throw StateError('Falta ${file.path}');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// Mensajes (claves sin `@`) de un catálogo ARB.
Map<String, String> _messages(Map<String, dynamic> arb) {
  final out = <String, String>{};
  for (final entry in arb.entries) {
    if (entry.key.startsWith('@')) continue;
    if (entry.value is! String) {
      fail('La clave "${entry.key}" no es texto');
    }
    out[entry.key] = entry.value as String;
  }
  return out;
}

/// Metadatos (claves `@clave`) de un catálogo ARB.
Map<String, Map<String, dynamic>> _metadata(Map<String, dynamic> arb) {
  final out = <String, Map<String, dynamic>>{};
  for (final entry in arb.entries) {
    if (!entry.key.startsWith('@@') && entry.key.startsWith('@')) {
      out[entry.key.substring(1)] = (entry.value as Map).cast<String, dynamic>();
    }
  }
  return out;
}

/// Nombres de parámetros de un mensaje ICU: `{nombre}`, `{n, plural, ...}` o
/// `{n, select, ...}`. El nombre del selector cuenta como parámetro (es el
/// valor que se pasa); las palabras de los ramales (`one`, `other`, el texto
/// de cada ramal) no. Los `{x}` dentro de un ramal sí se cuentan.
Set<String> placeholdersOf(String message) => _IcuScanner(message).run();

class _IcuScanner {
  _IcuScanner(this._s);

  final String _s;
  final Set<String> _names = {};
  int _i = 0;

  Set<String> run() {
    _parseMessage(nested: false);
    return _names;
  }

  void _parseMessage({required bool nested}) {
    while (_i < _s.length) {
      final c = _s[_i];
      if (c == '}' && nested) {
        _i++;
        return;
      }
      _i++;
      if (c == '{') _parseArgument();
    }
  }

  void _skipSpaces() {
    while (_i < _s.length && _s[_i].trim().isEmpty) {
      _i++;
    }
  }

  void _parseArgument() {
    final start = _i;
    while (_i < _s.length && _s[_i] != ',' && _s[_i] != '}') {
      _i++;
    }
    final name = _s.substring(start, _i).trim();
    if (name.isNotEmpty) _names.add(name);
    if (_i >= _s.length) return;
    if (_s[_i] == '}') {
      _i++;
      return;
    }
    _i++; // ','
    final typeStart = _i;
    while (_i < _s.length && _s[_i] != ',' && _s[_i] != '}') {
      _i++;
    }
    final type = _s.substring(typeStart, _i).trim();
    if (_i >= _s.length) return;
    if (_s[_i] == '}') {
      _i++;
      return;
    }
    _i++; // ',' antes de los ramales o del formato
    if (type != 'plural' && type != 'select' && type != 'selectordinal') {
      // Formato simple (number, date…): se salta hasta la llave de cierre.
      while (_i < _s.length && _s[_i] != '}') {
        _i++;
      }
      _i++;
      return;
    }
    // Ramales: `clave { mensaje }` repetidos hasta el `}` final del selector.
    while (true) {
      _skipSpaces();
      if (_i >= _s.length) return;
      if (_s[_i] == '}') {
        _i++;
        return;
      }
      while (_i < _s.length && _s[_i] != '{') {
        _i++;
      }
      _i++; // '{' del ramal
      _parseMessage(nested: true);
    }
  }
}

/// Hay letras (latinas o árabes) fuera de los {parámetros}.
bool _hasWords(String message) {
  final withoutParams = message.replaceAll(RegExp(r'\{[^{}]*\}'), ' ');
  return RegExp(r'[A-Za-zÀ-ɏ؀-ۿ]').hasMatch(withoutParams);
}

/// Devuelve un texto explicativo si las llaves `{}` no están balanceadas.
String? _unbalancedBraces(String message) {
  var depth = 0;
  for (var i = 0; i < message.length; i++) {
    if (message[i] == '{') depth++;
    if (message[i] == '}') depth--;
    if (depth < 0) return 'cierre "}" sin apertura en la posición $i';
  }
  if (depth != 0) return 'quedan $depth llave(s) "{" sin cerrar';
  return null;
}

void main() {
  final arbs = {for (final l in _locales) l: _loadArb(l)};
  final messages = {for (final l in _locales) l: _messages(arbs[l]!)};
  final metadata = {for (final l in _locales) l: _metadata(arbs[l]!)};
  final esKeys = messages['es']!.keys.toSet();

  group('catálogos ARB', () {
    test('es, en y ar tienen exactamente el mismo conjunto de claves', () {
      final problems = <String>[];
      for (final l in _locales) {
        final keys = messages[l]!.keys.toSet();
        for (final k in esKeys.difference(keys)) {
          problems.add('clave "$k" falta en $l');
        }
        for (final k in keys.difference(esKeys)) {
          problems.add('clave "$k" sobra en $l (no existe en es)');
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('es, en y ar tienen exactamente el mismo conjunto de claves @clave', () {
      final esMeta = metadata['es']!.keys.toSet();
      final problems = <String>[];
      for (final l in _locales) {
        final meta = metadata[l]!.keys.toSet();
        for (final k in esMeta.difference(meta)) {
          problems.add('metadatos "@$k" faltan en $l');
        }
        for (final k in meta.difference(esMeta)) {
          problems.add('metadatos "@$k" sobran en $l (no existen en es)');
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('ningún valor está vacío', () {
      final problems = <String>[];
      for (final l in _locales) {
        messages[l]!.forEach((k, v) {
          if (v.trim().isEmpty) problems.add('clave "$k" vacía en $l');
        });
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('los parámetros {nombre} coinciden entre es, en y ar', () {
      final problems = <String>[];
      for (final k in esKeys) {
        final expected = placeholdersOf(messages['es']![k]!);
        for (final l in ['en', 'ar']) {
          final actual = placeholdersOf(messages[l]![k]!);
          if (actual.length != expected.length || !actual.containsAll(expected)) {
            problems.add(
              'clave "$k" en $l: parámetros ${actual.toList()..sort()} '
              'distintos de es ${expected.toList()..sort()}',
            );
          }
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('los placeholders declarados en @clave aparecen en el texto es y viceversa', () {
      final problems = <String>[];
      metadata['es']!.forEach((k, meta) {
        final declared = meta['placeholders'];
        if (declared == null) return;
        final declaredNames = (declared as Map).keys.cast<String>().toSet();
        final inText = messages['es']![k] == null
            ? <String>{}
            : placeholdersOf(messages['es']![k]!);
        for (final p in declaredNames.difference(inText)) {
          problems.add('clave "$k": placeholder "$p" declarado pero no aparece en el texto es');
        }
        for (final p in inText.difference(declaredNames)) {
          problems.add('clave "$k": "{$p}" aparece en el texto es pero no está declarado');
        }
      });
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('las llaves {} están balanceadas en cada valor', () {
      final problems = <String>[];
      for (final l in _locales) {
        messages[l]!.forEach((k, v) {
          final error = _unbalancedBraces(v);
          if (error != null) problems.add('clave "$k" en $l: $error');
        });
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('en y ar no repiten frases largas del español (umbral medido)', () {
      final copies = <String>[];
      for (final k in esKeys) {
        final es = messages['es']![k]!;
        if (es.length < _minCopyLength) continue;
        // Sin palabras fuera de los {parámetros} (p. ej. «{a}: {b} → {c}») no hay
        // texto que traducir: la coincidencia es legítima.
        if (!_hasWords(es)) continue;
        for (final l in ['en', 'ar']) {
          if (messages[l]![k] == es && !_legitimateCopies.contains(es)) {
            copies.add('$l "$k": "$es"');
          }
        }
      }
      if (copies.isNotEmpty) {
        // ignore: avoid_print
        print('Frases largas idénticas al español (${copies.length}):\n'
            '${copies.join('\n')}');
      }
      expect(
        copies.length,
        lessThanOrEqualTo(_maxLongCopies),
        reason: 'Hay ${copies.length} frases largas idénticas al español; '
            'umbral $_maxLongCopies.\n${copies.join('\n')}',
      );
    });
  });

  group('recorrido AppLocalizations', () {
    const locales = {'es': Locale('es'), 'en': Locale('en'), 'ar': Locale('ar')};

    test('claves clave devuelven texto no vacío y distinto en cada idioma', () {
      final texts = <String, Map<String, String>>{};
      for (final entry in locales.entries) {
        final l10n = lookupAppLocalizations(entry.value);
        texts[entry.key] = {
          'appVersion': l10n.appVersion('0.3.33+36'),
          'settings': l10n.settings,
          'welcomeTitle': l10n.welcomeTitle,
          'helpWelcome': l10n.helpWelcome,
          'cancel': l10n.cancel,
          'save': l10n.save,
        };
      }
      for (final key in texts['es']!.keys) {
        final values = {for (final l in locales.keys) l: texts[l]![key]!};
        for (final e in values.entries) {
          expect(e.value.trim(), isNotEmpty, reason: '$key vacía en ${e.key}');
        }
        expect(values.values.toSet().length, values.length,
            reason: '$key no es distinta en es, en y ar: $values');
      }
    });

    test('welcomeStep(1, 5) contiene «1» y «5» en es, en y ar', () {
      for (final entry in locales.entries) {
        final text = lookupAppLocalizations(entry.value).welcomeStep(1, 5);
        expect(text, contains('1'), reason: 'welcomeStep en ${entry.key}: $text');
        expect(text, contains('5'), reason: 'welcomeStep en ${entry.key}: $text');
      }
    });
  });
}
