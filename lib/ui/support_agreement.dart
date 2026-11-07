import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../application/localization.dart';
import '../application/support_agreement_service.dart';
import '../data/support_agreement_repository.dart';
import '../domain/support_agreement.dart';

/// Pantalla de acuerdos de apoyo del acompañante (feature 005, US5).
///
/// Los acuerdos solo se crean con consentimiento explícito y solo se anota lo
/// que la persona registra a mano: no se vigila ninguna otra app. Los avisos
/// del acompañante (`ReminderScheduler`) son por acompañante y no por acuerdo,
/// por lo que aquí solo se muestra el texto libre `reminder` del acuerdo.
class SupportAgreementScreen extends StatefulWidget {
  const SupportAgreementScreen({
    super.key,
    required this.repository,
    this.service = const SupportAgreementService(),
    this.now = DateTime.now,
    this.newId = _uuid,
  });

  final SupportAgreementRepository repository;
  final SupportAgreementService service;
  final DateTime Function() now;
  final String Function() newId;

  @override
  State<SupportAgreementScreen> createState() => _SupportAgreementScreenState();
}

String _uuid() => const Uuid().v4();

class _SupportAgreementScreenState extends State<SupportAgreementScreen> {
  List<SupportAgreement>? agreements;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await widget.repository.list();
      if (!mounted) return;
      setState(() {
        agreements = all;
        failed = false;
      });
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  Future<void> _create() async {
    final form = await showDialog<_AgreementFormResult>(
      context: context,
      builder: (_) => const _AgreementFormDialog(),
    );
    if (form == null || !mounted) return;
    try {
      final proposal = widget.service.parseProposal(
        {
          'action': 'create',
          'objective': form.objective,
          if (form.unit != null) 'unit': form.unit,
          if (form.target != null) 'target': form.target,
        },
        profileId: widget.repository.scope.profileId,
        companionId: widget.repository.scope.companionId,
        sourceMessageId: 'manual',
      );
      final agreement = proposal == null
          ? null
          : widget.service.accept(
              proposal,
              userConsented: form.consented,
              id: widget.newId(),
              revisionId: widget.newId(),
              at: widget.now(),
            );
      if (agreement == null) throw StateError('rejected');
      await widget.repository.save(agreement);
    } catch (_) {
      if (mounted) _snack(appText(context).agreementSaveError);
      return;
    }
    await _load();
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _open(SupportAgreement agreement) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _AgreementDetail(
          initial: agreement,
          repository: widget.repository,
          service: widget.service,
          now: widget.now,
          newId: widget.newId,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final text = appText(context);
    final all = agreements;
    return Scaffold(
      appBar: AppBar(title: Text(text.agreementTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('agreement-new'),
        onPressed: all == null ? null : _create,
        icon: const Icon(Icons.add),
        label: Text(text.agreementNew),
      ),
      body: failed
          ? Center(child: Text(text.agreementLoadError))
          : all == null
          ? const Center(child: CircularProgressIndicator())
          : all.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  text.agreementEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                for (final status in SupportAgreementStatus.values)
                  ..._section(status, all),
              ],
            ),
    );
  }

  List<Widget> _section(
    SupportAgreementStatus status,
    List<SupportAgreement> all,
  ) {
    final items = all.where((a) => a.status == status).toList();
    if (items.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
        child: Text(
          _statusLabel(context, status),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      for (final a in items)
        ListTile(
          key: Key('agreement-${a.id}'),
          title: Text(a.objective, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: _measure(context, a) == null
              ? null
              : Text(_measure(context, a)!),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(a),
        ),
    ];
  }
}

String _statusLabel(BuildContext context, SupportAgreementStatus status) {
  final text = appText(context);
  return switch (status) {
    SupportAgreementStatus.active => text.agreementStatusActive,
    SupportAgreementStatus.paused => text.agreementStatusPaused,
    SupportAgreementStatus.completed => text.agreementStatusCompleted,
  };
}

String _number(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

String? _measure(BuildContext context, SupportAgreement a) {
  if (a.target == null) return null;
  final unit = a.unit == null ? '' : ' ${a.unit}';
  return '${appText(context).agreementMeasureLabel}: ${_number(a.target!)}$unit';
}

String _date(BuildContext context, DateTime value) {
  try {
    final locale = Localizations.maybeLocaleOf(context)?.toString();
    return DateFormat.yMd(locale).add_Hm().format(value.toLocal());
  } catch (_) {
    return value.toLocal().toString();
  }
}

/// Número finito y no negativo, o `null` si el texto no es válido.
/// Un texto vacío se trata por separado (medida opcional).
double? _parseMeasure(String raw) {
  final value = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite || value < 0) return null;
  return value;
}

class _AgreementFormResult {
  const _AgreementFormResult({
    required this.objective,
    this.unit,
    this.target,
    this.consented = false,
  });

  final String objective;
  final String? unit;
  final double? target;
  final bool consented;
}

/// Alta o modificación. En el alta exige la casilla de consentimiento.
class _AgreementFormDialog extends StatefulWidget {
  const _AgreementFormDialog({this.existing});

  final SupportAgreement? existing;

  @override
  State<_AgreementFormDialog> createState() => _AgreementFormDialogState();
}

class _AgreementFormDialogState extends State<_AgreementFormDialog> {
  late final objective = TextEditingController(
    text: widget.existing?.objective ?? '',
  );
  late final unit = TextEditingController(text: widget.existing?.unit ?? '');
  late final target = TextEditingController(
    text: widget.existing?.target == null ? '' : _number(widget.existing!.target!),
  );
  bool consent = false;
  String? objectiveError;
  String? targetError;
  String? consentError;

  @override
  void dispose() {
    objective.dispose();
    unit.dispose();
    target.dispose();
    super.dispose();
  }

  void _submit() {
    final text = appText(context);
    final goal = objective.text.trim();
    final rawTarget = target.text.trim();
    final parsed = rawTarget.isEmpty ? null : _parseMeasure(rawTarget);
    final creating = widget.existing == null;
    setState(() {
      objectiveError =
          goal.isEmpty || goal.length > SupportAgreement.maxObjectiveLength
          ? text.agreementErrorObjective
          : null;
      targetError = rawTarget.isNotEmpty && parsed == null
          ? text.agreementErrorMeasure
          : null;
      consentError = creating && !consent ? text.agreementErrorConsent : null;
    });
    if (objectiveError != null || targetError != null || consentError != null) {
      return;
    }
    final u = unit.text.trim();
    Navigator.of(context).pop(
      _AgreementFormResult(
        objective: goal,
        unit: u.isEmpty ? null : u,
        target: parsed,
        consented: consent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = appText(context);
    final creating = widget.existing == null;
    return AlertDialog(
      title: Text(creating ? text.agreementNew : text.agreementModify),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('agreement-objective'),
              controller: objective,
              maxLines: null,
              decoration: InputDecoration(
                labelText: text.agreementObjectiveLabel,
                errorText: objectiveError,
              ),
            ),
            TextField(
              key: const Key('agreement-unit'),
              controller: unit,
              decoration: InputDecoration(labelText: text.agreementUnitLabel),
            ),
            TextField(
              key: const Key('agreement-target'),
              controller: target,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: text.agreementMeasureOptionalLabel,
                errorText: targetError,
              ),
            ),
            if (creating)
              CheckboxListTile(
                key: const Key('agreement-consent'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: consent,
                onChanged: (v) => setState(() => consent = v ?? false),
                title: Text(text.agreementConsent),
                subtitle: consentError == null
                    ? null
                    : Text(
                        consentError!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(text.agreementCancel),
        ),
        FilledButton(
          key: const Key('agreement-form-submit'),
          onPressed: _submit,
          child: Text(creating ? text.agreementCreate : text.agreementSave),
        ),
      ],
    );
  }
}

class _EventDialog extends StatefulWidget {
  const _EventDialog();

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  final amount = TextEditingController();
  final note = TextEditingController();
  String? amountError;

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = amount.text.trim();
    final parsed = raw.isEmpty ? null : _parseMeasure(raw);
    if (raw.isNotEmpty && parsed == null) {
      setState(() => amountError = appText(context).agreementErrorMeasure);
      return;
    }
    final n = note.text.trim();
    Navigator.of(context).pop((amount: parsed, note: n.isEmpty ? null : n));
  }

  @override
  Widget build(BuildContext context) {
    final text = appText(context);
    return AlertDialog(
      title: Text(text.agreementRecordProgress),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('agreement-event-amount'),
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: text.agreementAmountLabel,
              errorText: amountError,
            ),
          ),
          TextField(
            key: const Key('agreement-event-note'),
            controller: note,
            decoration: InputDecoration(labelText: text.agreementNoteLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(text.agreementCancel),
        ),
        FilledButton(
          key: const Key('agreement-event-submit'),
          onPressed: _submit,
          child: Text(text.agreementRecord),
        ),
      ],
    );
  }
}

class _AgreementDetail extends StatefulWidget {
  const _AgreementDetail({
    required this.initial,
    required this.repository,
    required this.service,
    required this.now,
    required this.newId,
  });

  final SupportAgreement initial;
  final SupportAgreementRepository repository;
  final SupportAgreementService service;
  final DateTime Function() now;
  final String Function() newId;

  @override
  State<_AgreementDetail> createState() => _AgreementDetailState();
}

class _AgreementDetailState extends State<_AgreementDetail> {
  late SupportAgreement agreement = widget.initial;

  /// Guarda el resultado de [change]; si algo falla, deja el acuerdo como estaba.
  Future<void> _apply(SupportAgreement Function() change) async {
    try {
      final next = change();
      await widget.repository.save(next);
      if (mounted) setState(() => agreement = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appText(context).agreementSaveError)),
        );
      }
    }
  }

  Future<void> _record() async {
    final result = await showDialog<({double? amount, String? note})>(
      context: context,
      builder: (_) => const _EventDialog(),
    );
    if (result == null) return;
    await _apply(() {
      final event = widget.service.confirmEvent(
        agreement,
        userConfirmed: true,
        eventId: widget.newId(),
        occurredAt: widget.now(),
        amount: result.amount,
        note: result.note,
      );
      return agreement.recordEvent(event!);
    });
  }

  Future<void> _modify() async {
    final form = await showDialog<_AgreementFormResult>(
      context: context,
      builder: (_) => _AgreementFormDialog(existing: agreement),
    );
    if (form == null) return;
    await _apply(
      () => agreement.modify(
        revisionId: widget.newId(),
        changedAt: widget.now(),
        objective: form.objective,
        unit: form.unit,
        target: form.target,
      ),
    );
  }

  Future<void> _complete() async {
    final text = appText(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(text.agreementCompleteTitle),
        content: Text(text.agreementCompleteBody),
        actions: [
          TextButton(
            key: const Key('agreement-complete-cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(text.agreementCancel),
          ),
          FilledButton(
            key: const Key('agreement-complete-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(text.agreementComplete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _apply(
      () => agreement.complete(revisionId: widget.newId(), at: widget.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = appText(context);
    final a = agreement;
    final done = a.status == SupportAgreementStatus.completed;
    final measure = _measure(context, a);
    final events = a.events.reversed.toList();
    final revisions = a.revisions.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: Text(text.agreementTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            a.objective,
            key: const Key('agreement-detail-objective'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _statusLabel(context, a.status),
            key: const Key('agreement-detail-status'),
          ),
          if (measure != null) Text(measure),
          if (a.reminder != null)
            Text('${text.agreementReminderLabel}: ${a.reminder}'),
          const SizedBox(height: 12),
          if (!done)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (a.status == SupportAgreementStatus.active)
                  FilledButton.icon(
                    key: const Key('agreement-record'),
                    onPressed: _record,
                    icon: const Icon(Icons.add_task),
                    label: Text(text.agreementRecordProgress),
                  ),
                if (a.status == SupportAgreementStatus.active)
                  OutlinedButton(
                    key: const Key('agreement-pause'),
                    onPressed: () => _apply(
                      () => a.pause(revisionId: widget.newId(), at: widget.now()),
                    ),
                    child: Text(text.agreementPause),
                  ),
                if (a.status == SupportAgreementStatus.paused)
                  OutlinedButton(
                    key: const Key('agreement-resume'),
                    onPressed: () => _apply(
                      () => a.resume(revisionId: widget.newId(), at: widget.now()),
                    ),
                    child: Text(text.agreementResume),
                  ),
                OutlinedButton(
                  key: const Key('agreement-modify'),
                  onPressed: _modify,
                  child: Text(text.agreementModify),
                ),
                OutlinedButton(
                  key: const Key('agreement-complete'),
                  onPressed: _complete,
                  child: Text(text.agreementComplete),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Text(text.agreementEventsTitle, style: Theme.of(context).textTheme.titleSmall),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(text.agreementNoEvents),
            ),
          for (final e in events)
            ListTile(
              key: Key('agreement-event-${e.id}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                [
                  if (e.amount != null) _number(e.amount!),
                  if (e.note != null) e.note!,
                ].join(' · '),
              ),
              subtitle: Text(_date(context, e.occurredAt)),
            ),
          const SizedBox(height: 16),
          Text(text.agreementChangesTitle, style: Theme.of(context).textTheme.titleSmall),
          if (revisions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(text.agreementNoChanges),
            ),
          for (final r in revisions)
            ListTile(
              key: Key('agreement-revision-${r.revision}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${text.agreementRevisionLabel(r.revision)} · '
                '${_statusLabel(context, r.status)}',
              ),
              subtitle: Text('${r.objective}\n${_date(context, r.createdAt)}'),
              isThreeLine: true,
            ),
        ],
      ),
    );
  }
}
