/// Batalat — Status Badge Widget
import 'package:flutter/material.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  factory StatusBadge.fromOrderStatus(String status) {
    final map = {
      'pending':          _StatusStyle('قيد الانتظار',    AppColors.statusPending,   AppColors.warningLight),
      'confirmed':        _StatusStyle('مؤكد',            AppColors.statusConfirmed,  AppColors.infoLight),
      'preparing':        _StatusStyle('جاري التحضير',   AppColors.statusPreparing,  Color(0xFFF3EEFF)),
      'out_for_delivery': _StatusStyle('في الطريق',       AppColors.warning,          AppColors.warningLight),
      'delivered':        _StatusStyle('تم التسليم',      AppColors.statusDelivered,  AppColors.successLight),
      'cancelled':        _StatusStyle('ملغي',            AppColors.statusCancelled,  AppColors.errorLight),
    };
    final s = map[status] ?? _StatusStyle(status, AppColors.textHint, AppColors.borderLight);
    return StatusBadge(label: s.label, color: s.color, bgColor: s.bgColor);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.badge.copyWith(color: color),
      ),
    );
  }
}

class _StatusStyle {
  final String label;
  final Color color;
  final Color bgColor;
  const _StatusStyle(this.label, this.color, this.bgColor);
}

