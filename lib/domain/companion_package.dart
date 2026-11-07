import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'activity.dart';
import 'assistant_blocks.dart';
import 'block_names.dart';
import 'companion.dart';
import 'reminder.dart';
import 'workout.dart';

/// Why a companion package was rejected.
enum CompanionPackageProblem {
  /// Empty text or file.
  empty,

  /// The encoded text or the compressed bytes exceed the limit.
  tooLarge,

  /// Not valid base64url or not valid UTF-8.
  badEncoding,

  /// Not valid gzip.
  badCompression,

  /// The decompressed content exceeds the limit (possible compression bomb).
  tooLargeExpanded,

  /// Not valid JSON, or not a JSON object.
  malformed,

  /// A JSON object that is not a companion package (no `format`).
  notAPackage,

  /// `format` names a version this app does not know.
  unsupportedVersion,

  /// The `checksum` does not match the content.
  checksumMismatch,

  /// A field that must never travel in a package (keys, chats, memory…).
  forbiddenField,

  /// A field that is not in the allowed list.
  unknownField,

  /// A required field is missing.
  missingField,

  /// A field has the wrong type, an unknown value or exceeds its limit.
  invalidField,
}

class CompanionPackageException implements Exception {
  const CompanionPackageException(this.problem, this.message, {this.field});

  final CompanionPackageProblem problem;

  /// Internal message in Spanish; the UI localizes its own text by [problem].
  final String message;

  /// The offending field, when there is one.
  final String? field;

  @override
  String toString() => message;
}

/// Numeric limits of `trackia-companion/1` (`contracts/contratos.md`).
class CompanionPackageLimits {
  const CompanionPackageLimits._();

  // Same as the creator's text fields (companion_creator.dart).
  static const nameChars = 40;
  static const descriptionChars = 80;
  static const instructionsChars = 4000;

  static const maxTemplates = 5;
  static const templateNameChars = 80;
  static const templateInstructionsChars = 1500;
  static const reminderTextsPerList = 5;
  static const reminderTextChars = 140;

  /// Largest JSON a package may expand to.
  static const maxJsonBytes = 64 * 1024;

  /// Largest gzip stream.
  static const maxCompressedBytes = 32 * 1024;

  /// Longest base64url text (no padding) of [maxCompressedBytes].
  static const maxEncodedChars = (maxCompressedBytes * 8 + 5) ~/ 6 + 4;

  /// Longest text that is still offered as a QR code.
  static const qrMaxChars = 2000;
}

/// An activity template of a package: the definition and whether the activity
/// is instant (no timer).
class PackageTemplate {
  const PackageTemplate({required this.activity, this.instant = false});

  final ActivityDefinition activity;
  final bool instant;

  /// Only the allowed fields; local identity, origin, locks and progress never
  /// leave.
  Map<String, Object?> toBody() => {
    'name': activity.name,
    'repeated': activity.repeated,
    'restSeconds': activity.restSeconds,
    if (activity.activitySeconds != null)
      'activitySeconds': activity.activitySeconds,
    if (activity.targetSets != null) 'targetSets': activity.targetSets,
    if (activity.targetCycles != null) 'targetCycles': activity.targetCycles,
    'fields': [for (final f in activity.fields) Map<String, Object>.of(f)],
    'instructions': activity.instructions,
    if (activity.segmentSingular != null)
      'segmentSingular': activity.segmentSingular,
    if (activity.segmentPlural != null) 'segmentPlural': activity.segmentPlural,
    'instant': instant,
  };
}

/// A shareable companion configuration (`trackia-companion/1`). Immutable and
/// always valid: the constructor applies every limit, so a value of this type
/// can only come from the exporter or from a strictly validated package.
class CompanionPackage {
  CompanionPackage({
    required this.name,
    required this.icon,
    required this.color,
    this.description = '',
    this.instructions = '',
    this.mode = 'reminder',
    List<PackageTemplate> templates = const [],
    this.reminders,
  }) : templates = List.unmodifiable(templates) {
    _validate();
  }

  static const format = 'trackia-companion/1';

  /// Exactly the keys a package may carry, besides `format` and `checksum`.
  static const allowedKeys = {
    'name',
    'icon',
    'color',
    'description',
    'instructions',
    'mode',
    'templates',
    'reminders',
  };

  static const _templateKeys = {
    'name',
    'repeated',
    'restSeconds',
    'activitySeconds',
    'targetSets',
    'targetCycles',
    'fields',
    'instructions',
    'segmentSingular',
    'segmentPlural',
    'instant',
  };
  static const _templateRequired = {
    'name',
    'repeated',
    'restSeconds',
    'fields',
    'instructions',
    'instant',
  };

  /// Names that must never appear in a package, whatever their value. They
  /// get a specific error; any other unknown key is also rejected.
  static const forbiddenKeys = {
    'apikey',
    'api_key',
    'key',
    'token',
    'accesstoken',
    'refreshtoken',
    'secret',
    'password',
    'chats',
    'chat',
    'messages',
    'history',
    'memory',
    'memories',
    'sheetid',
    'spreadsheetid',
    'sheet',
    'accountid',
    'account',
    'email',
    'profileid',
    'userid',
    'user',
    'id',
    'companionid',
    'spaceid',
    'usage',
    'stats',
    'progress',
    'achievements',
    'goals',
    'permissions',
    'connections',
    'settings',
  };

  final String name, icon, color, description, instructions, mode;
  final List<PackageTemplate> templates;

  /// The companion's own reminder texts; null when it has none.
  final ReminderTemplates? reminders;

  // ---------------------------------------------------------------- build

  /// The package of [companion]: only allowed fields, whatever else the
  /// companion or its settings hold. App blocks are removed from the
  /// instructions. Throws when something exceeds a limit.
  factory CompanionPackage.fromCompanion(
    Companion companion, {
    String mode = 'reminder',
    List<PackageTemplate> templates = const [],
    ReminderTemplates? reminders,
  }) => CompanionPackage(
    name: companion.name,
    icon: companion.icon,
    color: companion.color,
    description: companion.description,
    instructions: stripAppBlocks(companion.prompt).text.trim(),
    mode: mode,
    templates: [
      for (final t in templates)
        PackageTemplate(
          activity: _withoutBlocks(t.activity),
          instant: t.instant,
        ),
    ],
    reminders: reminders ?? companion.reminderCopy,
  );

  static ActivityDefinition _withoutBlocks(ActivityDefinition a) {
    final clean = stripAppBlocks(a.instructions).text.trim();
    if (clean == a.instructions) return a;
    return ActivityDefinition.fromJson({...a.toJson(), 'instructions': clean});
  }

  /// Removes every fenced `trackia-*` / `gymia-*` block (finished or not, with
  /// or without a space after the fence) from [text]. It repeats until nothing
  /// is left, so removing one block cannot leave another one formed.
  static ({String text, int removed}) stripAppBlocks(String text) {
    final pattern = RegExp(
      '$fenceOpen(?:$blockPrefix|gymia)-[\\s\\S]*?(?:```|\$)',
      caseSensitive: false,
    );
    var current = text;
    var removed = 0;
    for (var i = 0; i < 20; i++) {
      final count = pattern.allMatches(current).length;
      if (count == 0) break;
      removed += count;
      current = current.replaceAll(pattern, '');
    }
    return (text: current, removed: removed);
  }

  // ------------------------------------------------------------ validation

  static final _control = RegExp(
    r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]',
  );
  static final _lineBreak = RegExp(r'[\n\r\t]');

  static Never _fail(
    CompanionPackageProblem problem,
    String message, [
    String? field,
  ]) => throw CompanionPackageException(problem, message, field: field);

  static void _text(
    String field,
    String value, {
    required int max,
    bool required = false,
    bool multiline = false,
  }) {
    if (value.length > max) {
      _fail(
        CompanionPackageProblem.invalidField,
        'El campo «$field» supera los $max caracteres.',
        field,
      );
    }
    if (required && value.trim().isEmpty) {
      _fail(
        CompanionPackageProblem.invalidField,
        'El campo «$field» no puede estar vacío.',
        field,
      );
    }
    if (_control.hasMatch(value) ||
        (!multiline && _lineBreak.hasMatch(value))) {
      _fail(
        CompanionPackageProblem.invalidField,
        'El campo «$field» tiene caracteres no permitidos.',
        field,
      );
    }
  }

  void _validate() {
    _text('name', name, max: CompanionPackageLimits.nameChars, required: true);
    _text(
      'description',
      description,
      max: CompanionPackageLimits.descriptionChars,
    );
    _text(
      'instructions',
      instructions,
      max: CompanionPackageLimits.instructionsChars,
      multiline: true,
    );
    if (!Companion.iconIds.contains(icon)) {
      _fail(
        CompanionPackageProblem.invalidField,
        'El icono del paquete no es válido.',
        'icon',
      );
    }
    if (!Companion.colorIds.contains(color)) {
      _fail(
        CompanionPackageProblem.invalidField,
        'El color del paquete no es válido.',
        'color',
      );
    }
    if (!CompanionProposal.modes.contains(mode)) {
      _fail(
        CompanionPackageProblem.invalidField,
        'El modo del paquete no es válido.',
        'mode',
      );
    }
    if (templates.length > CompanionPackageLimits.maxTemplates) {
      _fail(
        CompanionPackageProblem.invalidField,
        'El paquete tiene más de ${CompanionPackageLimits.maxTemplates} plantillas.',
        'templates',
      );
    }
    for (final t in templates) {
      _text(
        'templates.name',
        t.activity.name,
        max: CompanionPackageLimits.templateNameChars,
        required: true,
      );
      _text(
        'templates.instructions',
        t.activity.instructions,
        max: CompanionPackageLimits.templateInstructionsChars,
        multiline: true,
      );
      for (final f in t.activity.fields) {
        for (final v in f.values) {
          if (v is String) _text('templates.fields', v, max: 80);
          if (v is List) {
            for (final o in v) {
              _text('templates.fields', '$o', max: 80);
            }
          }
        }
      }
    }
    final copy = reminders;
    if (copy != null) {
      final lists = {
        'windowStart': copy.windowStart,
        'lastCall': copy.lastCall,
        'inactive': copy.inactive,
      };
      for (final entry in lists.entries) {
        if (entry.value.length > CompanionPackageLimits.reminderTextsPerList) {
          _fail(
            CompanionPackageProblem.invalidField,
            'Los avisos «${entry.key}» superan el máximo de '
                '${CompanionPackageLimits.reminderTextsPerList} textos.',
            'reminders',
          );
        }
        for (final text in entry.value) {
          _text(
            'reminders.${entry.key}',
            text,
            max: CompanionPackageLimits.reminderTextChars,
            required: true,
          );
        }
      }
    }
    // The app's own validation has the last word.
    try {
      Companion(
        id: 'import',
        name: name,
        description: description,
        prompt: instructions,
        icon: icon,
        color: color,
        reminderCopy: reminders,
      );
    } on FormatException catch (e) {
      _fail(CompanionPackageProblem.invalidField, e.message);
    } on ValidationException catch (e) {
      _fail(CompanionPackageProblem.invalidField, e.message);
    }
  }

  // --------------------------------------------------------------- encode

  /// The content, without `format` and `checksum`.
  Map<String, Object?> toBody() => {
    'name': name,
    'icon': icon,
    'color': color,
    'description': description,
    'instructions': instructions,
    'mode': mode,
    'templates': [for (final t in templates) t.toBody()],
    'reminders': {
      'windowStart': reminders?.windowStart ?? const <String>[],
      'lastCall': reminders?.lastCall ?? const <String>[],
      'inactive': reminders?.inactive ?? const <String>[],
    },
  };

  /// JSON of the whole package, with sorted keys and no spaces.
  String toCanonicalJson() => canonicalJson({
    'format': format,
    ...toBody(),
    'checksum': checksumOf(toBody()),
  });

  /// sha256 (lowercase hex) of the canonical JSON of the content: the package
  /// without `checksum` and with `format` included, so a change of version
  /// also changes it.
  static String checksumOf(Map<String, Object?> body) => sha256
      .convert(utf8.encode(canonicalJson({'format': format, ...body})))
      .toString();

  /// JSON with keys sorted at every level and no whitespace.
  static String canonicalJson(Object? value) => jsonEncode(_sorted(value));

  static Object? _sorted(Object? v) {
    if (v is Map) {
      final keys = v.keys.cast<String>().toList()..sort();
      return {for (final k in keys) k: _sorted(v[k])};
    }
    if (v is List) return [for (final e in v) _sorted(e)];
    return v;
  }

  /// gzip of the canonical JSON.
  Uint8List encodeBytes() {
    final bytes = Uint8List.fromList(
      gzip.encode(utf8.encode(toCanonicalJson())),
    );
    if (bytes.length > CompanionPackageLimits.maxCompressedBytes) {
      _fail(
        CompanionPackageProblem.tooLarge,
        'El paquete comprimido supera '
        '${CompanionPackageLimits.maxCompressedBytes ~/ 1024} KB.',
      );
    }
    return bytes;
  }

  /// base64url (no padding) of [encodeBytes]: the text of the QR and the
  /// content of a `.trackia` file.
  String encode() => base64Url.encode(encodeBytes()).replaceAll('=', '');

  /// Whether [encoded] is short enough to offer a QR code.
  static bool fitsInQr(String encoded) =>
      encoded.length <= CompanionPackageLimits.qrMaxChars;

  // --------------------------------------------------------------- decode

  /// Decodes the text of a QR or of a `.trackia` file (base64url).
  static CompanionPackage decode(String text) {
    final clean = text.trim();
    if (clean.isEmpty) {
      _fail(CompanionPackageProblem.empty, 'El paquete está vacío.');
    }
    if (clean.length > CompanionPackageLimits.maxEncodedChars) {
      _fail(
        CompanionPackageProblem.tooLarge,
        'El paquete es demasiado grande.',
      );
    }
    if (!RegExp(r'^[A-Za-z0-9_-]+={0,2}$').hasMatch(clean)) {
      _fail(
        CompanionPackageProblem.badEncoding,
        'El texto del paquete no es base64 válido.',
      );
    }
    final Uint8List bytes;
    try {
      bytes = base64Url.decode(base64Url.normalize(clean));
    } on FormatException {
      _fail(
        CompanionPackageProblem.badEncoding,
        'El texto del paquete no es base64 válido.',
      );
    }
    return _fromGzip(bytes);
  }

  /// Decodes a file's bytes: a gzip stream, or the UTF-8 text of [decode].
  static CompanionPackage decodeBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      _fail(CompanionPackageProblem.empty, 'El paquete está vacío.');
    }
    final isGzip = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
    if (isGzip) return _fromGzip(bytes);
    if (bytes.length > CompanionPackageLimits.maxEncodedChars * 2) {
      _fail(
        CompanionPackageProblem.tooLarge,
        'El paquete es demasiado grande.',
      );
    }
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      _fail(
        CompanionPackageProblem.badEncoding,
        'El archivo no es un paquete válido.',
      );
    }
    return decode(text);
  }

  static CompanionPackage _fromGzip(List<int> compressed) {
    if (compressed.length > CompanionPackageLimits.maxCompressedBytes) {
      _fail(
        CompanionPackageProblem.tooLarge,
        'El paquete comprimido es demasiado grande.',
      );
    }
    if (compressed.length < 18 ||
        compressed[0] != 0x1f ||
        compressed[1] != 0x8b) {
      _fail(
        CompanionPackageProblem.badCompression,
        'El paquete no está comprimido correctamente.',
      );
    }
    final json = _gunzipLimited(compressed);
    final String text;
    try {
      text = utf8.decode(json);
    } on FormatException {
      _fail(
        CompanionPackageProblem.badEncoding,
        'El contenido del paquete no es texto UTF-8 válido.',
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      _fail(CompanionPackageProblem.malformed, 'El paquete no es JSON válido.');
    }
    return fromJson(decoded);
  }

  /// Decompresses without ever holding more than the limit: it stops as soon
  /// as the output passes [CompanionPackageLimits.maxJsonBytes].
  static Uint8List _gunzipLimited(List<int> compressed) {
    final out = BytesBuilder(copy: false);
    final sink = _LimitedSink(out, CompanionPackageLimits.maxJsonBytes);
    try {
      final input = gzip.decoder.startChunkedConversion(sink);
      const step = 512;
      for (var i = 0; i < compressed.length; i += step) {
        final end = i + step > compressed.length ? compressed.length : i + step;
        input.add(compressed.sublist(i, end));
      }
      input.close();
    } on _TooLarge {
      _fail(
        CompanionPackageProblem.tooLargeExpanded,
        'El contenido del paquete es demasiado grande al descomprimirlo.',
      );
    } catch (_) {
      _fail(
        CompanionPackageProblem.badCompression,
        'El paquete está dañado o no está comprimido correctamente.',
      );
    }
    final bytes = out.takeBytes();
    // The gzip trailer repeats the original length: a cut stream does not
    // match it (Dart's decoder accepts truncated input silently).
    final n = compressed.length;
    final declared =
        compressed[n - 4] |
        compressed[n - 3] << 8 |
        compressed[n - 2] << 16 |
        compressed[n - 1] << 24;
    if (declared != bytes.length) {
      _fail(
        CompanionPackageProblem.badCompression,
        'El paquete está dañado o incompleto.',
      );
    }
    return bytes;
  }

  /// Strict validation of a decoded JSON value.
  static CompanionPackage fromJson(Object? json) {
    if (json is! Map) {
      _fail(CompanionPackageProblem.malformed, 'El paquete no es un objeto.');
    }
    final map = Map<String, Object?>.from(json);
    final declared = map['format'];
    if (declared is! String) {
      _fail(
        CompanionPackageProblem.notAPackage,
        'El archivo no es un paquete de acompañante.',
      );
    }
    final version = RegExp(
      r'^trackia-companion/(\d{1,9})$',
    ).firstMatch(declared);
    if (version == null) {
      _fail(
        CompanionPackageProblem.notAPackage,
        'El archivo no es un paquete de acompañante.',
        'format',
      );
    }
    if (version.group(1) != '1') {
      _fail(
        CompanionPackageProblem.unsupportedVersion,
        'Este paquete es de una versión que esta app no conoce ($declared). '
            'Actualiza TrackIA para importarlo.',
        'format',
      );
    }
    _checkKeys(map);
    final checksum = map['checksum'];
    final body = Map<String, Object?>.of(map)
      ..remove('format')
      ..remove('checksum');
    if (checksum is! String || checksum != checksumOf(body)) {
      _fail(
        CompanionPackageProblem.checksumMismatch,
        'El paquete está dañado o fue modificado (la suma de control no coincide).',
        'checksum',
      );
    }
    try {
      return _build(body);
    } on CompanionPackageException {
      rethrow;
    } on Object catch (e) {
      if (e is ValidationException) {
        _fail(CompanionPackageProblem.invalidField, e.message);
      }
      _fail(
        CompanionPackageProblem.invalidField,
        'Algún campo del paquete no tiene el tipo esperado.',
      );
    }
  }

  static void _checkKeys(Map<String, Object?> map) {
    for (final key in map.keys) {
      if (key == 'format' || key == 'checksum' || allowedKeys.contains(key)) {
        continue;
      }
      if (forbiddenKeys.contains(key.toLowerCase())) {
        _fail(
          CompanionPackageProblem.forbiddenField,
          'El paquete incluye un campo que nunca debe compartirse («$key»).',
          key,
        );
      }
      _fail(
        CompanionPackageProblem.unknownField,
        'El paquete incluye un campo desconocido («$key»).',
        key,
      );
    }
    for (final key in [...allowedKeys, 'checksum']) {
      if (!map.containsKey(key)) {
        _fail(
          CompanionPackageProblem.missingField,
          'Al paquete le falta el campo «$key».',
          key,
        );
      }
    }
  }

  static T _typed<T>(Object? value, String field) {
    if (value is! T) {
      _fail(
        CompanionPackageProblem.invalidField,
        'El campo «$field» no tiene el tipo esperado.',
        field,
      );
    }
    return value;
  }

  static CompanionPackage _build(Map<String, Object?> body) {
    final templatesRaw = _typed<List>(body['templates'], 'templates');
    if (templatesRaw.length > CompanionPackageLimits.maxTemplates) {
      _fail(
        CompanionPackageProblem.invalidField,
        'El paquete tiene más de ${CompanionPackageLimits.maxTemplates} plantillas.',
        'templates',
      );
    }
    final templates = <PackageTemplate>[];
    for (final raw in templatesRaw) {
      final t = Map<String, Object?>.from(_typed<Map>(raw, 'templates'));
      for (final key in t.keys) {
        if (!_templateKeys.contains(key)) {
          _fail(
            CompanionPackageProblem.unknownField,
            'Una plantilla incluye un campo desconocido («$key»).',
            'templates.$key',
          );
        }
      }
      for (final key in _templateRequired) {
        if (!t.containsKey(key)) {
          _fail(
            CompanionPackageProblem.missingField,
            'A una plantilla le falta el campo «$key».',
            'templates.$key',
          );
        }
      }
      final fields = _typed<List>(t['fields'], 'templates.fields');
      final activity = ActivityDefinition(
        name: _typed<String>(t['name'], 'templates.name'),
        repeated: _typed<bool>(t['repeated'], 'templates.repeated'),
        restSeconds: _typed<int>(t['restSeconds'], 'templates.restSeconds'),
        activitySeconds: t['activitySeconds'] == null
            ? null
            : _typed<int>(t['activitySeconds'], 'templates.activitySeconds'),
        targetSets: t['targetSets'] == null
            ? null
            : _typed<int>(t['targetSets'], 'templates.targetSets'),
        targetCycles: t['targetCycles'] == null
            ? null
            : _typed<int>(t['targetCycles'], 'templates.targetCycles'),
        fields: [
          for (final f in fields)
            Map<String, Object>.from(_typed<Map>(f, 'templates.fields')),
        ],
        instructions: _typed<String>(
          t['instructions'],
          'templates.instructions',
        ),
        segmentSingular: t.containsKey('segmentSingular')
            ? _typed<String>(t['segmentSingular'], 'templates.segmentSingular')
            : null,
        segmentPlural: t.containsKey('segmentPlural')
            ? _typed<String>(t['segmentPlural'], 'templates.segmentPlural')
            : null,
      );
      templates.add(
        PackageTemplate(
          activity: activity,
          instant: _typed<bool>(t['instant'], 'templates.instant'),
        ),
      );
    }
    final rem = Map<String, Object?>.from(
      _typed<Map>(body['reminders'], 'reminders'),
    );
    const remKeys = {'windowStart', 'lastCall', 'inactive'};
    if (rem.keys.toSet().difference(remKeys).isNotEmpty ||
        !rem.keys.toSet().containsAll(remKeys)) {
      _fail(
        CompanionPackageProblem.invalidField,
        'Los avisos del paquete no tienen la forma esperada.',
        'reminders',
      );
    }
    List<String> texts(String key) => [
      for (final e in _typed<List>(rem[key], 'reminders.$key'))
        _typed<String>(e, 'reminders.$key'),
    ];
    final copy = ReminderTemplates(
      windowStart: texts('windowStart'),
      lastCall: texts('lastCall'),
      inactive: texts('inactive'),
    );
    final empty =
        copy.windowStart.isEmpty &&
        copy.lastCall.isEmpty &&
        copy.inactive.isEmpty;
    return CompanionPackage(
      name: _typed<String>(body['name'], 'name'),
      icon: _typed<String>(body['icon'], 'icon'),
      color: _typed<String>(body['color'], 'color'),
      description: _typed<String>(body['description'], 'description'),
      instructions: _typed<String>(body['instructions'], 'instructions'),
      mode: _typed<String>(body['mode'], 'mode'),
      templates: templates,
      reminders: empty ? null : copy,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CompanionPackage &&
      canonicalJson(toBody()) == canonicalJson(other.toBody());

  @override
  int get hashCode => canonicalJson(toBody()).hashCode;
}

class _TooLarge implements Exception {
  const _TooLarge();
}

class _LimitedSink implements Sink<List<int>> {
  _LimitedSink(this._out, this._max);

  final BytesBuilder _out;
  final int _max;

  @override
  void add(List<int> data) {
    if (_out.length + data.length > _max) throw const _TooLarge();
    _out.add(data);
  }

  @override
  void close() {}
}
