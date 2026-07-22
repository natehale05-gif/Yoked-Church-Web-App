import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/church_config.dart';
import '../../models/connect_submission.dart';
import '../../services/connect_service.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/section_container.dart';

class ConnectAdminScreen extends StatefulWidget {
  const ConnectAdminScreen({super.key});

  @override
  State<ConnectAdminScreen> createState() => _ConnectAdminScreenState();
}

class _ConnectAdminScreenState extends State<ConnectAdminScreen> {
  final ConnectService _service = const ConnectService();
  late Future<List<ConnectSubmission>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchSubmissions();
  }

  void _refresh() => setState(() => _future = _service.fetchSubmissions());

  Future<void> _toggleFollowedUp(ConnectSubmission submission) async {
    final updated = ConnectSubmission(
      id: submission.id,
      name: submission.name,
      email: submission.email,
      phone: submission.phone,
      message: submission.message,
      type: submission.type,
      submittedAt: submission.submittedAt,
      status: submission.status == SubmissionStatus.open ? SubmissionStatus.followedUp : SubmissionStatus.open,
      staffNote: submission.staffNote,
    );
    await _service.updateSubmission(updated);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminHeader(title: 'Connect Inbox', subtitle: 'Prayer requests and connect cards from the website.'),
        SectionContainer(
          maxWidth: 800,
          child: FutureBuilder<List<ConnectSubmission>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final submissions = snapshot.data ?? [];
              if (submissions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: Text('No submissions yet.')),
                );
              }
              return Column(
                children: submissions.map((submission) {
                  final isFollowedUp = submission.status == SubmissionStatus.followedUp;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Chip(
                                label: Text(submission.type == ConnectType.prayerRequest ? 'Prayer' : 'Connect'),
                                backgroundColor: ChurchConfig.primaryColor.withValues(alpha: 0.1),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(submission.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              Text(DateFormat.yMMMd().format(submission.submittedAt),
                                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${submission.email} · ${submission.phone}',
                              style: const TextStyle(color: Colors.black54)),
                          if (submission.message.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(submission.message),
                          ],
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () => _toggleFollowedUp(submission),
                              icon: Icon(isFollowedUp ? Icons.replay : Icons.check_circle_outline, size: 16),
                              label: Text(isFollowedUp ? 'Mark as Open' : 'Mark Followed Up'),
                            ),
                          ),
                        ],
                      ),
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
