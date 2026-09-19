import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/theme.dart';

class CachedRemoteImage extends StatelessWidget {
  const CachedRemoteImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_not_supported_outlined,
    this.fallback,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final Widget? fallback;

  Widget _fallback() =>
      fallback ??
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kCardAlt, kCard],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          border: Border.all(color: kLine),
        ),
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: kPrimary.withValues(alpha: .42)),
      );

  String? _normalizedUrl(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    final withScheme = raw.startsWith('//') ? 'https:$raw' : raw;
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty) return null;

    // FilGoal blocks some direct mobile requests. The API proxy adds the
    // source headers server-side and keeps the UI independent from that host.
    final host = uri.host.toLowerCase();
    if ((host == 'filgoal.com' || host.endsWith('.filgoal.com')) &&
        !withScheme.startsWith(AppConfig.apiBaseUrl)) {
      return '${AppConfig.apiBaseUrl}/football/image?url=${Uri.encodeComponent(withScheme)}';
    }
    return withScheme;
  }

  @override
  Widget build(BuildContext context) {
    final source = _normalizedUrl(url);
    final child = source == null || source.isEmpty
        ? _fallback()
        : CachedNetworkImage(
            imageUrl: source,
            width: width,
            height: height,
            fit: fit,
            filterQuality: FilterQuality.medium,
            useOldImageOnUrlChange: true,
            httpHeaders: const {
              'Accept':
                  'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
              'User-Agent': 'AlmasrySC/1.0 (Flutter)',
            },
            fadeInDuration: const Duration(milliseconds: 180),
            memCacheWidth: width == null ? null : (width! * 3).round(),
            memCacheHeight: height == null ? null : (height! * 3).round(),
            placeholder: (_, __) => Container(
              width: width,
              height: height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kCardAlt, kCard],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
            errorWidget: (_, __, ___) => _fallback(),
          );
    return borderRadius == null
        ? child
        : ClipRRect(borderRadius: borderRadius!, child: child);
  }
}

class CachedAvatar extends StatelessWidget {
  const CachedAvatar({
    super.key,
    required this.url,
    required this.size,
    this.fallbackIcon = Icons.person,
  });

  final String? url;
  final double size;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: CachedRemoteImage(
      url: url,
      width: size,
      height: size,
      fallbackIcon: fallbackIcon,
    ),
  );
}
