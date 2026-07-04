import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/learning_step.dart';

class TeachingCardWidget extends StatelessWidget {
  final TeachingCardData data;
  final bool isIntro;
  final VoidCallback onNext;

  const TeachingCardWidget({
    super.key,
    required this.data,
    this.isIntro = false,
    required this.onNext,
  });

  /// Renders the lesson illustration. Bundled Flutter assets
  /// (`assets/openmoji/...` — the clean-image system, 2026-07-03) load via
  /// Image.asset; anything else is a backend URL served through
  /// CachedNetworkImage. Both fail soft to the lesson emoji.
  Widget _buildImage() {
    final url = data.imageUrl!;
    if (url.startsWith('assets/')) {
      return Container(
        height: 160,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: data.accentColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Image.asset(
          url,
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (ctx, error, stack) =>
              Text(data.emoji, style: const TextStyle(fontSize: 56)),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: ApiConfig.resolveMediaUrl(url),
      height: 200,
      width: double.infinity,
      fit: BoxFit.contain,
      placeholder: (ctx, _) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: data.accentColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: data.accentColor,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (ctx, url, error) => Container(
        height: 120,
        decoration: BoxDecoration(
          color: data.accentColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(data.emoji, style: const TextStyle(fontSize: 56)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = data.imageUrl != null && data.imageUrl!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildImage(),
            ),
            const SizedBox(height: 16),
          ] else
            Text(data.emoji, style: const TextStyle(fontSize: 56)),
          if (!hasImage) const SizedBox(height: 16),
          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: isIntro ? 26 : 22,
              fontWeight: FontWeight.bold,
              color: data.accentColor,
            ),
          ),
          const SizedBox(height: 16),
          // Content card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: data.accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: data.accentColor.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Text(
              data.content,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                height: 1.8,
                color: Color(0xFF2D3436),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Next button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: data.accentColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isIntro ? 'يلا نبدأ! 🚀' : 'التالي ←',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
