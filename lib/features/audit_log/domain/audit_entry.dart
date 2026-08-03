import 'package:flutter/foundation.dart';

/// A record of a change worth attributing to a person.
///
/// Deliberately not a general activity feed - only the actions where a
/// church would later ask "who did that?": settings edits, role changes,
/// and deletions of content.
@immutable
class AuditEntry {
  final String id;
  final String actorUid;
  final String actorName;
  final String action;
  final String entity;
  final String details;
  final DateTime at;

  const AuditEntry({
    this.id = '',
    required this.actorUid,
    required this.actorName,
    required this.action,
    required this.entity,
    this.details = '',
    required this.at,
  });

  factory AuditEntry.fromMap(String id, Map<String, dynamic> map) => AuditEntry(
        id: id,
        actorUid: map['actorUid'] as String? ?? '',
        actorName: map['actorName'] as String? ?? '',
        action: map['action'] as String? ?? '',
        entity: map['entity'] as String? ?? '',
        details: map['details'] as String? ?? '',
        at: DateTime.tryParse(map['at'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'actorUid': actorUid,
        'actorName': actorName,
        'action': action,
        'entity': entity,
        'details': details,
        'at': at.toIso8601String(),
      };

  String get summary => details.isEmpty ? '$action $entity' : '$action $entity - $details';
}
