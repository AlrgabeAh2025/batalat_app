/// Batalat — Loading Shimmer Widget
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/constants/app_constants.dart';

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = AppConstants.radiusMedium,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.borderLight,
      highlightColor: AppColors.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class PackageCardShimmer extends StatelessWidget {
  const PackageCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.borderLight,
      highlightColor: AppColors.surface,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        child: Column(
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusLarge),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, color: AppColors.borderLight),
                  const SizedBox(height: 6),
                  Container(height: 14, width: 80, color: AppColors.borderLight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListItemShimmer extends StatelessWidget {
  const ListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.borderLight,
      highlightColor: AppColors.surface,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        child: Row(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, color: AppColors.borderLight),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 120, color: AppColors.borderLight),
                  const SizedBox(height: 8),
                  Container(height: 18, width: 80, color: AppColors.borderLight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

