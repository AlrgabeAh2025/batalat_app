/// Batalat — Contact Screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/cms/providers/cms_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';

class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactAsync = ref.watch(contactProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BatalatAppBar(title: 'تواصل معنا'),
      body: contactAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          emoji: '⚠️',
          title: 'تعذر التحميل',
          subtitle: e.toString(),
          actionLabel: 'إعادة',
          onAction: () => ref.invalidate(contactProvider),
        ),
        data: (c) {
          return ListView(
            padding: const EdgeInsets.all(AppConstants.screenPadding),
            children: [
              if (c.phone.isNotEmpty)
                _tile(
                  Iconsax.call,
                  'الهاتف',
                  c.phone,
                  onTap: () => _open('tel:${c.phone}'),
                  onCopy: () => Clipboard.setData(ClipboardData(text: c.phone)),
                ),
              if (c.whatsapp.isNotEmpty)
                _tile(
                  Iconsax.message,
                  'واتساب',
                  c.whatsapp,
                  onTap: () {
                    final n = c.whatsapp.replaceAll(RegExp(r'[^\d+]'), '');
                    _open('https://wa.me/${n.replaceFirst('+', '')}');
                  },
                ),
              if (c.email.isNotEmpty)
                _tile(
                  Iconsax.sms,
                  'البريد',
                  c.email,
                  onTap: () => _open('mailto:${c.email}'),
                ),
              if (c.address.isNotEmpty)
                _tile(Iconsax.location, 'العنوان', c.address),
              if (c.workingHours.isNotEmpty)
                _tile(Iconsax.clock, 'ساعات العمل', c.workingHours),
              if (c.facebookUrl.isNotEmpty)
                _tile(
                  Iconsax.global,
                  'فيسبوك',
                  c.facebookUrl,
                  onTap: () => _open(c.facebookUrl),
                ),
              if (c.instagramUrl.isNotEmpty)
                _tile(
                  Iconsax.camera,
                  'إنستغرام',
                  c.instagramUrl,
                  onTap: () => _open(c.instagramUrl),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    VoidCallback? onCopy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: AppTextStyles.labelMedium),
        subtitle: Text(value, style: AppTextStyles.bodyMedium),
        onTap: onTap,
        trailing: onCopy == null
            ? null
            : IconButton(
                icon: const Icon(Iconsax.copy, size: 18),
                onPressed: onCopy,
              ),
      ),
    );
  }
}
