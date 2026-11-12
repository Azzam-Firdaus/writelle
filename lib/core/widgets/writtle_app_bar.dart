import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'writelle_logo.dart';

/// Minimalist flat App Bar adhering to Editorial Luxury.
/// Displays the official Writelle Logo when [isBrandTitle] is true or title is 'Writelle'.
class WrittleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isBrandTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBottomBorder;
  final String? poeticGreeting;
  final Widget? titleWidget;

  const WrittleAppBar({
    super.key,
    required this.title,
    this.isBrandTitle = false,
    this.actions,
    this.leading,
    this.showBottomBorder = true,
    this.poeticGreeting,
    this.titleWidget,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isBrand = isBrandTitle || title.trim().toLowerCase() == 'writelle';

    Widget titleContent;
    if (titleWidget != null) {
      titleContent = titleWidget!;
    } else if (isBrand) {
      if (poeticGreeting != null && poeticGreeting!.trim().isNotEmpty) {
        titleContent = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const WritelleLogo.appBar(),
            const SizedBox(width: 8),
            Container(
              height: 14,
              width: 1,
              color: AppColors.borderColor(context).withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                poeticGreeting!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.storyBody.copyWith(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondaryColor(context),
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        );
      } else {
        titleContent = const WritelleLogo.appBar();
      }
    } else {
      titleContent = Text(
        title,
        style: AppTypography.pageHeader.copyWith(
          color: AppColors.textPrimaryColor(context),
        ),
      );
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: leading,
      centerTitle: false,
      title: titleContent,
      actions: actions,
      iconTheme: IconThemeData(color: AppColors.textPrimaryColor(context)),
      bottom: showBottomBorder
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppColors.borderColor(context).withValues(alpha: 0.6),
              ),
            )
          : null,
    );
  }
}
