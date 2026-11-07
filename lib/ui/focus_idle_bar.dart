part of 'activity_focus.dart';

/// The bar shown while the companion has no activity.
extension _ActivityIdleBar on _ActivityFocusControlsState {
  /// No activity: a thin bar that works without AI and offers to create one.
  Widget _idleBar(
    BuildContext context, {
    required bool blockedByOther,
    required bool enabled,
    required bool closingDay,
    required Widget finishButton,
    required Widget? restButton,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final compact = widget.compact;
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          blockedByOther ? appText(context).activityIdleOtherActive : appText(context).activityIdleNoActivity,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        if (!compact)
          Text(
            blockedByOther
                ? appText(context).activityIdleEndOther
                : appText(context).activityIdleRegisterAnytime,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
      ],
    );
    final newButton = OutlinedButton.icon(
      key: const Key('new-activity'),
      onPressed: enabled ? choose : null,
      icon: const Icon(Icons.add),
      label: Text(appText(context).activityNewActivity),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
    );
    // Closing the day or resting adds buttons; they wrap instead of overflowing
    // on narrow screens or with large system fonts.
    final extras = [
      if (restButton != null) restButton,
      if (closingDay) finishButton,
      if (instantTemplates.isNotEmpty && !blockedByOther)
        OutlinedButton.icon(
          key: const Key('record-instant'),
          onPressed: enabled ? startInstantRecord : null,
          icon: const Icon(Icons.edit_note),
          label: Text(appText(context).activityIdleRecord),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: title),
                if (!blockedByOther && extras.isEmpty)
                  Flexible(child: newButton),
              ],
            ),
            if (extras.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [...extras, if (!blockedByOther) newButton],
                ),
              ),
            if (c.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  c.error!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
