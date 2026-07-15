import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A premium, rounded image container built to showcase photos of people.
///
/// - Pass [imageUrl] (a network URL or bundled asset path) to show a real photo.
/// - When no image is provided, it shows a tasteful placeholder so the layout
///   always looks intentional and there is clearly room for a real photo.
///
/// This keeps the site "photo-first": every people section has generous,
/// well-composed space ready for real images.
class PhotoFrame extends StatelessWidget {
  final String? imageUrl;
  final double? aspectRatio;
  final double radius;
  final IconData placeholderIcon;
  final String? placeholderLabel;
  final BoxFit fit;

  const PhotoFrame({
    super.key,
    this.imageUrl,
    this.aspectRatio,
    this.radius = 20,
    this.placeholderIcon = Icons.person_outline,
    this.placeholderLabel,
    this.fit = BoxFit.cover,
  });

  bool get _isNetwork => imageUrl != null && imageUrl!.startsWith('http');

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      final image = _isNetwork
          ? Image.network(imageUrl!, fit: fit, errorBuilder: _onError)
          : Image.asset(imageUrl!, fit: fit, errorBuilder: _onError);
      content = image;
    } else {
      content = _Placeholder(
        icon: placeholderIcon,
        label: placeholderLabel,
      );
    }

    final frame = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: AppColors.cream,
        child: content,
      ),
    );

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.10),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: frame,
    );

    if (aspectRatio != null) {
      return AspectRatio(aspectRatio: aspectRatio!, child: decorated);
    }
    return decorated;
  }

  Widget _onError(BuildContext context, Object error, StackTrace? stack) {
    return _Placeholder(icon: placeholderIcon, label: placeholderLabel);
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final String? label;

  const _Placeholder({required this.icon, this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.photoPlaceholder,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.goldSoft, size: 46),
            if (label != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onDarkSoft,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A circular avatar variant for staff / leaders.
class PersonAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const PersonAvatar({super.key, this.imageUrl, this.size = 128});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: PhotoFrame(
          imageUrl: imageUrl,
          radius: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
