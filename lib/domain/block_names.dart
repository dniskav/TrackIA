/// The fenced blocks the assistant writes (```trackia-activity …```).
///
/// The app was called GymIA and asked for `gymia-*` blocks. It now asks for
/// `trackia-*`, but keeps reading both: archived chats and models that still
/// remember the old name must keep working.
const blockPrefix = 'trackia';
const _legacyBlockPrefix = 'gymia';

/// A block of [kind] with its JSON body in group 1, under either prefix.
RegExp blockPattern(String kind) => RegExp(
  '```(?:$blockPrefix|$_legacyBlockPrefix)-$kind\\s*\\n([\\s\\S]*?)```',
);

/// Whether the text opens a block of [kind], finished or not.
bool hasBlock(String text, String kind) => RegExp(
  '```(?:$blockPrefix|$_legacyBlockPrefix)-${RegExp.escape(kind)}(?=[\\s`]|\$)',
).hasMatch(text);

/// Blocks the user never sees as text. Every old `gymia-*` block, and the
/// `trackia-*` ones that are commands to the app (the game and companion
/// blocks are shown by their own cards).
final hiddenBlockPattern = RegExp(
  '```(?:$_legacyBlockPrefix-|$blockPrefix-'
  '(?:activity|activity-target|result|archive|recall|sync|sheet-plan|sheet-edit|timing))'
  r'[\s\S]*?(?:```|$)',
);
