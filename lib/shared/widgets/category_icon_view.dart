/// Batalat — Shared category icon view (Iconsax or emoji fallback)
import 'package:flutter/material.dart';
import 'package:batalat_app/core/constants/category_icons.dart';
import 'package:batalat_app/core/theme/app_colors.dart';

class CategoryIconView extends StatelessWidget {
  final String? icon;
  final double size;
  final Color? color;
  final bool active;
  final bool preferEmoji;

  const CategoryIconView({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.active = false,
    this.preferEmoji = false,
  });

  @override
  Widget build(BuildContext context) {
    final def = CategoryIconMapper.defFor(icon);
    final tint = color ?? (active ? AppColors.primary : AppColors.textHint);

    // Prefer vector Iconsax when we have a catalog key
    if (!preferEmoji && def != null) {
      return Icon(
        CategoryIconMapper.iconData(icon, active: active),
        size: size,
        color: tint,
      );
    }

    // Emoji fallback (legacy or preferEmoji)
    return Text(
      CategoryIconMapper.emoji(icon),
      style: TextStyle(fontSize: size * 0.92, height: 1),
    );
  }
}
