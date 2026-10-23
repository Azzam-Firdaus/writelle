import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Minimalist flat App Bar adhering to Editorial Minimalism.
/// Ref: docs/UI_UX_DESIGN.md
class WrittleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isBrandTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBottomBorder;

  const WrittleAppBar({
    super.key,
    required this.title,
    this.isBrandTitle = false,
    this.actions,
    this.leading,
    this.showBottomBorder = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: leading,
      centerTitle: false,
      title: Text(
        title,
        style: isBrandTitle
            ? AppTypography.displayTitle.copyWith(fontSize: 22)
            : AppTypography.uiHeadline.copyWith(fontWeight: FontWeight.w600),
      ),
      actions: actions,
      bottom: showBottomBorder
          ? const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borderLight,
              ),
            )
          : null,
    );
  }
}
