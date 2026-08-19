/// Batalat — Price Tag Widget
import 'package:flutter/material.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';

class PriceTag extends StatelessWidget {
  final double price;
  final double? comparePrice;
  final bool showCurrency;
  final bool large;

  const PriceTag({
    super.key,
    required this.price,
    this.comparePrice,
    this.showCurrency = true,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOnSale = comparePrice != null && comparePrice! > price;
    final currency = showCurrency ? ' ${AppConstants.currency}' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '${price.toStringAsFixed(0)}$currency',
          style: large ? AppTextStyles.price : AppTextStyles.priceSmall,
        ),
        if (isOnSale) ...[
          const SizedBox(width: 6),
          Text(
            '${comparePrice!.toStringAsFixed(0)}$currency',
            style: AppTextStyles.priceOld,
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-${(((comparePrice! - price) / comparePrice!) * 100).round()}%',
              style: AppTextStyles.badge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}

