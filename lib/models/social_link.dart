class SocialLink {
  final String id;

  /// One of: facebook, instagram, youtube, x, tiktok, spotify, website.
  final String platform;
  final String url;

  const SocialLink({
    required this.id,
    required this.platform,
    required this.url,
  });

  SocialLink copyWith({String? platform, String? url}) => SocialLink(
        id: id,
        platform: platform ?? this.platform,
        url: url ?? this.url,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform': platform,
        'url': url,
      };

  factory SocialLink.fromJson(Map<String, dynamic> json) => SocialLink(
        id: json['id'] as String,
        platform: json['platform'] as String? ?? 'website',
        url: json['url'] as String? ?? '',
      );
}
