/// Batalat — Profile Screen
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/features/auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const BatalatAppBar(
        title: 'حسابي',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryLight, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Iconsax.user, size: 30, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?['full_name'] ?? 'مستخدم',
                          style: AppTextStyles.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?['phone'] ?? '+218 9X XXXXXXX',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            const SizedBox(height: 32),
            _SettingsGroup(
              title: 'إعدادات الحساب',
              items: [
                _SettingsItem(
                  icon: Iconsax.location,
                  title: 'عناويني',
                  onTap: () => context.push(AppRoutes.addresses),
                ),
                _SettingsItem(
                  icon: Iconsax.wallet_3,
                  title: 'محفظتي',
                  onTap: () => context.push(AppRoutes.wallet),
                ),
                _SettingsItem(
                  icon: Iconsax.card,
                  title: 'طرق الدفع',
                  onTap: () => context.push(AppRoutes.paymentMethods),
                ),
                _SettingsItem(
                  icon: Iconsax.edit,
                  title: 'طلباتي المخصصة',
                  onTap: () => context.push(AppRoutes.customRequests),
                ),
                _SettingsItem(
                  icon: Iconsax.add_circle,
                  title: 'طلب مخصص جديد',
                  onTap: () => context.push(AppRoutes.customRequestNew),
                ),
                _SettingsItem(
                  icon: Iconsax.box,
                  title: 'حجوزات الإيجار',
                  onTap: () => context.push(AppRoutes.myRentals),
                ),
                _SettingsItem(
                  icon: Iconsax.notification,
                  title: 'الإشعارات',
                  onTap: () => context.push(AppRoutes.notifications),
                ),
              ],
            ).animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 24),
            _SettingsGroup(
              title: 'الدعم والمساعدة',
              items: [
                _SettingsItem(
                  icon: Iconsax.message_question,
                  title: 'الأسئلة الشائعة',
                  onTap: () => context.push(AppRoutes.faq),
                ),
                _SettingsItem(
                  icon: Iconsax.call,
                  title: 'تواصل معنا',
                  onTap: () => context.push(AppRoutes.contact),
                ),
                _SettingsItem(
                  icon: Iconsax.shield_tick,
                  title: 'الشروط والأحكام',
                  onTap: () => context.push(AppRoutes.terms),
                ),
              ],
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              icon: const Icon(Iconsax.logout, color: AppColors.error),
              label: Text(
                'تسجيل الخروج',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
              ),
            ).animate(delay: 300.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.textHint)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: AppTextStyles.bodyLarge),
      trailing: const Icon(Iconsax.arrow_left_2, size: 18, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
