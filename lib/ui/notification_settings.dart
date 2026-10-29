import 'package:flutter/material.dart';
import '../application/rest_notifications.dart';

/// Android's interruption filter that blocks everything, alarms included.
const _totalSilence = 3;

/// Global notice settings: what is announced, whether it sounds like an alarm
/// and how it behaves under Do Not Disturb.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, required this.notifications});
  final RestNotificationController notifications;
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  RestNotificationController get n => widget.notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    n.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may come back from the system's Do Not Disturb settings.
    if (state == AppLifecycleState.resumed) n.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Avisos')),
    body: ListenableBuilder(
      listenable: n,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        if (!n.supported) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Los avisos de descanso solo están disponibles en Android.',
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (n.dnd)
              Container(
                key: const Key('notify-dnd-banner'),
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.secondary),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.dark_mode_outlined, color: scheme.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No molestar está activo',
                            style: textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.dndFilter == _totalSilence
                                ? 'Estás en «Silencio total»: Android bloquea los avisos, incluso como alarma.'
                                : n.alarmStyle
                                ? 'Los avisos de descanso suenan como alarma. Los demás avisos no sonarían ni vibrarían.'
                                : 'Ahora mismo los avisos de descanso no sonarían ni vibrarían.',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            SwitchListTile(
              key: const Key('notify-enabled'),
              title: const Text('Avisos de actividad y descanso'),
              subtitle: const Text(
                'Actividad lista, tramo en marcha, fin de tramo y fin de descanso.',
              ),
              value: n.enabled,
              onChanged: n.busy ? null : n.toggle,
            ),
            SwitchListTile(
              key: const Key('notify-alarm-style'),
              title: const Text('Tratar como alarma'),
              subtitle: const Text(
                'El fin de descanso y de tramo suenan y vibran aunque No molestar esté en modo Prioridad.',
              ),
              value: n.alarmStyle,
              onChanged: n.busy ? null : n.setAlarmStyle,
            ),
            if (n.alarmChannelBlocked)
              ListTile(
                key: const Key('notify-channel-blocked'),
                leading: Icon(Icons.block, color: scheme.error),
                title: const Text('Android bloquea el canal de alarma'),
                subtitle: const Text('Actívalo en los ajustes del canal.'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => n.openChannelSettings('alarm'),
              ),
            if (n.enabled && !n.exact)
              ListTile(
                title: const Text('Permitir avisos puntuales'),
                subtitle: const Text(
                  'Sin este permiso Android puede retrasar el aviso.',
                ),
                onTap: n.allowExact,
              ),
            if (n.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(n.error!, style: TextStyle(color: scheme.error)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Comprobar',
                style: textTheme.labelLarge?.copyWith(color: scheme.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: OutlinedButton.icon(
                key: const Key('notify-test'),
                onPressed: n.busy ? null : n.testNotification,
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Probar aviso'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: OutlinedButton.icon(
                key: const Key('notify-test-alarm'),
                onPressed: n.busy ? null : () => n.testAlarm(),
                icon: const Icon(Icons.timer_outlined),
                label: const Text('Probar con No molestar activo'),
              ),
            ),
            if (n.testStatus != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(n.testStatus!),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: OutlinedButton.icon(
                key: const Key('notify-open-dnd'),
                onPressed: n.openDndSettings,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir ajustes de No molestar'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                'En «Silencio total» Android bloquea todo, incluidas las alarmas. Ahí solo ayuda permitirlas en los ajustes de tu móvil.',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
