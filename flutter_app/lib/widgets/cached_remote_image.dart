import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/theme.dart';

String _imageSource(String? value) {
  final source = value?.trim();
  if (source == null || source.isEmpty) return '';

  final uri = Uri.tryParse(source);
  const imageHosts = {
    'filgoal.com',
    'www.filgoal.com',
    'media.filgoal.com',
    'semedia.filgoal.com',
  };
  if (uri == null ||
      uri.scheme != 'https' ||
      !imageHosts.contains(uri.host.toLowerCase())) {
    return source;
  }

  final proxyBase =
      '${AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '')}/football/image';
  return Uri.parse(proxyBase)
      .replace(queryParameters: {'url': source})
      .toString();
}

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

  Widget _fallback() => fallback ?? Container(
    width: width,
    height: height,
    color: kCardAlt,
    alignment: Alignment.center,
    child: Icon(fallbackIcon, color: Colors.white30),
  );

  @override
  Widget build(BuildContext context) {
    final source = _imageSource(url);
    final child = source.isEmpty
        ? _fallback()
        : CachedNetworkImage(
            imageUrl: source,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 180),
            memCacheWidth: width == null ? null : (width! * 3).round(),
            memCacheHeight: height == null ? null : (height! * 3).round(),
            placeholder: (_, __) => Container(
              width: width,
              height: height,
              color: kCardAlt,
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