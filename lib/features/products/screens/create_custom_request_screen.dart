/// Batalat — Create free-form custom request
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/core/network/api_client.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/features/products/providers/customization_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_app_bar.dart';
import 'package:batalat_app/shared/widgets/batalat_button.dart';
import 'package:batalat_app/shared/widgets/rose_pattern_background.dart';

class CreateCustomRequestScreen extends ConsumerStatefulWidget {
  const CreateCustomRequestScreen({super.key});

  @override
  ConsumerState<CreateCustomRequestScreen> createState() =>
      _CreateCustomRequestScreenState();
}

class _CreateCustomRequestScreenState
    extends ConsumerState<CreateCustomRequestScreen> {
  final _descController = TextEditingController();
  final _titleController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  bool _loading = false;

  @override
  void dispose() {
    _descController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_images.length >= 5) return;
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked.take(5 - _images.length));
    });
  }

  Future<void> _submit() async {
    final desc = _descController.text.trim();
    if (desc.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب وصفاً أوضح للطلب (5 أحرف على الأقل)')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final created = await createCustomRequest(
        description: desc,
        title: _titleController.text.trim(),
        images: _images,
      );
      ref.invalidate(myCustomRequestsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الطلب — سنرسل لك عرض سعر قريباً')),
      );
      context.pushReplacement('${AppRoutes.customRequests}/${created.id}');
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoseDecorScaffold(
      density: RoseDecorDensity.soft,
      appBar: const BatalatAppBar(title: 'طلب مخصص'),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        children: [
          Text(
            'صف الباقة أو الزينة التي تحتاجها وأرفق صورة مرجعية إن وُجدت. سنرد عليك بعرض سعر.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text('عنوان مختصر (اختياري)', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'مثال: باقة زفاف بيضاء',
            ),
          ),
          const SizedBox(height: 16),
          Text('وصف الطلب *', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'الألوان، الحجم، المناسبة، وأي تفاصيل أخرى...',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('صور مرجعية', style: AppTextStyles.labelLarge),
              const Spacer(),
              TextButton.icon(
                onPressed: _images.length >= 5 ? null : _pickImages,
                icon: const Icon(Iconsax.gallery_add),
                label: Text('إضافة (${_images.length}/5)'),
              ),
            ],
          ),
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_images[i].path),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: InkWell(
                          onTap: () => setState(() => _images.removeAt(i)),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 32),
          BatalatButton(
            label: 'إرسال الطلب',
            isLoading: _loading,
            onTap: _loading ? null : _submit,
          ),
        ],
      ),
    );
  }
}
