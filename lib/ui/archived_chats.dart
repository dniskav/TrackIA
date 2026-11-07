import 'package:flutter/material.dart';
import '../application/localization.dart';
import '../data/chat_archive_store.dart';
import '../data/ai_client.dart';
import 'chat_message.dart';

class ArchivedChatsScreen extends StatefulWidget {
  const ArchivedChatsScreen({
    super.key,
    required this.store,
    required this.entries,
  });
  final ChatArchiveStore store;
  final List<Map<String, dynamic>> entries;
  @override
  State<ArchivedChatsScreen> createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends State<ArchivedChatsScreen> {
  String query = '';
  String? error;
  Future<void> open(Map<String, dynamic> entry) async {
    try {
      final document = await widget.store.read(entry['id'] as String);
      if (!mounted) return;
      final selected = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => _ArchiveDetail(document: document)),
      );
      if (selected != null && mounted) Navigator.pop(context, selected);
    } catch (_) {
      if (mounted) {
        setState(() => error = appText(context).archiveRecoverError);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(appText(context).chatArchives)),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              labelText: appText(context).archiveSearchLabel,
            ),
            onChanged: (text) => setState(() => query = text.toLowerCase()),
          ),
        ),
        if (error != null) Text(error!),
        Expanded(
          child: ListView(
            children: [
              if (widget.entries.isEmpty)
                ListTile(title: Text(appText(context).archiveEmpty)),
              for (final entry in widget.entries.reversed)
                if ('${entry['title']} ${entry['summary']}'
                    .toLowerCase()
                    .contains(query))
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(entry['title'] as String),
                    subtitle: Text(
                      '${appText(context).archiveChatSubtitle((entry['createdAt'] as String).substring(0, 10), '${entry['messageCount']}')}${entry['automatic'] == true ? ' · ${appText(context).archiveAutomaticTag}' : ''}',
                    ),
                    onTap: () => open(entry),
                  ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ArchiveDetail extends StatelessWidget {
  const _ArchiveDetail({required this.document});
  final Map<String, dynamic> document;
  @override
  Widget build(BuildContext context) {
    final rows = document['messages'] as List;
    return Scaffold(
      appBar: AppBar(title: Text(document['title'] as String)),
      body: Column(
        children: [
          if ((document['summary'] as String).isNotEmpty)
            ExpansionTile(
              title: Text(appText(context).archiveContinuityTitle),
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .25,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      document['automatic'] == true
                          ? '${document['summary']}\n\n${appText(context).archiveReasonLine('${document['reason']}')}'
                          : '${document['summary']}',
                    ),
                  ),
                ),
              ],
            ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, document['id'] as String),
            icon: const Icon(Icons.chat_outlined),
            label: Text(appText(context).archiveConsultFromChat),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final message = AiMessage.fromStorage(
                  Map<String, dynamic>.from(rows[index] as Map),
                );
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.role == 'user'
                              ? appText(context).archiveYou
                              : appText(context).assistant,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ChatMessageBody(
                          text: message.text,
                          assistant: message.role == 'assistant',
                        ),
                        if (message.attachment != null)
                          Text(
                            appText(
                              context,
                            ).archiveAttachmentKept(message.attachment!.name),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
