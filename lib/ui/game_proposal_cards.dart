import 'package:flutter/material.dart';

import '../application/localization.dart';

/// What a card of the chat asks the user to accept: a goal, an achievement or
/// reminder texts the AI proposed (FR-036). Nothing is saved until «Añadir».
class GameProposalData {
  const GameProposalData({
    required this.kind,
    required this.title,
    required this.lines,
    required this.payload,
  });

  /// `goal`, `achievement` or `copy`.
  final String kind;
  final String title;
  final List<String> lines;
  final Object payload;
}

class GameProposalCard extends StatelessWidget {
  const GameProposalCard({
    super.key,
    required this.data,
    required this.onAdd,
    required this.onIgnore,
    this.busy = false,
  });

  final GameProposalData data;
  final VoidCallback onAdd, onIgnore;
  final bool busy;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('game-proposal-${data.kind}'),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          for (final line in data.lines)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text(line)),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                key: Key('game-ignore-${data.kind}'),
                onPressed: busy ? null : onIgnore,
                child: Text(appText(context).proposalIgnore),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: Key('game-add-${data.kind}'),
                onPressed: busy ? null : onAdd,
                child: Text(
                  data.kind == 'copy'
                      ? appText(context).proposalUseTexts
                      : appText(context).proposalAdd,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// The one-off offer to switch a reminder companion to game mode (research D15).
class GameSuggestionCard extends StatelessWidget {
  const GameSuggestionCard({
    super.key,
    required this.onActivate,
    required this.onLater,
    required this.onNever,
  });

  static const text =
      'Llevas varios días seguidos cumpliendo. ¿Quieres activar el modo Juego para ver metas, rachas y logros?';

  final VoidCallback onActivate, onLater, onNever;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('game-suggestion'),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(text),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                key: const Key('suggest-activate'),
                onPressed: onActivate,
                child: Text(appText(context).activityEnableNotices),
              ),
              OutlinedButton(
                key: const Key('suggest-later'),
                onPressed: onLater,
                child: Text(appText(context).proposalSuggestLater),
              ),
              TextButton(
                key: const Key('suggest-never'),
                onPressed: onNever,
                child: Text(appText(context).proposalSuggestNever),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
