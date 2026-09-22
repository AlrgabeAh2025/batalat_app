/// Batalat — قائمة جانبية للتنقل بين الشاشات
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/auth/providers/auth_provider.dart';
import 'package:batalat_app/features/auth/utils/auth_gate.dart';
import 'package:batalat_app/shared/widgets/batalat_logo.dart';
import 'package:batalat_app/shared/widgets/rose_pattern_background.dart';

/// مفتاح Scaffold الرئيسي لفتح الـ Drawer من الشاشات الفرعية
final GlobalKey<ScaffoldState> mainShellScaffoldKey = GlobalKey<ScaffoldState>();

class BatalatDrawer extends ConsumerWidget {
  const BatalatDrawer({super.key});

  void _closeThen(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuth = ref.watch(isAuthenticatedProvider);
    final user = ref.watch(currentUserProvider);
    final name = isAuth ? (user?['full_name'] as String? ?? 'مستخدم') : 'زائر';

    return Drawer(
      backgroundColor: AppColors.surface,
      child: Stack(
        children: [
          const RosePatternBackground(density: RoseDecorDensity.soft),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      const BatalatLogo(size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('باتلات', style: AppTextStyles.titleLarge),
                            const SizedBox(height: 2),
                            Text(
                              name,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textHint,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Iconsax.close_circle, size: 22),
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _DrawerItem(
                        icon: Iconsax.home,
                        label: 'الرئيسية',
                        onTap: () => _closeThen(
                          context,
                          () => context.go(AppRoutes.home),
                        ),
                      ),
                      _DrawerItem(
                        icon: Iconsax.category,
                        label: 'الأقسام',
                        onTap: () => _closeThen(
                          context,
                          () => context.go(AppRoutes.categories),
                        ),
                      ),
                      _DrawerItem(
                        icon: Iconsax.shopping_cart,
                        label: 'السلة',
                        onTap: () => _closeThen(
                          context,
                          () => context.go(AppRoutes.cart),
                        ),
                      ),
                      _DrawerItem(
                        icon: Iconsax.receipt,
                        label: 'طلباتي',
                        onTap: () => _closeThen(context, () {
                          if (!requireAuth(
                            context,
                            ref,
                            returnTo: AppRoutes.orders,
                            message: 'سجّل الدخول لمتابعة طلباتك',
                          )) {
                            return;
                          }
                          context.go(AppRoutes.orders);
                        }),
                      ),
                      _DrawerItem(
                        icon: Iconsax.edit,
                        label: 'طلب مخصص',
                        onTap: () => _closeThen(context, () {
                          if (!requireAuth(
                            context,
                            ref,
                            returnTo: AppRoutes.customRequestNew,
                            message: 'سجّل الدخول لإرسال طلب مخصص',
                          )) {
                            return;
                          }
                          context.push(AppRoutes.customRequestNew);
                        }),
                      ),
                      if (isAuth) ...[
                        _DrawerItem(
                          icon: Iconsax.notification,
                          label: 'الإشعارات',
                          onTap: () => _closeThen(
                            context,
                            () => context.push(AppRoutes.notifications),
                          ),
                        ),
                        _DrawerItem(
                          icon: Iconsax.location,
                          label: 'عناويني',
                          onTap: () => _closeThen(
                            context,
                            () => context.push(AppRoutes.addresses),
                          ),
                        ),
                        _DrawerItem(
                          icon: Iconsax.wallet_3,
                          label: 'محفظتي',
                          onTap: () => _closeThen(
                            context,
                            () => context.push(AppRoutes.wallet),
                          ),
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          'الدعم',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _DrawerItem(
                        icon: Iconsax.message_question,
                        label: 'الأسئلة الشائعة',
                        onTap: () => _closeThen(
                          context,
                          () => context.push(AppRoutes.faq),
                        ),
                      ),
                      _DrawerItem(
                        icon: Iconsax.call,
                        label: 'تواصل معنا',
                        onTap: () => _closeThen(
                          context,
                          () => context.push(AppRoutes.contact),
                        ),
                      ),
                      _DrawerItem(
                        icon: Iconsax.shield_tick,
                        label: 'الشروط والأحكام',
                        onTap: () => _closeThen(
                          context,
                          () => context.push(AppRoutes.terms),
                        ),
                      ),
                      _DrawerItem(
                        icon: Iconsax.lock,
                        label: 'سياسة الخصوصية',
                        onTap: () => _closeThen(
                          context,
                          () => context.push(AppRoutes.privacy),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: isAuth
                      ? _DrawerItem(
                          icon: Iconsax.user,
                          label: 'حسابي',
                          onTap: () => _closeThen(
                            context,
                            () => context.go(AppRoutes.profile),
                          ),
                        )
                      : Column(
                          children: [
                            _DrawerItem(
                              icon: Iconsax.login,
                              label: 'تسجيل الدخول',
                              onTap: () => _closeThen(
                                context,
                                () => context.push(AppRoutes.login),
                              ),
                            ),
                            _DrawerItem(
                              icon: Iconsax.user_add,
                              label: 'إنشاء حساب',
                              onTap: () => _closeThen(
                                context,
                                () => context.push(AppRoutes.register),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: AppTextStyles.labelLarge),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      horizontalTitleGap: 12,
    );
  }
}

/// زر فتح القائمة الجانبية
class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'القائمة',
      onPressed: () {
        // يفتح Drawer الخاص بـ MainShell حتى لو كانت الشاشة الفرعية لها Scaffold
        mainShellScaffoldKey.currentState?.openDrawer();
      },
      icon: const Icon(
        Iconsax.menu_1,
        color: AppColors.textPrimary,
        size: 22,
      ),
    );
  }
}
