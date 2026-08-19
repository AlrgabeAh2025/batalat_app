/// Batalat — Equipment / rental models
import 'package:batalat_app/core/network/media_url.dart';

class EquipmentCategory {
  final int id;
  final String name;
  final String slug;
  final String icon;
  final String? image;
  final int equipmentCount;
  final int order;

  const EquipmentCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.icon = '',
    this.image,
    this.equipmentCount = 0,
    this.order = 0,
  });

  factory EquipmentCategory.fromJson(Map<String, dynamic> json) {
    return EquipmentCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String? ?? '',
      image: resolveMediaUrl(json['image'] as String?),
      equipmentCount: json['equipment_count'] as int? ?? 0,
      order: json['order'] as int? ?? 0,
    );
  }
}

class EquipmentItem {
  final int id;
  final String name;
  final String slug;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final String pricingType;
  final double dailyPrice;
  final double hourlyPrice;
  final String? thumbnail;
  final bool isFeatured;
  final bool requiresDelivery;
  final double depositAmount;
  final double oversizedDeliveryFee;

  EquipmentItem({
    required this.id,
    required this.name,
    required this.slug,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.pricingType = 'daily',
    this.dailyPrice = 0,
    this.hourlyPrice = 0,
    this.thumbnail,
    this.isFeatured = false,
    this.requiresDelivery = false,
    this.depositAmount = 0,
    this.oversizedDeliveryFee = 0,
  });

  double get displayPrice =>
      pricingType == 'hourly' ? hourlyPrice : dailyPrice;

  String get priceLabel =>
      pricingType == 'hourly' ? '/ساعة' : '/يوم';

  factory EquipmentItem.fromJson(Map<String, dynamic> json) {
    return EquipmentItem(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      categoryId: json['category'] is int ? json['category'] as int : null,
      categoryName: json['category_name'] as String?,
      categorySlug: json['category_slug'] as String?,
      pricingType: json['pricing_type'] as String? ?? 'daily',
      dailyPrice: _d(json['daily_price']),
      hourlyPrice: _d(json['hourly_price']),
      thumbnail: resolveMediaUrl(json['thumbnail'] as String?),
      isFeatured: json['is_featured'] as bool? ?? false,
      requiresDelivery: json['requires_delivery'] as bool? ?? false,
      depositAmount: _d(json['deposit_amount']),
      oversizedDeliveryFee: _d(json['oversized_delivery_fee']),
    );
  }
}

class EquipmentDetail extends EquipmentItem {
  final String description;
  final String specifications;
  final EquipmentCategory? category;
  final List<String> images;
  final int totalQuantity;
  final int availableQuantity;
  final int minRentalHours;
  final String returnPolicyText;
  final double lossFee;
  final double damageFee;
  final List<int> blockedRegionIds;

  EquipmentDetail({
    required super.id,
    required super.name,
    required super.slug,
    required super.pricingType,
    required super.dailyPrice,
    required super.hourlyPrice,
    super.thumbnail,
    super.isFeatured,
    super.requiresDelivery,
    super.depositAmount,
    super.oversizedDeliveryFee,
    super.categoryName,
    super.categorySlug,
    int? categoryId,
    required this.description,
    this.specifications = '',
    this.category,
    this.images = const [],
    this.totalQuantity = 0,
    this.availableQuantity = 0,
    this.minRentalHours = 1,
    this.returnPolicyText = '',
    this.lossFee = 0,
    this.damageFee = 0,
    this.blockedRegionIds = const [],
  }) : super(categoryId: categoryId ?? category?.id);

  factory EquipmentDetail.fromJson(Map<String, dynamic> json) {
    EquipmentCategory? cat;
    if (json['category'] is Map<String, dynamic>) {
      cat = EquipmentCategory.fromJson(json['category'] as Map<String, dynamic>);
    }
    final imgs = (json['images'] as List<dynamic>? ?? [])
        .map((e) => resolveMediaUrl((e as Map)['image'] as String?))
        .whereType<String>()
        .toList();
    final blocked = (json['blocked_region_ids'] as List<dynamic>? ?? [])
        .map((e) => e is int ? e : int.tryParse('$e') ?? 0)
        .where((e) => e > 0)
        .toList();

    return EquipmentDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      pricingType: json['pricing_type'] as String? ?? 'daily',
      dailyPrice: _d(json['daily_price']),
      hourlyPrice: _d(json['hourly_price']),
      thumbnail: resolveMediaUrl(json['thumbnail'] as String?),
      isFeatured: json['is_featured'] as bool? ?? false,
      requiresDelivery: json['requires_delivery'] as bool? ?? false,
      depositAmount: _d(json['deposit_amount']),
      oversizedDeliveryFee: _d(json['oversized_delivery_fee']),
      categoryId: cat?.id,
      categoryName: cat?.name,
      categorySlug: cat?.slug,
      description: json['description'] as String? ?? '',
      specifications: json['specifications'] as String? ?? '',
      category: cat,
      images: imgs,
      totalQuantity: json['total_quantity'] as int? ?? 0,
      availableQuantity: json['available_quantity'] as int? ?? 0,
      minRentalHours: json['min_rental_hours'] as int? ?? 1,
      returnPolicyText: json['return_policy_text'] as String? ?? '',
      lossFee: _d(json['loss_fee']),
      damageFee: _d(json['damage_fee']),
      blockedRegionIds: blocked,
    );
  }
}

class RentalQuote {
  final bool isAvailable;
  final int availableQuantity;
  final String pricingMode;
  final String durationLabel;
  final double rentalPrice;
  final double depositAmount;
  final double deliveryFee;
  final double totalPrice;
  final double lossFee;
  final double damageFee;
  final String returnPolicyText;
  final List<int> blockedRegionIds;

  const RentalQuote({
    required this.isAvailable,
    required this.availableQuantity,
    required this.pricingMode,
    required this.durationLabel,
    required this.rentalPrice,
    required this.depositAmount,
    required this.deliveryFee,
    required this.totalPrice,
    this.lossFee = 0,
    this.damageFee = 0,
    this.returnPolicyText = '',
    this.blockedRegionIds = const [],
  });

  factory RentalQuote.fromJson(Map<String, dynamic> json) {
    return RentalQuote(
      isAvailable: json['is_available'] as bool? ?? false,
      availableQuantity: json['available_quantity'] as int? ?? 0,
      pricingMode: json['pricing_mode'] as String? ?? 'daily',
      durationLabel: json['duration_label'] as String? ?? '',
      rentalPrice: _d(json['rental_price']),
      depositAmount: _d(json['deposit_amount']),
      deliveryFee: _d(json['delivery_fee']),
      totalPrice: _d(json['total_price']),
      lossFee: _d(json['loss_fee']),
      damageFee: _d(json['damage_fee']),
      returnPolicyText: json['return_policy_text'] as String? ?? '',
      blockedRegionIds: (json['blocked_region_ids'] as List<dynamic>? ?? [])
          .map((e) => e is int ? e : int.tryParse('$e') ?? 0)
          .where((e) => e > 0)
          .toList(),
    );
  }
}

class RentalBookingItem {
  final int id;
  final String bookingNumber;
  final int? productId;
  final String productSlug;
  final String equipmentName;
  final String? thumbnail;
  final int quantity;
  final DateTime startDate;
  final DateTime endDate;
  final String pricingMode;
  final String pricingModeDisplay;
  final double rentalPrice;
  final double depositAmount;
  final double deliveryFee;
  final double totalPrice;
  final String status;
  final String statusDisplay;
  final String returnCondition;
  final String returnConditionDisplay;
  final double damageCharge;
  final double depositRefunded;

  const RentalBookingItem({
    required this.id,
    required this.bookingNumber,
    this.productId,
    this.productSlug = '',
    required this.equipmentName,
    this.thumbnail,
    required this.quantity,
    required this.startDate,
    required this.endDate,
    this.pricingMode = 'daily',
    this.pricingModeDisplay = '',
    required this.rentalPrice,
    required this.depositAmount,
    required this.deliveryFee,
    required this.totalPrice,
    required this.status,
    required this.statusDisplay,
    this.returnCondition = '',
    this.returnConditionDisplay = '',
    this.damageCharge = 0,
    this.depositRefunded = 0,
  });

  factory RentalBookingItem.fromJson(Map<String, dynamic> json) {
    return RentalBookingItem(
      id: json['id'] as int,
      bookingNumber: json['booking_number'] as String? ?? '',
      productId: json['product_id'] as int?,
      productSlug: json['product_slug'] as String? ?? '',
      equipmentName: json['equipment_name'] as String? ?? '',
      thumbnail: resolveMediaUrl(json['equipment_thumbnail'] as String?),
      quantity: json['quantity'] as int? ?? 1,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      pricingMode: json['pricing_mode'] as String? ?? 'daily',
      pricingModeDisplay: json['pricing_mode_display'] as String? ?? '',
      rentalPrice: _d(json['rental_price']),
      depositAmount: _d(json['deposit_amount']),
      deliveryFee: _d(json['delivery_fee']),
      totalPrice: _d(json['total_price']),
      status: json['status'] as String? ?? '',
      statusDisplay: json['status_display'] as String? ?? '',
      returnCondition: json['return_condition'] as String? ?? '',
      returnConditionDisplay: json['return_condition_display'] as String? ?? '',
      damageCharge: _d(json['damage_charge']),
      depositRefunded: _d(json['deposit_refunded']),
    );
  }
}

class PaginatedEquipment {
  final int count;
  final List<EquipmentItem> results;

  const PaginatedEquipment({required this.count, required this.results});

  factory PaginatedEquipment.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>? ?? [])
        .map((e) => EquipmentItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedEquipment(
      count: json['count'] as int? ?? results.length,
      results: results,
    );
  }
}

double _d(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
