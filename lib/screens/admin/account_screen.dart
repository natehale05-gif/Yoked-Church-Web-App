import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import 'admin_widgets.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _user;
  final _pass = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = TextEditingController(
        text: context.read<AuthController>().username);
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSection(
            title: 'Credentials',
            description:
                'Update the admin username and password for this church.',
            children: [
              TextField(
                controller: _user,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password (leave blank to keep)',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await auth.updateCredentials(
                    username: _user.text,
                    newPassword: _pass.text.isEmpty ? null : _pass.text,
                  );
                  if (context.mounted) {
                    _pass.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Credentials updated')),
                    );
                  }
                },
                child: const Text('Save credentials'),
              ),
            ],
          ),
          AdminSection(
            title: 'Session',
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await auth.signOut();
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
