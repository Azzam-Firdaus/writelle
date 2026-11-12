import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Tactile, bouncy Like button pill with micro-animations and optimistic state.
class WrittleLikePill extends StatefulWidget {
  final bool isLiked;
  final int likesCount;
  final VoidCallback? onTap;
  final bool Function()? onBeforeTap;
  final bool isCompact;

  const WrittleLikePill({
    super.key,
    required this.isLiked,
    required this.likesCount,
    this.onTap,
    this.onBeforeTap,
    this.isCompact = false,
  });

  @override
  State<WrittleLikePill> createState() => _WrittleLikePillState();
}

class _WrittleLikePillState extends State<WrittleLikePill>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late bool _liked;
  late int _count;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.isLiked;
    _count = widget.likesCount;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    // Subtle, delightful spring scale that stays within layout boundaries
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.90), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.14), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.10), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.10, end: 0.10), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.10, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant WrittleLikePill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isProcessing &&
        (oldWidget.isLiked != widget.isLiked || oldWidget.likesCount != widget.likesCount)) {
      _liked = widget.isLiked;
      _count = widget.likesCount;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null || _isProcessing) return;
    if (widget.onBeforeTap != null && !widget.onBeforeTap!()) {
      widget.onTap!();
      return;
    }
    HapticFeedback.lightImpact();

    setState(() {
      _liked = !_liked;
      _count += _liked ? 1 : -1;
      if (_count < 0) _count = 0;
      _isProcessing = true;
    });

    _animController.forward(from: 0.0);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.burntSienna;
    final inactiveColor = AppColors.textSecondaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = _liked
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    activeColor.withValues(alpha: 0.35),
                    activeColor.withValues(alpha: 0.20),
                  ]
                : [
                    const Color(0xFFFFECE5),
                    const Color(0xFFFFDDD0),
                  ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.softParchment.withValues(alpha: 0.12),
                    AppColors.softParchment.withValues(alpha: 0.05),
                  ]
                : [
                    AppColors.softParchment.withValues(alpha: 0.85),
                    AppColors.softParchment.withValues(alpha: 0.45),
                  ],
          );

    final borderColor = _liked
        ? activeColor.withValues(alpha: 0.50)
        : AppColors.warmSand.withValues(alpha: isDark ? 0.3 : 0.6);

    final shadows = _liked
        ? [
            BoxShadow(
              color: activeColor.withValues(alpha: isDark ? 0.25 : 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ];

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap != null ? _handleTap : null,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 9 : 12,
              vertical: widget.isCompact ? 4.5 : 6,
            ),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: shadows,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotationTransition(
                  turns: _rotationAnimation,
                  child: Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    size: widget.isCompact ? 14 : 16,
                    color: _liked ? activeColor : inactiveColor,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$_count',
                  style: AppTypography.captionMeta.copyWith(
                    fontSize: widget.isCompact ? 11.5 : 12.5,
                    fontWeight: _liked ? FontWeight.bold : FontWeight.w600,
                    color: _liked ? activeColor : AppColors.textPrimaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tactile, elastic ribbon Bookmark pill with spring animation and optimistic state.
class WrittleBookmarkPill extends StatefulWidget {
  final bool isBookmarked;
  final VoidCallback? onTap;
  final bool Function()? onBeforeTap;
  final bool isCompact;
  final String? label;

  const WrittleBookmarkPill({
    super.key,
    required this.isBookmarked,
    this.onTap,
    this.onBeforeTap,
    this.isCompact = false,
    this.label,
  });

  @override
  State<WrittleBookmarkPill> createState() => _WrittleBookmarkPillState();
}

class _WrittleBookmarkPillState extends State<WrittleBookmarkPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late bool _bookmarked;

  @override
  void initState() {
    super.initState();
    _bookmarked = widget.isBookmarked;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.72), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.72, end: 1.38), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.38, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutBack,
    ));
  }

  @override
  void didUpdateWidget(covariant WrittleBookmarkPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isBookmarked != widget.isBookmarked) {
      _bookmarked = widget.isBookmarked;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    if (widget.onBeforeTap != null && !widget.onBeforeTap!()) {
      widget.onTap!();
      return;
    }
    HapticFeedback.mediumImpact();

    setState(() {
      _bookmarked = !_bookmarked;
    });

    _animController.forward(from: 0.0);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.burntSienna;
    final inactiveColor = AppColors.textSecondaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = _bookmarked
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    activeColor.withValues(alpha: 0.35),
                    activeColor.withValues(alpha: 0.20),
                  ]
                : [
                    const Color(0xFFFEF3C7),
                    const Color(0xFFFDE68A),
                  ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.softParchment.withValues(alpha: 0.12),
                    AppColors.softParchment.withValues(alpha: 0.05),
                  ]
                : [
                    AppColors.softParchment.withValues(alpha: 0.85),
                    AppColors.softParchment.withValues(alpha: 0.45),
                  ],
          );

    final borderColor = _bookmarked
        ? activeColor.withValues(alpha: 0.55)
        : AppColors.warmSand.withValues(alpha: isDark ? 0.3 : 0.6);

    final shadows = _bookmarked
        ? [
            BoxShadow(
              color: activeColor.withValues(alpha: isDark ? 0.25 : 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ];

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap != null ? _handleTap : null,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.label != null ? 12 : (widget.isCompact ? 9 : 12),
              vertical: widget.isCompact ? 4.5 : 6,
            ),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: shadows,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  size: widget.isCompact ? 14 : 16,
                  color: _bookmarked ? activeColor : inactiveColor,
                ),
                if (widget.label != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    widget.label!,
                    style: AppTypography.captionMeta.copyWith(
                      fontSize: widget.isCompact ? 11.5 : 12.5,
                      fontWeight: _bookmarked ? FontWeight.bold : FontWeight.w600,
                      color: _bookmarked ? activeColor : AppColors.textPrimaryColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
