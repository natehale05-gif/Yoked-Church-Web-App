class GivingFund {
  final String id;
  final String name;
  final String description;
  final String url;

  const GivingFund({
    required this.id,
    required this.name,
    this.description = '',
    this.url = '',
  });

  GivingFund copyWith({String? name, String? description, String? url}) =>
      GivingFund(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        url: url ?? this.url,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'url': url,
      };

  factory GivingFund.fromJson(Map<String, dynamic> json) => GivingFund(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}
