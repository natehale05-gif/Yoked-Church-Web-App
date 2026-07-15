import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/app_icons.dart';
import '../../models/site_content.dart';
import '../../state/site_content_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/buttons.dart';
import 'admin_serving_page.dart' show IconPicker;

const _accentSwatches = [
  0xFFC6A15B, // gold
  0xFF2F6DB0, // blue
  0xFF3E7C5A, // green
  0xFFB5544E, // terracotta
  0xFF6C5CE7, // violet
  0xFFCD7F32, // bronze
  0xFF14807A, // teal
  0xFFB3438F, // magenta
];

class AdminEditorPage extends StatefulWidget {
  const AdminEditorPage({super.key});

  @override
  State<AdminEditorPage> createState() => _AdminEditorPageState();
}

enum _Section { brand, home, contact, events, ministries, team, sermons }

class _AdminEditorPageState extends State<AdminEditorPage> {
  _Section _section = _Section.brand;
  late SiteContent _draft;
  bool _dirty = false;

  // Text controllers for scalar fields.
  final _c = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _draft = context.read<SiteContentController>().content;
    _bindControllers();
  }

  void _bindControllers() {
    void bind(String k, String v) {
      _c[k] = TextEditingController(text: v)
        ..addListener(() => _markDirty());
    }

    bind('churchName', _draft.churchName);
    bind('shortName', _draft.shortName);
    bind('tagline', _draft.tagline);
    bind('heroHeadline', _draft.heroHeadline);
    bind('heroSubhead', _draft.heroSubhead);
    bind('addressLine1', _draft.addressLine1);
    bind('addressLine2', _draft.addressLine2);
    bind('phone', _draft.phone);
    bind('email', _draft.email);
    bind('mapUrl', _draft.mapUrl);
    bind('giveUrl', _draft.giveUrl);
    bind('instagramUrl', _draft.instagramUrl);
    bind('facebookUrl', _draft.facebookUrl);
    bind('youtubeUrl', _draft.youtubeUrl);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  SiteContent _collect() => _draft.copyWith(
        churchName: _c['churchName']!.text,
        shortName: _c['shortName']!.text,
        tagline: _c['tagline']!.text,
        heroHeadline: _c['heroHeadline']!.text,
        heroSubhead: _c['heroSubhead']!.text,
        addressLine1: _c['addressLine1']!.text,
        addressLine2: _c['addressLine2']!.text,
        phone: _c['phone']!.text,
        email: _c['email']!.text,
        mapUrl: _c['mapUrl']!.text,
        giveUrl: _c['giveUrl']!.text,
        instagramUrl: _c['instagramUrl']!.text,
        facebookUrl: _c['facebookUrl']!.text,
        youtubeUrl: _c['youtubeUrl']!.text,
      );

  Future<void> _save() async {
    final content = _collect();
    await context.read<SiteContentController>().update(content);
    setState(() {
      _draft = content;
      _dirty = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your website has been updated.')),
      );
    }
  }

  /// Update collections in the draft and mark dirty.
  void _updateDraft(SiteContent Function(SiteContent) fn) {
    setState(() {
      _draft = fn(_draft);
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminHeader(
          title: 'Site Editor',
          subtitle: 'Change your public website — no code required.',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Preview'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.line),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
              ),
              const SizedBox(width: 12),
              PrimaryButton(
                label: _dirty ? 'Save changes' : 'Saved',
                icon: _dirty ? Icons.save_outlined : Icons.check,
                onPressed: _dirty ? _save : () {},
              ),
            ],
          ),
        ),
        _sectionTabs(),
        const SizedBox(height: 20),
        Panel(
          padding: const EdgeInsets.all(24),
          child: _body(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _sectionTabs() {
    const labels = {
      _Section.brand: 'Brand',
      _Section.home: 'Home page',
      _Section.contact: 'Contact & times',
      _Section.events: 'Events',
      _Section.ministries: 'Ministries',
      _Section.team: 'Team',
      _Section.sermons: 'Messages',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in _Section.values)
          ChoiceChip(
            label: Text(labels[s]!),
            selected: _section == s,
            onSelected: (_) => setState(() => _section = s),
            showCheckmark: false,
            selectedColor: AppColors.navy,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              color: _section == s ? AppColors.onDark : AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
            side: const BorderSide(color: AppColors.line),
          ),
      ],
    );
  }

  Widget _body() {
    switch (_section) {
      case _Section.brand:
        return _brand();
      case _Section.home:
        return _home();
      case _Section.contact:
        return _contact();
      case _Section.events:
        return _events();
      case _Section.ministries:
        return _ministries();
      case _Section.team:
        return _team();
      case _Section.sermons:
        return _sermons();
    }
  }

  Widget _field(String key, String label, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        AdminField(controller: _c[key]!, maxLines: maxLines),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- Brand ---
  Widget _brand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('churchName', 'Church name'),
        _field('shortName', 'Short name (used for the logo mark)'),
        _field('tagline', 'Tagline', maxLines: 2),
        const FieldLabel('Brand accent color'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final swatch in _accentSwatches)
              GestureDetector(
                onTap: () => _updateDraft((d) => d.copyWith(accentColor: swatch)),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Color(swatch),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _draft.accentColor == swatch
                          ? AppColors.navy
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: _draft.accentColor == swatch
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // --- Home ---
  Widget _home() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('heroHeadline', 'Hero headline'),
        _field('heroSubhead', 'Hero subheading', maxLines: 3),
        const Divider(height: 32),
        _ListSection<ValuePoint>(
          title: 'What to expect',
          items: _draft.whatToExpect,
          itemTitle: (v) => v.title,
          itemSubtitle: (v) => v.body,
          leadingIcon: (v) => iconForKey(v.iconKey),
          onAdd: () => _editValuePoint(),
          onEdit: (v) => _editValuePoint(existing: v),
          onDelete: (v) => _updateDraft((d) => d.copyWith(
              whatToExpect:
                  d.whatToExpect.where((e) => e != v).toList())),
        ),
        const Divider(height: 32),
        _ListSection<ValuePoint>(
          title: 'Core values',
          items: _draft.values,
          itemTitle: (v) => v.title,
          itemSubtitle: (v) => v.body,
          leadingIcon: (v) => iconForKey(v.iconKey),
          onAdd: () => _editValuePoint(isValue: true),
          onEdit: (v) => _editValuePoint(existing: v, isValue: true),
          onDelete: (v) => _updateDraft((d) =>
              d.copyWith(values: d.values.where((e) => e != v).toList())),
        ),
      ],
    );
  }

  Future<void> _editValuePoint(
      {ValuePoint? existing, bool isValue = false}) async {
    final result = await showDialog<ValuePoint>(
      context: context,
      builder: (_) => _ValuePointDialog(existing: existing),
    );
    if (result == null) return;
    _updateDraft((d) {
      final list = [...(isValue ? d.values : d.whatToExpect)];
      final i = existing == null ? -1 : list.indexOf(existing);
      if (i >= 0) {
        list[i] = result;
      } else {
        list.add(result);
      }
      return isValue ? d.copyWith(values: list) : d.copyWith(whatToExpect: list);
    });
  }

  // --- Contact ---
  Widget _contact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('addressLine1', 'Address line 1'),
        _field('addressLine2', 'Address line 2'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _field('phone', 'Phone')),
            const SizedBox(width: 16),
            Expanded(child: _field('email', 'Email')),
          ],
        ),
        _field('mapUrl', 'Map link'),
        _field('giveUrl', 'Giving link'),
        const Divider(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _field('instagramUrl', 'Instagram URL')),
            const SizedBox(width: 16),
            Expanded(child: _field('facebookUrl', 'Facebook URL')),
          ],
        ),
        _field('youtubeUrl', 'YouTube URL'),
        const Divider(height: 32),
        _ListSection<ServiceTime>(
          title: 'Service times',
          items: _draft.serviceTimes,
          itemTitle: (s) => '${s.day} · ${s.time}',
          itemSubtitle: (s) => s.label,
          leadingIcon: (_) => Icons.schedule,
          onAdd: () => _editServiceTime(),
          onEdit: (s) => _editServiceTime(existing: s),
          onDelete: (s) => _updateDraft((d) => d.copyWith(
              serviceTimes:
                  d.serviceTimes.where((e) => e != s).toList())),
        ),
      ],
    );
  }

  Future<void> _editServiceTime({ServiceTime? existing}) async {
    final result = await showDialog<ServiceTime>(
      context: context,
      builder: (_) => _ServiceTimeDialog(existing: existing),
    );
    if (result == null) return;
    _updateDraft((d) {
      final list = [...d.serviceTimes];
      final i = existing == null ? -1 : list.indexOf(existing);
      if (i >= 0) {
        list[i] = result;
      } else {
        list.add(result);
      }
      return d.copyWith(serviceTimes: list);
    });
  }

  // --- Events ---
  Widget _events() {
    return _ListSection<ChurchEvent>(
      title: 'Events',
      items: _draft.events,
      itemTitle: (e) => e.title,
      itemSubtitle: (e) => '${e.date} · ${e.time} · ${e.location}',
      leadingIcon: (_) => Icons.event_outlined,
      onAdd: () => _editEvent(),
      onEdit: (e) => _editEvent(existing: e),
      onDelete: (e) => _updateDraft(
          (d) => d.copyWith(events: d.events.where((x) => x.id != e.id).toList())),
    );
  }

  Future<void> _editEvent({ChurchEvent? existing}) async {
    final result = await showDialog<ChurchEvent>(
      context: context,
      builder: (_) => _EventDialog(existing: existing),
    );
    if (result == null) return;
    _updateDraft((d) {
      final list = [...d.events];
      final i = list.indexWhere((x) => x.id == result.id);
      if (i >= 0) {
        list[i] = result;
      } else {
        list.add(result);
      }
      return d.copyWith(events: list);
    });
  }

  // --- Ministries ---
  Widget _ministries() {
    return _ListSection<Ministry>(
      title: 'Ministries',
      items: _draft.ministries,
      itemTitle: (m) => m.name,
      itemSubtitle: (m) => '${m.forWho} — ${m.description}',
      leadingIcon: (m) => iconForKey(m.iconKey),
      onAdd: () => _editMinistry(),
      onEdit: (m) => _editMinistry(existing: m),
      onDelete: (m) => _updateDraft((d) => d.copyWith(
          ministries: d.ministries.where((x) => x.id != m.id).toList())),
    );
  }

  Future<void> _editMinistry({Ministry? existing}) async {
    final result = await showDialog<Ministry>(
      context: context,
      builder: (_) => _MinistryDialog(existing: existing),
    );
    if (result == null) return;
    _updateDraft((d) {
      final list = [...d.ministries];
      final i = list.indexWhere((x) => x.id == result.id);
      if (i >= 0) {
        list[i] = result;
      } else {
        list.add(result);
      }
      return d.copyWith(ministries: list);
    });
  }

  // --- Team ---
  Widget _team() {
    return _ListSection<Person>(
      title: 'Team members',
      items: _draft.leaders,
      itemTitle: (p) => p.name,
      itemSubtitle: (p) => p.role,
      leadingIcon: (_) => Icons.person_outline,
      onAdd: () => _editPerson(),
      onEdit: (p) => _editPerson(existing: p),
      onDelete: (p) => _updateDraft((d) =>
          d.copyWith(leaders: d.leaders.where((x) => x.id != p.id).toList())),
    );
  }

  Future<void> _editPerson({Person? existing}) async {
    final result = await showDialog<Person>(
      context: context,
      builder: (_) => _PersonDialog(existing: existing),
    );
    if (result == null) return;
    _updateDraft((d) {
      final list = [...d.leaders];
      final i = list.indexWhere((x) => x.id == result.id);
      if (i >= 0) {
        list[i] = result;
      } else {
        list.add(result);
      }
      return d.copyWith(leaders: list);
    });
  }

  // --- Sermons ---
  Widget _sermons() {
    return _ListSection<Sermon>(
      title: 'Messages',
      items: _draft.sermons,
      itemTitle: (s) => s.title,
      itemSubtitle: (s) => '${s.series} · ${s.speaker} · ${s.date}',
      leadingIcon: (_) => Icons.play_circle_outline,
      onAdd: () => _editSermon(),
      onEdit: (s) => _editSermon(existing: s),
      onDelete: (s) => _updateDraft((d) =>
          d.copyWith(sermons: d.sermons.where((x) => x.id != s.id).toList())),
    );
  }

  Future<void> _editSermon({Sermon? existing}) async {
    final result = await showDialog<Sermon>(
      context: context,
      builder: (_) => _SermonDialog(existing: existing),
    );
    if (result == null) return;
    _updateDraft((d) {
      final list = [...d.sermons];
      final i = list.indexWhere((x) => x.id == result.id);
      if (i >= 0) {
        list[i] = result;
      } else {
        list.add(result);
      }
      return d.copyWith(sermons: list);
    });
  }
}

/// A reusable editable list with add / edit / delete controls.
class _ListSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemTitle;
  final String Function(T) itemSubtitle;
  final IconData Function(T) leadingIcon;
  final VoidCallback onAdd;
  final void Function(T) onEdit;
  final void Function(T) onDelete;

  const _ListSection({
    required this.title,
    required this.items,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.leadingIcon,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nothing here yet.',
                style: TextStyle(color: AppColors.inkSoft)),
          )
        else
          for (final item in items)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Icon(leadingIcon(item), size: 20, color: AppColors.navy),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(itemTitle(item),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                        Text(itemSubtitle(item),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    color: AppColors.inkSoft,
                    onPressed: () => onEdit(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 19),
                    color: AppColors.inkSoft,
                    onPressed: () => onDelete(item),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Item editor dialogs
// ---------------------------------------------------------------------------

class _DialogShell extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  const _DialogShell({
    required this.title,
    required this.children,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.onDark),
          onPressed: onSave,
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _ValuePointDialog extends StatefulWidget {
  final ValuePoint? existing;
  const _ValuePointDialog({this.existing});
  @override
  State<_ValuePointDialog> createState() => _ValuePointDialogState();
}

class _ValuePointDialogState extends State<_ValuePointDialog> {
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _body = TextEditingController(text: widget.existing?.body);
  late String _icon = widget.existing?.iconKey ?? 'star';

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.existing == null ? 'Add item' : 'Edit item',
      onSave: () {
        if (_title.text.trim().isEmpty) return;
        Navigator.pop(
          context,
          ValuePoint(
              iconKey: _icon,
              title: _title.text.trim(),
              body: _body.text.trim()),
        );
      },
      children: [
        const FieldLabel('Title'),
        AdminField(controller: _title),
        const SizedBox(height: 12),
        const FieldLabel('Description'),
        AdminField(controller: _body, maxLines: 3),
        const SizedBox(height: 12),
        const FieldLabel('Icon'),
        IconPicker(selected: _icon, onSelected: (k) => setState(() => _icon = k)),
      ],
    );
  }
}

class _ServiceTimeDialog extends StatefulWidget {
  final ServiceTime? existing;
  const _ServiceTimeDialog({this.existing});
  @override
  State<_ServiceTimeDialog> createState() => _ServiceTimeDialogState();
}

class _ServiceTimeDialogState extends State<_ServiceTimeDialog> {
  late final _day = TextEditingController(text: widget.existing?.day);
  late final _time = TextEditingController(text: widget.existing?.time);
  late final _label = TextEditingController(text: widget.existing?.label);

  @override
  void dispose() {
    _day.dispose();
    _time.dispose();
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.existing == null ? 'Add service time' : 'Edit service time',
      onSave: () {
        Navigator.pop(
          context,
          ServiceTime(
              day: _day.text.trim(),
              time: _time.text.trim(),
              label: _label.text.trim()),
        );
      },
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('Day'),
                  AdminField(controller: _day, hint: 'Sunday'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('Time'),
                  AdminField(controller: _time, hint: '9:00 AM'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const FieldLabel('Label'),
        AdminField(controller: _label, hint: 'Morning Gathering'),
      ],
    );
  }
}

class _EventDialog extends StatefulWidget {
  final ChurchEvent? existing;
  const _EventDialog({this.existing});
  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _date = TextEditingController(text: widget.existing?.date);
  late final _time = TextEditingController(text: widget.existing?.time);
  late final _location = TextEditingController(text: widget.existing?.location);
  late final _desc = TextEditingController(text: widget.existing?.description);

  @override
  void dispose() {
    _title.dispose();
    _date.dispose();
    _time.dispose();
    _location.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.existing == null ? 'Add event' : 'Edit event',
      onSave: () {
        if (_title.text.trim().isEmpty) return;
        final base = widget.existing ??
            ChurchEvent(
                title: '', date: '', time: '', location: '', description: '');
        Navigator.pop(
          context,
          base.copyWith(
            title: _title.text.trim(),
            date: _date.text.trim(),
            time: _time.text.trim(),
            location: _location.text.trim(),
            description: _desc.text.trim(),
          ),
        );
      },
      children: [
        const FieldLabel('Title'),
        AdminField(controller: _title),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('Date'),
                  AdminField(controller: _date, hint: 'August 15, 2026'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('Time'),
                  AdminField(controller: _time, hint: '9:00 AM'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const FieldLabel('Location'),
        AdminField(controller: _location),
        const SizedBox(height: 12),
        const FieldLabel('Description'),
        AdminField(controller: _desc, maxLines: 3),
      ],
    );
  }
}

class _MinistryDialog extends StatefulWidget {
  final Ministry? existing;
  const _MinistryDialog({this.existing});
  @override
  State<_MinistryDialog> createState() => _MinistryDialogState();
}

class _MinistryDialogState extends State<_MinistryDialog> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _forWho = TextEditingController(text: widget.existing?.forWho);
  late final _desc = TextEditingController(text: widget.existing?.description);
  late String _icon = widget.existing?.iconKey ?? 'groups';

  @override
  void dispose() {
    _name.dispose();
    _forWho.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.existing == null ? 'Add ministry' : 'Edit ministry',
      onSave: () {
        if (_name.text.trim().isEmpty) return;
        final base = widget.existing ??
            Ministry(name: '', forWho: '', description: '', iconKey: _icon);
        Navigator.pop(
          context,
          base.copyWith(
            name: _name.text.trim(),
            forWho: _forWho.text.trim(),
            description: _desc.text.trim(),
            iconKey: _icon,
          ),
        );
      },
      children: [
        const FieldLabel('Name'),
        AdminField(controller: _name),
        const SizedBox(height: 12),
        const FieldLabel('For who'),
        AdminField(controller: _forWho, hint: 'Birth – 5th Grade'),
        const SizedBox(height: 12),
        const FieldLabel('Description'),
        AdminField(controller: _desc, maxLines: 3),
        const SizedBox(height: 12),
        const FieldLabel('Icon'),
        IconPicker(selected: _icon, onSelected: (k) => setState(() => _icon = k)),
      ],
    );
  }
}

class _PersonDialog extends StatefulWidget {
  final Person? existing;
  const _PersonDialog({this.existing});
  @override
  State<_PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends State<_PersonDialog> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _role = TextEditingController(text: widget.existing?.role);
  late final _bio = TextEditingController(text: widget.existing?.bio);
  late final _image = TextEditingController(text: widget.existing?.imageUrl);

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _bio.dispose();
    _image.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.existing == null ? 'Add team member' : 'Edit team member',
      onSave: () {
        if (_name.text.trim().isEmpty) return;
        final base = widget.existing ?? Person(name: '', role: '', bio: '');
        Navigator.pop(
          context,
          base.copyWith(
            name: _name.text.trim(),
            role: _role.text.trim(),
            bio: _bio.text.trim(),
            imageUrl: _image.text.trim().isEmpty ? null : _image.text.trim(),
          ),
        );
      },
      children: [
        const FieldLabel('Name'),
        AdminField(controller: _name),
        const SizedBox(height: 12),
        const FieldLabel('Role'),
        AdminField(controller: _role, hint: 'Lead Pastor'),
        const SizedBox(height: 12),
        const FieldLabel('Bio'),
        AdminField(controller: _bio, maxLines: 3),
        const SizedBox(height: 12),
        const FieldLabel('Photo URL (optional)'),
        AdminField(controller: _image, hint: 'https://…'),
      ],
    );
  }
}

class _SermonDialog extends StatefulWidget {
  final Sermon? existing;
  const _SermonDialog({this.existing});
  @override
  State<_SermonDialog> createState() => _SermonDialogState();
}

class _SermonDialogState extends State<_SermonDialog> {
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _series = TextEditingController(text: widget.existing?.series);
  late final _speaker = TextEditingController(text: widget.existing?.speaker);
  late final _date = TextEditingController(text: widget.existing?.date);
  late final _desc = TextEditingController(text: widget.existing?.description);

  @override
  void dispose() {
    _title.dispose();
    _series.dispose();
    _speaker.dispose();
    _date.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.existing == null ? 'Add message' : 'Edit message',
      onSave: () {
        if (_title.text.trim().isEmpty) return;
        final base = widget.existing ??
            Sermon(
                title: '',
                series: '',
                speaker: '',
                date: '',
                description: '');
        Navigator.pop(
          context,
          base.copyWith(
            title: _title.text.trim(),
            series: _series.text.trim(),
            speaker: _speaker.text.trim(),
            date: _date.text.trim(),
            description: _desc.text.trim(),
          ),
        );
      },
      children: [
        const FieldLabel('Title'),
        AdminField(controller: _title),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('Series'),
                  AdminField(controller: _series),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('Date'),
                  AdminField(controller: _date, hint: 'July 6, 2026'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const FieldLabel('Speaker'),
        AdminField(controller: _speaker),
        const SizedBox(height: 12),
        const FieldLabel('Description'),
        AdminField(controller: _desc, maxLines: 3),
      ],
    );
  }
}
