/// Batalat — Custom AppBar Widget
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/shared/widgets/batalat_drawer.dart';

class BatalatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showMenuButton;
  final Widget? leading;
  final VoidCallback? onBack;

  const BatalatAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.showMenuButton = false,
    this.leading,
    this.onBack,
  });

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget = leading;
    if (leadingWidget == null) {
      if (showBackButton) {
        leadingWidget = IconButton(
          icon: const Icon(
            Iconsax.arrow_right_3,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () => _handleBack(context),
        );
      } else if (showMenuButton) {
        leadingWidget = const DrawerMenuButton();
      }
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      title: Text(title, style: AppTextStyles.headlineSmall),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
