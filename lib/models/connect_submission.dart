/// A form submission from the Connect / Prayer Request page.
/// [type] distinguishes a prayer request from a general connect card
/// so both can share one form and one Firestore collection.
enum ConnectType { prayerRequest, connectCard }

class ConnectSubmission {
  final String name;
  final String email;
  final String phone;
  final String message;
  final ConnectType type;
  final DateTime submittedAt;

  const ConnectSubmission({
    required this.name,
    required this.email,
    required this.phone,
    required this.message,
    required this.type,
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
        'type': type.name,
        'submittedAt': submittedAt.toIso8601String(),
      };
}
