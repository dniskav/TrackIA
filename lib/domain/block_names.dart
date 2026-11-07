import 'dart:convert';

/// The fenced blocks the assistant writes (```trackia-activity …```).
///
/// The app was called GymIA and asked for `gymia-*` blocks. It now asks for
/// `trackia-*`, but keeps reading both: archived chats and models that still
/// remember the old name must keep working.
const blockPrefix = 'trackia';
const _legacyBlockPrefix = 'gymia';

/// Apertura de un bloque: tres acentos graves y, a veces, un espacio antes del
/// nombre (los modelos escriben «``` trackia-sheet-plan»), que también cuenta.
const fenceOpen = r'```[ \t]*';

/// A block of [kind] with its JSON body in group 1, under either prefix.
RegExp blockPattern(String kind) => RegExp(
  '$fenceOpen(?:$blockPrefix|$_legacyBlockPrefix)-$kind\\s*\\n([\\s\\S]*?)```',
);

/// Whether the text opens a block of [kind], finished or not.
bool hasBlock(String text, String kind) => RegExp(
  '$fenceOpen(?:$blockPrefix|$_legacyBlockPrefix)-${RegExp.escape(kind)}(?=[\\s`]|\$)',
).hasMatch(text);

/// Blocks the user never sees as text. Every old `gymia-*` block, and the
/// `trackia-*` ones that are commands to the app (the game and companion
/// blocks are shown by their own cards).
final hiddenBlockPattern = RegExp(
  '$fenceOpen(?:$_legacyBlockPrefix-|$blockPrefix-'
  '(?:activity|activity-target|result|archive|recall|sync|sheet-plan|sheet-edit|timing))'
  r'[\s\S]*?(?:```|$)',
);

/// Claves de un plan de Google Sheets (en español o inglés) que un modelo a
/// veces escribe como JSON suelto en lugar de usar el bloque `trackia-sheet-plan`.
const _strayPlanKeys = {'summary', 'resumen', 'writes', 'layout'};

final _fencedJson = RegExp(
  r'```[ \t]*[A-Za-z0-9_-]*[ \t]*\n(\s*\{[\s\S]*?\})\s*```',
);

/// Quita del texto visible los bloques de código con un JSON de plan que la app
/// no reconoce: no son para el usuario y se veían como texto en crudo.
/// Los bloques de código normales (otro contenido) se conservan.
String stripStrayPlanJson(String text) =>
    text.replaceAllMapped(_fencedJson, (m) {
      try {
        final json = jsonDecode(m[1]!);
        if (json is Map && json.keys.any(_strayPlanKeys.contains)) return '';
      } catch (_) {}
      return m[0]!;
    });
