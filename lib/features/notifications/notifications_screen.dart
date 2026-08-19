/// Batalat — Notifications Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/notifications/providers/notifications_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BatalatAppBar(
        title: 'الإشعارات',
        actions: [
          IconButton(
            tooltip: 'تعليم الكل كمقروء',
            icon: const Icon(Iconsax.tick_circle, color: AppColors.primary),
            onPressed: () async {
              await markAllNotificationsRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationsCountProvider);
            },
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          emoji: '⚠️',
          title: 'تعذر التحميل',
          subtitle: e.toString(),
          actionLabel: 'إعادة',
          onAction: () => ref.invalidate(notificationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(notificationsProvider);
                ref.invalidate(unreadNotificationsCountProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyState(emoji: '🔔', title: 'لا توجد إشعارات'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationsCountProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = items[i];
                return InkWell(
                  onTap: () async {
                    if (!n.isRead) {
                      await markNotificationRead(n.id);
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadNotificationsCountProvider);
                    }
                    final orderId = n.orderId;
                    if (orderId != null && context.mounted) {
                      context.push('/orders/$orderId');
                      return;
                    }
                    final requestId = n.data['request_id'];
                    if (requestId != null && context.mounted) {
                      context.push('/custom-requests/$requestId');
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n.isRead
                          ? AppColors.surface
                          : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: n.isRead
                            ? AppColors.borderLight
                            : AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          n.isRead
                              ? Iconsax.notification
                              : Iconsax.notification5,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: AppTextStyles.titleSmall),
                              const SizedBox(height: 4),
                              Text(n.body, style: AppTextStyles.bodyMedium),
                              const SizedBox(height: 6),
                              Text(
                                _formatDate(n.createdAt),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
