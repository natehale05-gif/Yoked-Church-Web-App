class AppNotification {
  final String id;
  final String uid;
  final String title;
  final String message;
  final String linkPath;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.uid,
    required this.title,
    required this.message,
    this.linkPath = '',
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      uid: map['uid'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      linkPath: map['linkPath'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      read: map['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'title': title,
        'message': message,
        'linkPath': linkPath,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };
}
