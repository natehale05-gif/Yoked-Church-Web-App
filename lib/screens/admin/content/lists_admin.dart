import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/giving_fund.dart';
import '../../../models/service_time.dart';
import '../../../models/social_link.dart';
import '../../../state/site_controller.dart';
import '../../../utils/icon_utils.dart';

class ServiceTimesAdminScreen extends StatelessWidget {
  const ServiceTimesAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final items = site.config.serviceTimes;

    return Scaffold(
      appBar: AppBar(title: const Text('Service Times')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add time'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final s in items)
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(s.name),
                subtitle: Text('${s.day} · ${s.time}'
                    '${s.location.isNotEmpty ? ' · ${s.location}' : ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _edit(context, s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => site.setServiceTimes(
                          items.where((e) => e.id != s.id).toList()),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, ServiceTime? existing) async {
    final site = context.read<SiteController>();
    final name = TextEditingController(text: existing?.name ?? '');
    final day = TextEditingController(text: existing?.day ?? '');
    final time = TextEditingController(text: existing?.time ?? '');
    final loc = TextEditingController(text: existing?.location ?? '');

    final ok = await _showFormDialog(
      context,
      title: existing == null ? 'Add service time' : 'Edit service time',
      fields: [
        _field(name, 'Name (e.g. Sunday Gathering)'),
        _field(day, 'Day (e.g. Sunday)'),
        _field(time, 'Time (e.g. 9:00 AM)'),
        _field(loc, 'Location (optional)'),
      ],
    );
    if (ok != true) return;

    final updated = (existing ??
            ServiceTime(
                id: 'svc-${DateTime.now().microsecondsSinceEpoch}',
                name: '',
                day: '',
                time: ''))
        .copyWith(
      name: name.text,
      day: day.text,
      time: time.text,
      location: loc.text,
    );
    final list = List<ServiceTime>.from(site.config.serviceTimes);
    final i = list.indexWhere((e) => e.id == updated.id);
    if (i >= 0) {
      list[i] = updated;
    } else {
      list.add(updated);
    }
    await site.setServiceTimes(list);
  }
}

class SocialLinksAdminScreen extends StatelessWidget {
  const SocialLinksAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final items = site.config.socialLinks;

    return Scaffold(
      appBar: AppBar(title: const Text('Social Links')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add link'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final s in items)
            Card(
              child: ListTile(
                leading: Icon(socialIcon(s.platform)),
                title: Text(s.platform),
                subtitle: Text(s.url, maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _edit(context, s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => site.setSocialLinks(
                          items.where((e) => e.id != s.id).toList()),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, SocialLink? existing) async {
    final site = context.read<SiteController>();
    var platform = existing?.platform ?? socialPlatforms.first;
    final url = TextEditingController(text: existing?.url ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Add social link' : 'Edit link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: platform,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Platform'),
                items: [
                  for (final p in socialPlatforms)
                    DropdownMenuItem(value: p, child: Text(p)),
                ],
                onChanged: (v) => setState(() => platform = v ?? platform),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: url,
                decoration: const InputDecoration(
                    labelText: 'URL', hintText: 'https://…'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final updated = (existing ??
            SocialLink(
                id: 's-${DateTime.now().microsecondsSinceEpoch}',
                platform: platform,
                url: ''))
        .copyWith(platform: platform, url: url.text);
    final list = List<SocialLink>.from(site.config.socialLinks);
    final i = list.indexWhere((e) => e.id == updated.id);
    if (i >= 0) {
      list[i] = updated;
    } else {
      list.add(updated);
    }
    await site.setSocialLinks(list);
  }
}

class GivingFundsAdminScreen extends StatelessWidget {
  const GivingFundsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final site = context.watch<SiteController>();
    final items = site.config.givingFunds;

    return Scaffold(
      appBar: AppBar(title: const Text('Giving Funds')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Add fund'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final f in items)
            Card(
              child: ListTile(
                leading: const Icon(Icons.savings_outlined),
                title: Text(f.name),
                subtitle: f.description.isNotEmpty
                    ? Text(f.description,
                        maxLines: 2, overflow: TextOverflow.ellipsis)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _edit(context, f),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => site.setGivingFunds(
                          items.where((e) => e.id != f.id).toList()),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, GivingFund? existing) async {
    final site = context.read<SiteController>();
    final name = TextEditingController(text: existing?.name ?? '');
    final desc = TextEditingController(text: existing?.description ?? '');
    final url = TextEditingController(text: existing?.url ?? '');

    final ok = await _showFormDialog(
      context,
      title: existing == null ? 'Add fund' : 'Edit fund',
      fields: [
        _field(name, 'Fund name'),
        _field(desc, 'Description', maxLines: 3),
        _field(url, 'Giving URL', hint: 'https://…'),
      ],
    );
    if (ok != true) return;

    final updated = (existing ??
            GivingFund(
                id: 'fund-${DateTime.now().microsecondsSinceEpoch}', name: ''))
        .copyWith(name: name.text, description: desc.text, url: url.text);
    final list = List<GivingFund>.from(site.config.givingFunds);
    final i = list.indexWhere((e) => e.id == updated.id);
    if (i >= 0) {
      list[i] = updated;
    } else {
      list.add(updated);
    }
    await site.setGivingFunds(list);
  }
}

// --- Shared dialog helpers ---------------------------------------------------

Widget _field(TextEditingController c, String label,
    {String? hint, int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );
}

Future<bool?> _showFormDialog(
  BuildContext context, {
  required String title,
  required List<Widget> fields,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: fields),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save')),
      ],
    ),
  );
}
