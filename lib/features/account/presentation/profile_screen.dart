import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_container.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import 'account_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _household = <_HouseholdRow>[];
  bool _directoryOptIn = false;
  NotificationPreferences _prefs = const NotificationPreferences();
  bool _hydrated = false;
  bool _saving = false;

  /// Populates the form from the loaded profile exactly once, so typing
  /// isn't clobbered by subsequent provider emissions.
  void _hydrate(AppUser user) {
    if (_hydrated) return;
    _hydrated = true;
    _name.text = user.displayName;
    _phone.text = user.phone;
    _directoryOptIn = user.directoryOptIn;
    _prefs = user.notificationPreferences;
    for (final member in user.household) {
      _household.add(_HouseholdRow.from(member));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    for (final row in _household) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _save(AppUser user) async {
    setState(() => _saving = true);
    final household = [
      for (final row in _household)
        if (row.name.text.trim().isNotEmpty)
          HouseholdMember(
            name: row.name.text.trim(),
            relationship: row.relationship.text.trim(),
            birthDate: row.birthDate,
          ),
    ];

    await ref.read(profileControllerProvider).save(
          user.copyWith(
            displayName: _name.text.trim(),
            phone: _phone.text.trim(),
            household: household,
            directoryOptIn: _directoryOptIn,
            notificationPreferences: _prefs,
          ),
        );

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return PageBody(
      children: [
        const AccountHeader(title: 'Profile', subtitle: 'Your details, household, and preferences.'),
        SectionContainer(
          maxWidth: 720,
          child: user == null
              ? const Center(child: CircularProgressIndicator())
              : Builder(
                  builder: (context) {
                    _hydrate(user);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Full name'),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phone,
                          decoration: const InputDecoration(labelText: 'Phone'),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        InputDecorator(
                          decoration: const InputDecoration(labelText: 'Email'),
                          child: Text(user.email),
                        ),
                        const SizedBox(height: 32),
                        _Household(
                          rows: _household,
                          onAdd: () => setState(() => _household.add(_HouseholdRow.empty())),
                          onRemove: (i) => setState(() => _household.removeAt(i).dispose()),
                          onBirthDate: (i, date) => setState(() => _household[i].birthDate = date),
                        ),
                        const SizedBox(height: 32),
                        Text('Privacy', style: Theme.of(context).textTheme.titleLarge),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('List me in the member directory'),
                          subtitle: const Text(
                            'Other signed-in members will be able to see your name and email. Off by default.',
                          ),
                          value: _directoryOptIn,
                          onChanged: (v) => setState(() => _directoryOptIn = v),
                        ),
                        const SizedBox(height: 24),
                        Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        const Text(
                          'Choose what shows up in your notification inbox.',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        for (final entry in const [
                          ('volunteering', 'Volunteering', 'Serving assignments and approvals'),
                          ('announcements', 'Announcements', 'Church-wide news'),
                          ('groups', 'Groups', 'Group requests and updates'),
                          ('events', 'Events', 'Event reminders and changes'),
                        ])
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(entry.$2),
                            subtitle: Text(entry.$3),
                            value: _prefs.allows(entry.$1),
                            onChanged: (v) => setState(() => _prefs = _prefs.copyWithEntry(entry.$1, v)),
                          ),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: _saving ? null : () => _save(user),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Save Changes'),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Household extends StatelessWidget {
  final List<_HouseholdRow> rows;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final void Function(int index, DateTime? birthDate) onBirthDate;

  const _Household({
    required this.rows,
    required this.onAdd,
    required this.onRemove,
    required this.onBirthDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Household', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'Add family members so staff know who belongs together - and so kids '
          'can be checked in under your name.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            // Name, relationship and date of birth are three fields, not
            // a table: on a phone they stack, with the remove button
            // staying beside the date it belongs to.
            child: ResponsiveRow(
              spacing: 12,
              flex: const [2, 1, 1],
              children: [
                TextField(
                  controller: rows[i].name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: rows[i].relationship,
                  decoration: const InputDecoration(labelText: 'Relationship'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                    onTap: () async {
                      final existing = rows[i].birthDate;
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: existing ?? DateTime(DateTime.now().year - 6),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        helpText: 'Date of birth',
                      );
                      if (picked != null) onBirthDate(i, picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of birth',
                        // Only children need one, and saying so keeps
                        // adults from wondering whether it is required.
                        helperText: 'For kids check-in',
                        suffixIcon: rows[i].birthDate == null
                            ? const Icon(Icons.calendar_today_outlined, size: 18)
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                tooltip: 'Clear',
                                onPressed: () => onBirthDate(i, null),
                              ),
                      ),
                      child: Text(
                        rows[i].birthDate == null
                            ? 'Optional'
                            : DateFormat.yMMMd().format(rows[i].birthDate!),
                        style: TextStyle(
                          color: rows[i].birthDate == null ? Colors.black45 : Colors.black87,
                        ),
                      ),
                    ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemove(i),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add household member'),
        ),
      ],
    );
  }
}

class _HouseholdRow {
  final TextEditingController name;
  final TextEditingController relationship;

  /// Mutable: the field existed from the start but nothing could set it,
  /// so no parent could record a child's age and kids check-in had
  /// nothing to show a volunteer.
  DateTime? birthDate;

  _HouseholdRow({required this.name, required this.relationship, this.birthDate});

  factory _HouseholdRow.empty() =>
      _HouseholdRow(name: TextEditingController(), relationship: TextEditingController());

  factory _HouseholdRow.from(HouseholdMember member) => _HouseholdRow(
        name: TextEditingController(text: member.name),
        relationship: TextEditingController(text: member.relationship),
        birthDate: member.birthDate,
      );

  void dispose() {
    name.dispose();
    relationship.dispose();
  }
}
