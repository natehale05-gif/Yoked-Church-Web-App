import 'package:flutter/material.dart';

import '../../config/church_config.dart';
import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../widgets/account_header.dart';
import '../../widgets/section_container.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final UserService _service = UserService();
  late final Future<List<AppUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AccountHeader(
          title: 'Member Directory',
          subtitle: 'Members who have opted in to be listed here.',
        ),
        SectionContainer(
          maxWidth: 700,
          child: FutureBuilder<List<AppUser>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final members = snapshot.data ?? [];
              if (members.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: Text('No members have opted into the directory yet.')),
                );
              }
              return Column(
                children: members.map((member) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: ChurchConfig.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                          style: TextStyle(color: ChurchConfig.primaryColor, fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(member.email),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
