/// Batalat — Custom AppBar Widget
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';

class BatalatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? leading;

  const BatalatAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Iconsax.arrow_right_3,
                  color: AppColors.textPrimary, size: 22),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : leading,
      title: Text(title, style: AppTextStyles.headlineSmall),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

