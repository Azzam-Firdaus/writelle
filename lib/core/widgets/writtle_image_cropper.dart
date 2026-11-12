import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Interactive modal sheet / dialog to crop story cover images to the standard 16:9 ratio.
class WrittleImageCropper extends StatefulWidget {
  final File imageFile;

  const WrittleImageCropper({
    super.key,
    required this.imageFile,
  });

  /// Opens the crop dialog and returns the cropped [File], or `null` if cancelled.
  static Future<File?> crop(BuildContext context, {required File imageFile}) {
    return Navigator.of(context).push<File>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => WrittleImageCropper(imageFile: imageFile),
      ),
    );
  }

  @override
  State<WrittleImageCropper> createState() => _WrittleImageCropperState();
}

class _WrittleImageCropperState extends State<WrittleImageCropper> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  Future<void> _applyCrop() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final boundary = _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Navigator.of(context).pop(null);
        return;
      }

      // Render the repaint boundary at 2.5x pixel ratio for sharp cover quality
      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (mounted) Navigator.of(context).pop(null);
        return;
      }

      final buffer = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final tempFilePath = '${tempDir.path}/writtle_cover_${DateTime.now().millisecondsSinceEpoch}.png';
      final croppedFile = File(tempFilePath);
      await croppedFile.writeAsBytes(buffer);

      if (mounted) {
        Navigator.of(context).pop(croppedFile);
      }
    } catch (e) {
      debugPrint('[WrittleImageCropper] Error applying crop: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to crop cover: $e')),
        );
        Navigator.of(context).pop(null);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final cropWidth = mediaQuery.size.width - 32.0;
    final cropHeight = cropWidth * (9.0 / 16.0); // 16:9 aspect ratio standard

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text(
          'Crop Cover (16:9)',
          style: AppTypography.storyHeading.copyWith(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _applyCrop,
            child: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.burntSienna,
                    ),
                  )
                : Text(
                    'Apply',
                    style: AppTypography.uiBodyMedium.copyWith(
                      color: AppColors.burntSienna,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // 16:9 Viewport Crop Area
            Center(
              child: Container(
                width: cropWidth,
                height: cropHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.85),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRect(
                  child: Stack(
                    children: [
                      // Interactive Pannable and Zoomable Image
                      RepaintBoundary(
                        key: _cropKey,
                        child: SizedBox(
                          width: cropWidth,
                          height: cropHeight,
                          child: InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 1.0,
                            maxScale: 5.0,
                            panEnabled: true,
                            scaleEnabled: true,
                            child: Image.file(
                              widget.imageFile,
                              fit: BoxFit.cover,
                              width: cropWidth,
                              height: cropHeight,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Rule-of-Thirds Grid Overlay
                      IgnorePointer(
                        child: CustomPaint(
                          size: Size(cropWidth, cropHeight),
                          painter: _GridOverlayPainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Bottom Instructions & Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pinch, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Pinch to zoom & drag to frame',
                        style: AppTypography.captionMeta.copyWith(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _resetZoom,
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                    label: Text(
                      'Reset',
                      style: AppTypography.captionMeta.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws subtle rule-of-thirds grid lines over the 16:9 crop viewport
class _GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.0;

    // Vertical third lines
    final thirdWidth = size.width / 3.0;
    canvas.drawLine(Offset(thirdWidth, 0), Offset(thirdWidth, size.height), paint);
    canvas.drawLine(Offset(thirdWidth * 2, 0), Offset(thirdWidth * 2, size.height), paint);

    // Horizontal third lines
    final thirdHeight = size.height / 3.0;
    canvas.drawLine(Offset(0, thirdHeight), Offset(size.width, thirdHeight), paint);
    canvas.drawLine(Offset(0, thirdHeight * 2), Offset(size.width, thirdHeight * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
