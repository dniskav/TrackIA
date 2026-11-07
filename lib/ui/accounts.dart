import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../application/localization.dart';
import '../data/profile_store.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});
  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  bool busy = false;
  String? error;
  final profiles = ProfileStore.instance;

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(
          () => error = switch (e) {
            PlatformException p =>
              p.message ?? appText(context).accountsConnectError,
            FormatException f => f.message,
            _ => appText(context).accountsSwitchError,
          },
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(appText(context).accountAndData)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          profiles.active?.email ?? appText(context).localProfile,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(appText(context).accountsDescription),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: busy ? null : () => run(() => profiles.connect()),
          icon: const Icon(Icons.account_circle_outlined),
          label: Text(appText(context).accountsConnectAnother),
        ),
        for (final profile in profiles.profiles)
          ListTile(
            title: Text(profile.email),
            subtitle: Text(
              profile.id == profiles.activeId
                  ? appText(context).accountsActiveProfile
                  : appText(context).accountsReconnectProfile,
            ),
            trailing: profile.id == profiles.activeId
                ? const Icon(Icons.check)
                : null,
            enabled: !busy && profile.id != profiles.activeId,
            onTap: () =>
                run(() => profiles.connect(expectedSubject: profile.subject)),
          ),
        if (profiles.activeId != 'local') ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: busy ? null : () => run(profiles.useLocal),
            child: Text(appText(context).accountsDisconnect),
          ),
          Text(appText(context).accountsDisconnectNotice),
        ],
        if (busy)
          const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    ),
  );
}
