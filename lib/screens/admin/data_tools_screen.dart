import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/site_controller.dart';
import 'admin_widgets.dart';

class DataToolsScreen extends StatefulWidget {
  const DataToolsScreen({super.key});

  @override
  State<DataToolsScreen> createState() => _DataToolsScreenState();
}

class _DataToolsScreenState extends State<DataToolsScreen> {
  final _import = TextEditingController();

  @override
  void dispose() {
    _import.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final exported = site.exportJson();

    return Scaffold(
      appBar: AppBar(title: const Text('Provisioning & Data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSection(
            title: 'Export configuration',
            description:
                'This JSON is the full, portable definition of the church. '
                'A selling/admin site can generate this to provision a new '
                'customer, and it can be re-imported here at any time.',
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 240),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    exported,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: exported));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Configuration copied to clipboard')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_all),
                label: const Text('Copy JSON'),
              ),
            ],
          ),
          AdminSection(
            title: 'Import configuration',
            description:
                'Paste a full site JSON (or a bare church config) to load it.',
            children: [
              TextField(
                controller: _import,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '{ "config": { … } }',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final error = await site.importJson(_import.text);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Configuration imported'),
                      backgroundColor: error != null
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                  );
                  if (error == null) _import.clear();
                },
                icon: const Icon(Icons.download),
                label: const Text('Import JSON'),
              ),
            ],
          ),
          AdminSection(
            title: 'Danger zone',
            children: [
              OutlinedButton.icon(
                onPressed: () => _confirm(
                  context,
                  title: 'Reset to demo content?',
                  message:
                      'This restores the built-in Circle Church demo data.',
                  onConfirm: site.resetToDefault,
                ),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset to demo content'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => _confirm(
                  context,
                  title: 'Clear everything?',
                  message:
                      'This removes all content and starts from a blank church.',
                  onConfirm: site.clearAll,
                ),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear all content'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (ok == true) await onConfirm();
  }
}
