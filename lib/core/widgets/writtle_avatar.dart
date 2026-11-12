import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Resolves an avatar image source from:
/// 1. Data URI (`data:image/...;base64,...`)
/// 2. Local device filesystem path (`/data/user/0/...` or `C:\...`)
/// 3. Remote CDN network URL (`https://...`)
ImageProvider? getWrittleImageProvider(String? imagePathOrUrl) {
  if (imagePathOrUrl == null || imagePathOrUrl.trim().isEmpty) return null;
  final clean = imagePathOrUrl.trim();

  // 1. Data URI
  if (clean.startsWith('data:image')) {
    final comma = clean.indexOf(',');
    if (comma != -1) {
      try {
        final b64 = clean.substring(comma + 1).replaceAll(RegExp(r'\s+'), '');
        return MemoryImage(base64Decode(b64));
      } catch (_) {
        return null;
      }
    }
  }

  // 2. Local File
  if (!kIsWeb && !clean.startsWith('http://') && !clean.startsWith('https://')) {
    final filePath = clean.startsWith('file://') ? clean.replaceFirst('file://', '') : clean;
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}
  }

  // 3. Remote Network URL
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return NetworkImage(clean);
  }

  return null;
}

/// Reusable circular avatar widget for Writelle profiles and authors.
class WrittleAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final String fallbackInitial;
  final VoidCallback? onTap;

  const WrittleAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 42,
    this.fallbackInitial = 'W',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rawProvider = getWrittleImageProvider(avatarUrl);
    final targetDim = (radius * 2.5).clamp(48.0, 300.0).toInt();
    final imageProvider = rawProvider != null && !kIsWeb
        ? ResizeImage(rawProvider, width: targetDim, height: targetDim)
        : rawProvider;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surfaceWarmColor(context),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              fallbackInitial.isNotEmpty ? fallbackInitial[0].toUpperCase() : 'W',
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: AppColors.accentPrimary,
              ),
            )
          : null,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      );
    }
    return avatar;
  }
}
