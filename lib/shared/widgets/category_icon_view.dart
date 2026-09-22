/// Batalat — أيقونة قسم من Material Icons (نفس الاسم في لوحة الإدارة)
import 'package:flutter/material.dart';
import 'package:batalat_app/core/constants/category_icons.dart';
import 'package:batalat_app/core/theme/app_colors.dart';

class CategoryIconView extends StatelessWidget {
  final String? icon;
  final double size;
  final Color? color;
  final bool active;

  const CategoryIconView({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? (active ? AppColors.primary : AppColors.textHint);
    return Icon(
      CategoryIconMapper.iconData(icon, active: active),
      size: size,
      color: tint,
    );
  }
}
