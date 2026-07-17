import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/church_config.dart';
import '../models/connect_submission.dart';

/// Submits Connect Card / Prayer Request form entries.
///
/// With [ChurchConfig.useFirebase] enabled, submissions are written to a
/// Firestore collection the church staff can review. Without a backend
/// configured, submissions fall back to opening a pre-filled email so
/// nothing is lost before Firebase is set up.
class ConnectService {
  const ConnectService();

  Future<void> submit(ConnectSubmission submission) async {
    if (ChurchConfig.useFirebase) {
      await FirebaseFirestore.instance.collection('submissions').add(submission.toMap());
      return;
    }

    final subject = submission.type == ConnectType.prayerRequest
        ? 'Prayer Request from ${submission.name}'
        : 'Connect Card from ${submission.name}';
    final body = 'Name: ${submission.name}\n'
        'Email: ${submission.email}\n'
        'Phone: ${submission.phone}\n\n'
        '${submission.message}';

    final uri = Uri(
      scheme: 'mailto',
      path: ChurchConfig.email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    await launchUrl(uri);
  }
}
