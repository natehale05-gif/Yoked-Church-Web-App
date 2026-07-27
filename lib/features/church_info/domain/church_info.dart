import 'package:flutter/foundation.dart';

@immutable
class StaffMember {
  final String id;
  final String name;
  final String role;
  final String bio;
  final String email;
  final String photoUrl;
  final int sortOrder;

  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    this.bio = '',
    this.email = '',
    this.photoUrl = '',
    this.sortOrder = 0,
  });

  factory StaffMember.fromMap(String id, Map<String, dynamic> map) => StaffMember(
        id: id,
        name: map['name'] as String? ?? '',
        role: map['role'] as String? ?? '',
        bio: map['bio'] as String? ?? '',
        email: map['email'] as String? ?? '',
        photoUrl: map['photoUrl'] as String? ?? '',
        sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'role': role,
        'bio': bio,
        'email': email,
        'photoUrl': photoUrl,
        'sortOrder': sortOrder,
      };

  StaffMember copyWith({
    String? id,
    String? name,
    String? role,
    String? bio,
    String? email,
    String? photoUrl,
    int? sortOrder,
  }) =>
      StaffMember(
        id: id ?? this.id,
        name: name ?? this.name,
        role: role ?? this.role,
        bio: bio ?? this.bio,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}

/// A campus or meeting location. Multi-campus churches add more than one;
/// single-campus churches just have the one and the UI reads the same.
@immutable
class ChurchLocation {
  final String id;
  final String name;
  final String address;
  final String description;
  final String mapUrl;
  final String imageUrl;
  final List<String> serviceTimes;
  final int sortOrder;

  const ChurchLocation({
    required this.id,
    required this.name,
    required this.address,
    this.description = '',
    this.mapUrl = '',
    this.imageUrl = '',
    this.serviceTimes = const [],
    this.sortOrder = 0,
  });

  factory ChurchLocation.fromMap(String id, Map<String, dynamic> map) => ChurchLocation(
        id: id,
        name: map['name'] as String? ?? '',
        address: map['address'] as String? ?? '',
        description: map['description'] as String? ?? '',
        mapUrl: map['mapUrl'] as String? ?? '',
        imageUrl: map['imageUrl'] as String? ?? '',
        serviceTimes: ((map['serviceTimes'] as List<dynamic>?) ?? const []).map((e) => '$e').toList(),
        sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'description': description,
        'mapUrl': mapUrl,
        'imageUrl': imageUrl,
        'serviceTimes': serviceTimes,
        'sortOrder': sortOrder,
      };

  ChurchLocation copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
    String? mapUrl,
    String? imageUrl,
    List<String>? serviceTimes,
    int? sortOrder,
  }) =>
      ChurchLocation(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address ?? this.address,
        description: description ?? this.description,
        mapUrl: mapUrl ?? this.mapUrl,
        imageUrl: imageUrl ?? this.imageUrl,
        serviceTimes: serviceTimes ?? this.serviceTimes,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}

@immutable
class Faq {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int sortOrder;

  const Faq({
    required this.id,
    required this.question,
    required this.answer,
    this.category = '',
    this.sortOrder = 0,
  });

  factory Faq.fromMap(String id, Map<String, dynamic> map) => Faq(
        id: id,
        question: map['question'] as String? ?? '',
        answer: map['answer'] as String? ?? '',
        category: map['category'] as String? ?? '',
        sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'question': question,
        'answer': answer,
        'category': category,
        'sortOrder': sortOrder,
      };

  Faq copyWith({String? id, String? question, String? answer, String? category, int? sortOrder}) => Faq(
        id: id ?? this.id,
        question: question ?? this.question,
        answer: answer ?? this.answer,
        category: category ?? this.category,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
