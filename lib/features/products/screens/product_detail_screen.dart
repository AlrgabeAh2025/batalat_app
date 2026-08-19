/// Batalat — Product Detail Screen (with selectable addons)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import 'package:batalat_app/core/network/api_client.dart';
import 'package:batalat_app/core/router/app_router.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';
import 'package:batalat_app/features/cart/providers/cart_provider.dart';
import 'package:batalat_app/shared/widgets/batalat_button.dart';
import 'package:batalat_app/shared/widgets/category_icon_view.dart';
import 'package:batalat_app/shared/widgets/empty_state.dart';
import 'package:batalat_app/shared/widgets/loading_shimmer.dart';
import 'package:batalat_app/shared/widgets/price_tag.dart';
import '../models/product_models.dart';
import '../providers/products_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String slug;

  const ProductDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(productDetailProvider(slug));

    return detailAsync.when(
      loading: () => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_right_3, color: AppColors.primary),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Padding(
          padding: EdgeInsets.all(AppConstants.screenPadding),
          child: Column(
            children: [
              LoadingShimmer(height: 280),
              SizedBox(height: 24),
              LoadingShimmer(height: 28),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_right_3, color: AppColors.primary),
            onPressed: () => context.pop(),
          ),
        ),
        body: EmptyState(
          emoji: '⚠️',
          title: 'تعذر تحميل المنتج',
          subtitle: e.toString(),
          actionLabel: 'إعادة المحاولة',
          onAction: () => ref.invalidate(productDetailProvider(slug)),
        ),
      ),
      data: (product) => _ProductDetailBody(product: product),
    );
  }
}

class _ProductDetailBody extends ConsumerStatefulWidget {
  final ProductDetail product;

  const _ProductDetailBody({required this.product});

  @override
  ConsumerState<_ProductDetailBody> createState() => _ProductDetailBodyState();
}

class _ProductDetailBodyState extends ConsumerState<_ProductDetailBody> {
  final Set<int> _selected = {};
  final Map<int, TextEditingController> _textCtrls = {};

  ProductDetail get product => widget.product;

  List<ProductOptionItem> get _activeOptions =>
      product.options.where((o) => o.isActive).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  double get _addonsTotal => _activeOptions
      .where((o) => _selected.contains(o.id))
      .fold(0.0, (s, o) => s + o.additionalPrice);

  double get _livePrice => product.price + _addonsTotal;

  @override
  void initState() {
    super.initState();
    for (final o in _activeOptions) {
      if (o.requiresText) {
        _textCtrls[o.id] = TextEditingController();
      }
      // اختيار أول خيار إلزامي single تلقائياً لكل نوع
    }
    _autoSelectRequiredSingles();
  }

  void _autoSelectRequiredSingles() {
    final byType = <String, List<ProductOptionItem>>{};
    for (final o in _activeOptions) {
      if (o.isSingle) {
        byType.putIfAbsent(o.optionType, () => []).add(o);
      }
    }
    for (final entry in byType.entries) {
      final required = entry.value.any((o) => o.isRequired);
      if (required && entry.value.isNotEmpty) {
        _selected.add(entry.value.first.id);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _textCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _typeLabel(String type) {
    return switch (type) {
      'size' => 'الحجم',
      'color' => 'اللون',
      'addon' => 'إضافات',
      'message' => 'رسالة',
      'wrapping' => 'تغليف',
      'card' => 'بطاقة',
      _ => type,
    };
  }

  String? _validateSelection() {
    for (final o in _activeOptions.where((o) => o.isRequired && !o.isSingle)) {
      if (!_selected.contains(o.id)) {
        return 'الإضافة مطلوبة: ${o.name}';
      }
    }
    final singleTypes = <String>{};
    for (final o in _activeOptions.where((o) => o.isSingle && o.isRequired)) {
      singleTypes.add(o.optionType);
    }
    for (final type in singleTypes) {
      final ids = _activeOptions
          .where((o) => o.optionType == type && o.isSingle)
          .map((o) => o.id);
      if (!_selected.any(ids.contains)) {
        return 'يجب اختيار: ${_typeLabel(type)}';
      }
    }
    for (final id in _selected) {
      final o = _activeOptions.cast<ProductOptionItem?>().firstWhere(
            (e) => e?.id == id,
            orElse: () => null,
          );
      if (o != null && o.requiresText) {
        final text = _textCtrls[id]?.text.trim() ?? '';
        if (text.isEmpty) return 'أدخل النص لـ «${o.name}»';
      }
    }
    return null;
  }

  void _toggleMulti(ProductOptionItem o) {
    setState(() {
      if (_selected.contains(o.id)) {
        _selected.remove(o.id);
      } else {
        _selected.add(o.id);
      }
    });
  }

  void _selectSingle(ProductOptionItem o) {
    setState(() {
      final sameType = _activeOptions
          .where((e) => e.optionType == o.optionType && e.isSingle)
          .map((e) => e.id);
      _selected.removeWhere(sameType.contains);
      _selected.add(o.id);
    });
  }

  void _addToCart() {
    final err = _validateSelection();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final selectedOpts =
        _activeOptions.where((o) => _selected.contains(o.id)).toList();
    final texts = <String, String>{};
    final labels = <String>[];
    final optionsPayload = <Map<String, dynamic>>[];
    for (final o in selectedOpts) {
      final text = _textCtrls[o.id]?.text.trim() ?? '';
      if (text.isNotEmpty) texts['${o.id}'] = text;
      labels.add(text.isEmpty ? o.name : '${o.name}: $text');
      optionsPayload.add({
        'id': o.id,
        'name': o.name,
        'option_type': o.optionType,
        'additional_price': o.additionalPrice,
        'text': text,
      });
    }

    ref.read(cartProvider.notifier).addItem(
          type: product.isPackage
              ? CartItemType.package
              : CartItemType.product,
          itemId: product.id,
          slug: product.slug,
          name: product.name,
          unitPrice: _livePrice,
          thumbnail: product.thumbnail,
          extra: {
            'selected_option_ids': selectedOpts.map((e) => e.id).toList(),
            'option_texts': texts,
            'options': optionsPayload,
            'option_labels': labels,
          },
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت الإضافة إلى السلة')),
    );
  }

  Future<void> _openCustomRequest() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomRequestSheet(productId: product.id),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم إرسال طلب التخصيص'),
          action: SnackBarAction(
            label: 'عرض',
            onPressed: () => context.push(AppRoutes.customRequests),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = <String>[
      if (product.thumbnail != null) product.thumbnail!,
      ...product.images.where((i) => i.image != null).map((i) => i.image!),
    ];
    final uniqueImages = <String>[];
    for (final url in imageUrls) {
      if (!uniqueImages.contains(url)) uniqueImages.add(url);
    }

    final singleGroups = <String, List<ProductOptionItem>>{};
    final multiOpts = <ProductOptionItem>[];
    for (final o in _activeOptions) {
      if (o.isSingle) {
        singleGroups.putIfAbsent(o.optionType, () => []).add(o);
      } else {
        multiOpts.add(o);
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Iconsax.arrow_right_3,
                    color: AppColors.primary,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: uniqueImages.isEmpty
                  ? Container(
                      color: AppColors.primarySurface,
                      child: const Center(
                        child: Icon(
                          Iconsax.box,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : PageView.builder(
                      itemCount: uniqueImages.length,
                      itemBuilder: (_, i) {
                        return CachedNetworkImage(
                          imageUrl: uniqueImages[i],
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.primarySurface),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.primarySurface,
                            child: const Icon(
                              Iconsax.box,
                              color: AppColors.primary,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: AppTextStyles.displaySmall,
                        ),
                      ),
                      PriceTag(price: _livePrice, large: true),
                    ],
                  ),
                  if (_addonsTotal > 0)
                    Text(
                      'الأساسي ${product.price.toStringAsFixed(0)} + إضافات ${_addonsTotal.toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text('الوصف', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isEmpty
                        ? 'لا يوجد وصف متاح حالياً.'
                        : product.description,
                    style: AppTextStyles.bodyLarge,
                  ),
                  for (final entry in singleGroups.entries) ...[
                    const SizedBox(height: 20),
                    Text(
                      _typeLabel(entry.key),
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.value.map((o) {
                        final selected = _selected.contains(o.id);
                        final label = o.additionalPrice > 0
                            ? '${o.name} (+${o.additionalPrice.toStringAsFixed(0)})'
                            : o.name;
                        return ChoiceChip(
                          avatar: CategoryIconView(
                            icon: o.displayIcon,
                            size: 18,
                            active: selected,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) => _selectSingle(o),
                          selectedColor: AppColors.primarySurface,
                        );
                      }).toList(),
                    ),
                  ],
                  if (multiOpts.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('الإضافات', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 8),
                    ...multiOpts.map((o) {
                      final selected = _selected.contains(o.id);
                      return Column(
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: selected,
                            activeColor: AppColors.primary,
                            secondary: CategoryIconView(
                              icon: o.displayIcon,
                              size: 22,
                              active: selected,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            title: Text(o.name, style: AppTextStyles.bodyMedium),
                            subtitle: Text(
                              o.additionalPrice > 0
                                  ? '+${o.additionalPrice.toStringAsFixed(0)} ${AppConstants.currency}'
                                  : 'مجاناً',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            onChanged: (_) => _toggleMulti(o),
                          ),
                          if (selected && o.requiresText)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextField(
                                controller: _textCtrls.putIfAbsent(
                                  o.id,
                                  () => TextEditingController(),
                                ),
                                decoration: InputDecoration(
                                  labelText: 'نص «${o.name}»',
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                  if (product.isCustomizable ||
                      product.isPackage ||
                      product.isProduct) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _openCustomRequest,
                      icon: const Icon(Iconsax.edit),
                      label: const Text('طلب إضافة مخصصة'),
                    ),
                  ],
                  if (product.isEquipment) ...[
                    const SizedBox(height: 24),
                    Text('تفاصيل الإيجار', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 8),
                    if (product.specifications.isNotEmpty)
                      Text(
                        product.specifications,
                        style: AppTextStyles.bodyMedium,
                      ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppConstants.screenPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: product.isEquipment
              ? BatalatButton(
                  label: 'احجز الإيجار',
                  onTap: () =>
                      context.push('/equipment/${product.slug}/rent'),
                )
              : BatalatButton(
                  label: (product.stock > 0 || product.isPackage)
                      ? 'إضافة — ${_livePrice.toStringAsFixed(0)} ${AppConstants.currency}'
                      : 'غير متوفر',
                  onTap: (product.stock > 0 || product.isPackage)
                      ? _addToCart
                      : null,
                ),
        ),
      ),
    );
  }
}

/// ورقة طلب التخصيص — تمتلك الـ controller وتتخلص منه بأمان بعد الإغلاق.
class _CustomRequestSheet extends StatefulWidget {
  const _CustomRequestSheet({required this.productId});

  final int productId;

  @override
  State<_CustomRequestSheet> createState() => _CustomRequestSheetState();
}

class _CustomRequestSheetState extends State<_CustomRequestSheet> {
  final _descCtrl = TextEditingController();
  final _images = <XFile>[];
  bool _submitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 75);
    if (!mounted || picked.isEmpty) return;
    setState(() {
      _images
        ..clear()
        ..addAll(picked.take(5));
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_descCtrl.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل وصفاً أوضح للطلب')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final form = FormData.fromMap({
        'product_id': widget.productId,
        'description': _descCtrl.text.trim(),
      });
      for (final img in _images) {
        form.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(img.path, filename: img.name),
          ),
        );
      }
      await ApiClient().dio.post(
        '/products/custom-requests/',
        data: form,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.fromDioError(e).message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('طلب إضافة مخصصة', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'صف طلبك وسيقوم الفريق بإرسال عرض سعر.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'وصف الطلب',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _submitting ? null : _pickImages,
                    icon: const Icon(Iconsax.gallery),
                    label: Text(
                      _images.isEmpty
                          ? 'إرفاق صور (اختياري)'
                          : '${_images.length} صور مرفقة',
                    ),
                  ),
                  const SizedBox(height: 16),
                  BatalatButton(
                    label: _submitting ? 'جاري الإرسال...' : 'إرسال الطلب',
                    onTap: _submitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
