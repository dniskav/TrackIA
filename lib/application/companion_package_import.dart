import '../domain/activity.dart';
import '../domain/companion_package.dart';
import '../domain/reminder.dart';
import 'companion_creation.dart';

/// What the import changed or held back, for the preview screen.
enum ImportWarningKind {
  /// `trackia-*` / `gymia-*` blocks were removed from the instructions.
  appBlocksRemoved,

  /// The package asked for a mode other than «solo recordatorio»; the draft
  /// starts as a reminder and the person chooses.
  modeReset,

  /// The draft holds one activity; the others are listed but not applied.
  extraTemplatesNotApplied,

  /// The instructions look like an attempt to change the assistant's rules.
  suspiciousInstructions,

  /// Nothing was left of the instructions after removing the blocks.
  instructionsEmpty,
}

class ImportWarning {
  const ImportWarning(this.kind, {this.count = 0, this.detail = ''});

  final ImportWarningKind kind;

  /// Blocks removed, templates left out…
  final int count;
  final String detail;

  @override
  String toString() => '$kind($count)';
}

/// The result of reading a package: nothing is saved or applied.
class CompanionImportPreview {
  const CompanionImportPreview({
    required this.draft,
    required this.id,
    required this.templates,
    required this.declaredMode,
    required this.warnings,
    this.reminderCopy,
  });

  /// Always true: the content comes from outside and must be confirmed.
  bool get external => true;

  /// Editable draft: new identity, no permissions, no connections.
  final CompanionDraft draft;

  /// Id the new companion would get (free among the ids that were passed).
  final String id;

  /// All the package's templates, already cleaned (the draft holds the first).
  final List<PackageTemplate> templates;

  /// The package's own reminder texts, to be saved with the companion.
  final ReminderTemplates? reminderCopy;

  /// The mode the package declared, not the one the draft has.
  final String declaredMode;
  final List<ImportWarning> warnings;

  bool has(ImportWarningKind kind) => warnings.any((w) => w.kind == kind);
}

/// Reads a companion package into an editable draft (FR-018, FR-019). It has
/// no store, repository or network access: it cannot save, authorize or run
/// anything, whatever the package says.
class CompanionPackageImport {
  const CompanionPackageImport._();

  /// [text] is the QR text or the content of a `.trackia` file. Throws
  /// [CompanionPackageException] when the package is not acceptable.
  static CompanionImportPreview preview(
    String text, {
    Iterable<String> takenIds = const [],
  }) => fromPackage(CompanionPackage.decode(text), takenIds: takenIds);

  /// Same, from the bytes of a file.
  static CompanionImportPreview previewBytes(
    List<int> bytes, {
    Iterable<String> takenIds = const [],
  }) => fromPackage(CompanionPackage.decodeBytes(bytes), takenIds: takenIds);

  static CompanionImportPreview fromPackage(
    CompanionPackage package, {
    Iterable<String> takenIds = const [],
  }) {
    final warnings = <ImportWarning>[];
    var removed = 0;

    final cleaned = CompanionPackage.stripAppBlocks(package.instructions);
    removed += cleaned.removed;
    final instructions = cleaned.text.trim();

    final templates = <PackageTemplate>[];
    for (final t in package.templates) {
      final clean = CompanionPackage.stripAppBlocks(t.activity.instructions);
      removed += clean.removed;
      final text = clean.text.trim();
      templates.add(
        text == t.activity.instructions
            ? t
            : PackageTemplate(
                activity: ActivityDefinition.fromJson({
                  ...t.activity.toJson(),
                  'instructions': text,
                }),
                instant: t.instant,
              ),
      );
    }

    if (removed > 0) {
      warnings.add(
        ImportWarning(ImportWarningKind.appBlocksRemoved, count: removed),
      );
    }
    if (cleaned.removed > 0 && instructions.isEmpty) {
      warnings.add(const ImportWarning(ImportWarningKind.instructionsEmpty));
    }
    if (_suspicious.hasMatch(instructions) ||
        templates.any((t) => _suspicious.hasMatch(t.activity.instructions))) {
      warnings.add(
        const ImportWarning(ImportWarningKind.suspiciousInstructions),
      );
    }
    if (package.mode != 'reminder') {
      warnings.add(
        ImportWarning(ImportWarningKind.modeReset, detail: package.mode),
      );
    }
    if (templates.length > 1) {
      warnings.add(
        ImportWarning(
          ImportWarningKind.extraTemplatesNotApplied,
          count: templates.length - 1,
        ),
      );
    }

    final first = templates.isEmpty ? null : templates.first;
    final draft = CompanionDraft(
      name: package.name,
      description: package.description,
      prompt: instructions,
      icon: package.icon,
      color: package.color,
      // Never more than «solo recordatorio»: the person raises it by hand.
      mode: 'reminder',
      activity: first?.activity,
      instant: first?.instant ?? false,
      // No goal or schedule travels in a package: nothing is switched on.
      goal: null,
      reminder: null,
      origin: 'external',
    );
    return CompanionImportPreview(
      draft: draft,
      id: companionIdFor(package.name, takenIds),
      templates: List.unmodifiable(templates),
      reminderCopy: package.reminders,
      declaredMode: package.mode,
      warnings: List.unmodifiable(warnings),
    );
  }

  /// Phrases that try to override the assistant's rules, in Spanish and
  /// English. A hint for the preview, not a filter: the instructions are only
  /// ever style, whatever they say.
  static final _suspicious = RegExp(
    r'ignor[ae]\s+(todas?\s+)?(las\s+)?(instrucciones|reglas)|'
    r'ignore\s+(all\s+)?(previous|prior|the)\s+(instructions|rules)|'
    r'system\s+prompt|prompt\s+del\s+sistema|sin\s+pedir\s+confirmaci[oó]n|'
    r'without\s+(asking|confirmation)|revela\w*\s+(tus\s+)?(claves|instrucciones)|'
    r'concede\w*\s+permisos|reveal\s+(your|the)\s+(keys|system)',
    caseSensitive: false,
  );
}
