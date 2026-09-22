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
    final cp = CategoryIconMapper.codePoint(icon, active: active);
    if (cp == null) {
      return Icon(
        active ? Icons.category : Icons.category_outlined,
        size: size,
        color: tint,
      );
    }

    // رسم عبر خط MaterialIcons مباشرة — يتجنب IconData غير الثابت
    // الذي يفشل بناء iOS release (tree-shake icons).
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          String.fromCharCode(cp),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: CategoryIconMapper.fontFamily,
            fontSize: size,
            color: tint,
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
  }
}
