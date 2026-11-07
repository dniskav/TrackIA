import 'package:flutter/material.dart';

import '../application/localization.dart';

/// Una propuesta de la IA sobre una propiedad fija por el usuario (FR-023).
class LockedProposal {
  const LockedProposal(this.property, this.currentValue, this.proposedValue);
  final String property;
  final int currentValue;
  final int proposedValue;
}

/// Tarjeta «Aplicar / Ignorar» para propuestas sobre datos fijados a mano.
class ProposalCard extends StatelessWidget {
  const ProposalCard({
    super.key,
    required this.proposals,
    required this.onApply,
    required this.onIgnore,
  });
  final List<LockedProposal> proposals;
  final VoidCallback onApply;
  final VoidCallback onIgnore;

  String _label(BuildContext context, String p) {
    final t = appText(context);
    return switch (p) {
      'restSeconds' => t.activityRestLabel,
      'activitySeconds' => t.proposalLabelActivitySeconds,
      'targetCycles' => t.proposalLabelTargetCycles,
      _ => p,
    };
  }

  String _unit(BuildContext context, String p) {
    final t = appText(context);
    return p == 'targetCycles' ? t.proposalLabelUnitCycles : t.proposalLabelUnitSeconds;
  }

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('proposal-card'),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appText(context).proposalLockedTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final p in proposals)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                appText(context).proposalChangeLine(
                  _label(context, p.property),
                  p.currentValue,
                  _unit(context, p.property),
                  p.proposedValue,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                key: const Key('proposal-ignore'),
                onPressed: onIgnore,
                child: Text(appText(context).proposalIgnore),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: const Key('proposal-apply'),
                onPressed: onApply,
                child: Text(appText(context).proposalApply),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Candado junto a una propiedad que el usuario fijó a mano (FR-023): la IA solo
/// puede proponer cambios sobre ella. Tocarlo la libera.
class LockBadge extends StatelessWidget {
  const LockBadge({super.key, required this.onRelease});
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: appText(context).proposalLockLabel,
    excludeSemantics: true,
    onTap: onRelease,
    child: InkResponse(
      onTap: onRelease,
      radius: 18,
      child: const Padding(
        padding: EdgeInsets.all(6),
        child: Icon(Icons.lock_outline, size: 16),
      ),
    ),
  );
}
