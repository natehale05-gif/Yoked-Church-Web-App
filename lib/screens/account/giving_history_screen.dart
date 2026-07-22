import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/church_config.dart';
import '../../models/giving_record.dart';
import '../../providers/auth_provider.dart';
import '../../services/giving_service.dart';
import '../../widgets/account_header.dart';
import '../../widgets/section_container.dart';

class GivingHistoryScreen extends StatefulWidget {
  const GivingHistoryScreen({super.key});

  @override
  State<GivingHistoryScreen> createState() => _GivingHistoryScreenState();
}

class _GivingHistoryScreenState extends State<GivingHistoryScreen> {
  final GivingService _service = GivingService();
  late final Future<List<GivingRecord>> _future;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
    _future = uid.isEmpty ? Future.value(const []) : _service.fetchMyGivingHistory(uid);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();

    return Column(
      children: [
        const AccountHeader(title: 'Giving History', subtitle: 'A record of your gifts to the church.'),
        SectionContainer(
          maxWidth: 700,
          child: FutureBuilder<List<GivingRecord>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final records = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(ChurchConfig.givingUrl), webOnlyWindowName: '_blank'),
                    icon: const Icon(Icons.favorite),
                    label: const Text('Give Online'),
                  ),
                  const SizedBox(height: 24),
                  if (records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        "No giving history on file yet. Once the church office records a gift, it'll show up here.",
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: records.map((record) {
                          return ListTile(
                            title: Text(record.fund),
                            subtitle: Text(DateFormat.yMMMd().format(record.date)),
                            trailing: Text(
                              currency.format(record.amount),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          );
                        }).toList(),
                      ),
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
