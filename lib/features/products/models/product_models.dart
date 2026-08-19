/// Batalat — Product models (شجرة أقسام + أنواع موحّدة)
import 'package:batalat_app/core/network/media_url.dart';

class ProductItemKind {
  static const product = 'product';
  static const package = 'package';
  static const equipment = 'equipment';
}

class ProductCategory {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String? image;
  final String icon;
  final int productsCount;
  final bool isFeatured;
  final bool showInBottomNav;
  final int navOrder;
  final int order;
  final int? parentId;
  final List<ProductCategory> children;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.image,
    this.icon = '',
    this.productsCount = 0,
    this.isFeatured = false,
    this.showInBottomNav = false,
    this.navOrder = 0,
    this.order = 0,
    this.parentId,
    this.children = const [],
  });

  bool get isRoot => parentId == null;

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>? ?? [];
    return ProductCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String? ?? '',
      image: resolveMediaUrl(json['image'] as String?),
      icon: json['icon'] as String? ?? '',
      productsCount: json['products_count'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      showInBottomNav: json['show_in_bottom_nav'] as bool? ?? false,
      navOrder: json['nav_order'] as int? ?? 0,
      order: json['order'] as int? ?? 0,
      parentId: json['parent'] as int?,
      children: childrenJson
          .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProductOptionItem {
  final int id;
  final String optionType;
  final String name;
  final String icon;
  final double additionalPrice;
  final bool isActive;
  final String selectionMode;
  final bool isRequired;
  final int maxQuantity;
  final bool requiresText;
  final int order;

  const ProductOptionItem({
    required this.id,
    required this.optionType,
    required this.name,
    this.icon = '',
    this.additionalPrice = 0,
    this.isActive = true,
    this.selectionMode = 'multi',
    this.isRequired = false,
    this.maxQuantity = 1,
    this.requiresText = false,
    this.order = 0,
  });

  bool get isSingle => selectionMode == 'single';

  /// أيقونة العرض: من الأدمن أو افتراضية حسب نوع الإضافة
  String get displayIcon {
    if (icon.isNotEmpty) return icon;
    return switch (optionType) {
      'message' => 'message',
      'wrapping' => 'wrapping',
      'card' => 'card',
      'color' => 'color',
      'size' => 'size',
      'addon' => 'gift',
      _ => 'gift',
    };
  }

  factory ProductOptionItem.fromJson(Map<String, dynamic> json) {
    return ProductOptionItem(
      id: json['id'] as int,
      optionType: json['option_type'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      additionalPrice: _parseDouble(json['additional_price']),
      isActive: json['is_active'] as bool? ?? true,
      selectionMode: json['selection_mode'] as String? ?? 'multi',
      isRequired: json['is_required'] as bool? ?? false,
      maxQuantity: json['max_quantity'] as int? ?? 1,
      requiresText: json['requires_text'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }
}

class ProductItem {
  final int id;
  final String name;
  final String slug;
  final String itemKind;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final double price;
  final double? comparePrice;
  final int discountPercentage;
  final bool isOnSale;
  final String? thumbnail;
  final bool isFeatured;
  final int stock;
  final double? dailyPrice;
  final double? hourlyPrice;
  final String pricingType;

  ProductItem({
    required this.id,
    required this.name,
    required this.slug,
    this.itemKind = ProductItemKind.product,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    required this.price,
    this.comparePrice,
    this.discountPercentage = 0,
    this.isOnSale = false,
    this.thumbnail,
    this.isFeatured = false,
    this.stock = 0,
    this.dailyPrice,
    this.hourlyPrice,
    this.pricingType = '',
  });

  bool get isPackage => itemKind == ProductItemKind.package;
  bool get isEquipment => itemKind == ProductItemKind.equipment;
  bool get isProduct => itemKind == ProductItemKind.product;

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      itemKind: json['item_kind'] as String? ?? ProductItemKind.product,
      categoryId: json['category'] is int ? json['category'] as int : null,
      categoryName: json['category_name'] as String?,
      categorySlug: json['category_slug'] as String?,
      price: _parseDouble(json['price']),
      comparePrice: json['compare_price'] != null
          ? _parseDouble(json['compare_price'])
          : null,
      discountPercentage: json['discount_percentage'] as int? ?? 0,
      isOnSale: json['is_on_sale'] as bool? ?? false,
      thumbnail: resolveMediaUrl(json['thumbnail'] as String?),
      isFeatured: json['is_featured'] as bool? ?? false,
      stock: json['stock'] as int? ?? 0,
      dailyPrice: json['daily_price'] != null
          ? _parseDouble(json['daily_price'])
          : null,
      hourlyPrice: json['hourly_price'] != null
          ? _parseDouble(json['hourly_price'])
          : null,
      pricingType: json['pricing_type'] as String? ?? '',
    );
  }
}

class ProductImageItem {
  final int id;
  final String? image;
  final String altText;
  final int order;

  const ProductImageItem({
    required this.id,
    this.image,
    this.altText = '',
    this.order = 0,
  });

  factory ProductImageItem.fromJson(Map<String, dynamic> json) {
    return ProductImageItem(
      id: json['id'] as int,
      image: resolveMediaUrl(json['image'] as String?),
      altText: json['alt_text'] as String? ?? '',
      order: json['order'] as int? ?? 0,
    );
  }
}

class ProductDetail extends ProductItem {
  final String description;
  final String shortDescription;
  final ProductCategory? category;
  final List<ProductImageItem> images;
  final List<ProductOptionItem> options;
  final DateTime? createdAt;
  final String occasion;
  final bool isCustomizable;
  final int preparationHours;
  final String specifications;
  final int totalQuantity;
  final bool requiresDelivery;
  final int minRentalHours;
  final double depositAmount;

  ProductDetail({
    required super.id,
    required super.name,
    required super.slug,
    required super.price,
    super.itemKind,
    super.comparePrice,
    super.discountPercentage,
    super.isOnSale,
    super.thumbnail,
    super.isFeatured,
    super.stock,
    super.categoryName,
    super.categorySlug,
    super.dailyPrice,
    super.hourlyPrice,
    super.pricingType,
    int? categoryId,
    required this.description,
    this.shortDescription = '',
    this.category,
    this.images = const [],
    this.options = const [],
    this.createdAt,
    this.occasion = '',
    this.isCustomizable = false,
    this.preparationHours = 24,
    this.specifications = '',
    this.totalQuantity = 1,
    this.requiresDelivery = true,
    this.minRentalHours = 4,
    this.depositAmount = 0,
  }) : super(categoryId: categoryId ?? category?.id);

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'];
    ProductCategory? category;
    if (categoryJson is Map<String, dynamic>) {
      category = ProductCategory.fromJson(categoryJson);
    }

    final imagesJson = json['images'] as List<dynamic>? ?? [];
    final optionsJson = json['options'] as List<dynamic>? ?? [];

    return ProductDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      itemKind: json['item_kind'] as String? ?? ProductItemKind.product,
      price: _parseDouble(json['price']),
      comparePrice: json['compare_price'] != null
          ? _parseDouble(json['compare_price'])
          : null,
      discountPercentage: json['discount_percentage'] as int? ?? 0,
      isOnSale: json['is_on_sale'] as bool? ?? false,
      thumbnail: resolveMediaUrl(json['thumbnail'] as String?),
      isFeatured: json['is_featured'] as bool? ?? false,
      stock: json['stock'] as int? ?? 0,
      categoryId: category?.id,
      categoryName: category?.name,
      categorySlug: category?.slug,
      dailyPrice: json['daily_price'] != null
          ? _parseDouble(json['daily_price'])
          : null,
      hourlyPrice: json['hourly_price'] != null
          ? _parseDouble(json['hourly_price'])
          : null,
      pricingType: json['pricing_type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      category: category,
      images: imagesJson
          .map((e) => ProductImageItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      options: optionsJson
          .map((e) => ProductOptionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      occasion: json['occasion'] as String? ?? '',
      isCustomizable: json['is_customizable'] as bool? ?? false,
      preparationHours: json['preparation_hours'] as int? ?? 24,
      specifications: json['specifications'] as String? ?? '',
      totalQuantity: json['total_quantity'] as int? ?? 1,
      requiresDelivery: json['requires_delivery'] as bool? ?? true,
      minRentalHours: json['min_rental_hours'] as int? ?? 4,
      depositAmount: _parseDouble(json['deposit_amount']),
    );
  }
}

class HomeSection {
  final ProductCategory category;
  final List<ProductItem> products;

  const HomeSection({required this.category, required this.products});

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    final productsJson = json['products'] as List<dynamic>? ?? [];
    return HomeSection(
      category: ProductCategory.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      products: productsJson
          .map((e) => ProductItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HomeFeed {
  final List<ProductCategory> banners;
  final List<ProductCategory> categories;
  final List<HomeSection> sections;

  const HomeFeed({
    required this.banners,
    required this.categories,
    required this.sections,
  });

  factory HomeFeed.fromJson(Map<String, dynamic> json) {
    return HomeFeed(
      banners: (json['banners'] as List<dynamic>? ?? [])
          .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((e) => HomeSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PaginatedProducts {
  final int count;
  final String? next;
  final String? previous;
  final List<ProductItem> results;

  const PaginatedProducts({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedProducts.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>? ?? [])
        .map((e) => ProductItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedProducts(
      count: json['count'] as int? ?? results.length,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: results,
    );
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
