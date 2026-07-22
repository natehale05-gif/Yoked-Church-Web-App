import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/account_header.dart';
import '../../widgets/section_container.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final _nameController = TextEditingController();
  final List<TextEditingController> _memberNameControllers = [];
  final List<TextEditingController> _memberRelationControllers = [];
  bool _directoryOptIn = false;
  bool _initialized = false;
  bool _saving = false;

  void _initFromUser(AppUser user) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = user.displayName;
    _directoryOptIn = user.directoryOptIn;
    for (final member in user.household) {
      _memberNameControllers.add(TextEditingController(text: member.name));
      _memberRelationControllers.add(TextEditingController(text: member.relationship));
    }
  }

  void _addHouseholdMember() {
    setState(() {
      _memberNameControllers.add(TextEditingController());
      _memberRelationControllers.add(TextEditingController());
    });
  }

  void _removeHouseholdMember(int index) {
    setState(() {
      _memberNameControllers.removeAt(index).dispose();
      _memberRelationControllers.removeAt(index).dispose();
    });
  }

  Future<void> _save(AppUser user) async {
    setState(() => _saving = true);
    final household = <HouseholdMember>[];
    for (var i = 0; i < _memberNameControllers.length; i++) {
      final name = _memberNameControllers[i].text.trim();
      if (name.isEmpty) continue;
      household.add(HouseholdMember(name: name, relationship: _memberRelationControllers[i].text.trim()));
    }

    final updated = user.copyWith(
      displayName: _nameController.text.trim(),
      household: household,
      directoryOptIn: _directoryOptIn,
    );
    await _userService.updateProfile(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _memberNameControllers) {
      c.dispose();
    }
    for (final c in _memberRelationControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Column(
      children: [
        const AccountHeader(title: 'Profile', subtitle: 'Update your info and household.'),
        SectionContainer(
          maxWidth: 700,
          child: user == null
              ? const Center(child: CircularProgressIndicator())
              : Builder(builder: (context) {
                  _initFromUser(user);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                        child: Text(user.email),
                      ),
                      const SizedBox(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('List me in the member directory'),
                        subtitle: const Text('Other members will be able to see your name and contact info.'),
                        value: _directoryOptIn,
                        onChanged: (value) => setState(() => _directoryOptIn = value),
                      ),
                      const SizedBox(height: 16),
                      Text('Household', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      for (var i = 0; i < _memberNameControllers.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _memberNameControllers[i],
                                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _memberRelationControllers[i],
                                  decoration:
                                      const InputDecoration(labelText: 'Relationship', border: OutlineInputBorder()),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeHouseholdMember(i),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      TextButton.icon(
                        onPressed: _addHouseholdMember,
                        icon: const Icon(Icons.add),
                        label: const Text('Add household member'),
                      ),
                      const SizedBox(height: 24),
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
                }),
        ),
      ],
    );
  }
}
