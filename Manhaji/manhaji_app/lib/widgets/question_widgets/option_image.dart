import 'package:flutter/material.dart';
import '../../config/api_config.dart';

/// Renders a question/option picture from either a bundled asset
/// (`assets/openmoji/apple.png`) or a backend-served URL. Fail-soft: when the
/// path is null/empty or the image can't load, it renders nothing (size zero),
/// so a picture question still works as a text question.
///
/// This is the single resolver Tier-1 image question types use, so adding new
/// images (asset or remote) needs no per-widget logic.
class OptionImage extends StatelessWidget {
  const OptionImage({
    super.key,
    required this.path,
    this.size = 96,
    this.fit = BoxFit.contain,
  });

  final String? path;
  final double size;
  final BoxFit fit;

  bool get hasImage => path != null && path!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final p = path?.trim();
    if (p == null || p.isEmpty) return const SizedBox.shrink();

    final isAsset = p.startsWith('assets/');

    Widget onError(BuildContext context, Object error, StackTrace? stack) =>
        const SizedBox.shrink();

    return isAsset
        ? Image.asset(
            p,
            width: size,
            height: size,
            fit: fit,
            errorBuilder: onError,
          )
        : Image.network(
            ApiConfig.resolveMediaUrl(p),
            width: size,
            height: size,
            fit: fit,
            errorBuilder: onError,
          );
  }
}
