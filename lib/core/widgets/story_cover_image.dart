import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Reusable widget to render story cover images from:
/// 1. Remote HTTP/HTTPS URLs (Supabase Storage public CDN, Unsplash, etc.)
/// 2. Base64 Data URIs (`data:image/...;base64,...`)
/// 3. Local filesystem file paths (picked directly from device gallery)
class StoryCoverImage extends StatelessWidget {
  final String? coverUrl;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final int? cacheWidth;

  const StoryCoverImage({
    super.key,
    required this.coverUrl,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.cacheWidth = 800,
  });

  Widget _defaultError(BuildContext context, Object error) {
    if (errorBuilder != null) {
      return errorBuilder!(context, error, null);
    }
    return Container(
      color: const Color(0xFFF3ECE0),
      child: const Center(
        child: Icon(Icons.auto_stories_outlined, size: 28, color: Color(0xFF9E8B75)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (coverUrl == null || coverUrl!.trim().isEmpty) {
      return _defaultError(context, 'empty');
    }

    final url = coverUrl!.trim();
    final effectiveCacheWidth = kIsWeb ? null : cacheWidth;

    // 1. Base64 Data URI
    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        if (commaIdx != -1) {
          final base64Data = url.substring(commaIdx + 1).replaceAll(RegExp(r'\s+'), '');
          final bytes = base64Decode(base64Data);
          return Image.memory(
            bytes,
            fit: fit,
            cacheWidth: effectiveCacheWidth,
            gaplessPlayback: true,
            errorBuilder: errorBuilder ?? (ctx, err, stack) => _defaultError(ctx, err),
          );
        }
      } catch (e) {
        return _defaultError(context, e);
      }
    }

    // 2. Local File Path (Android / iOS / Desktop)
    if (!kIsWeb && !url.startsWith('http://') && !url.startsWith('https://')) {
      try {
        final cleanPath = url.startsWith('file://') ? url.replaceFirst('file://', '') : url;
        final file = File(cleanPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: fit,
            cacheWidth: effectiveCacheWidth,
            gaplessPlayback: true,
            errorBuilder: errorBuilder ?? (ctx, err, stack) => _defaultError(ctx, err),
          );
        }
      } catch (e) {
        return _defaultError(context, e);
      }
      return _defaultError(context, 'File not found');
    }

    // 3. Remote Network URL
    return Image.network(
      url,
      fit: fit,
      cacheWidth: effectiveCacheWidth,
      gaplessPlayback: true,
      errorBuilder: errorBuilder ?? (ctx, err, stack) => _defaultError(ctx, err),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFF3ECE0),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B6F4E)),
              ),
            ),
          ),
        );
      },
    );
  }
}
