/// Batalat — Package models
import 'package:batalat_app/core/network/media_url.dart';

class PackageOccasion {
  final String id;
  final String label;

  const PackageOccasion({required this.id, required this.label});

  factory PackageOccasion.fromJson(Map<String, dynamic> json) {
    return PackageOccasion(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }
}

class FlowerPackage {
  final int id;
  final String name;
  final String slug;
  final String occasion;
  final String? occasionDisplay;
  final double basePrice;
  final String? thumbnail;
  final bool isFeatured;
  final bool isCustomizable;
  final int preparationHours;

  const FlowerPackage({
    required this.id,
    required this.name,
    required this.slug,
    required this.occasion,
    this.occasionDisplay,
    required this.basePrice,
    this.thumbnail,
    this.isFeatured = false,
    this.isCustomizable = true,
    this.preparationHours = 24,
  });

  factory FlowerPackage.fromJson(Map<String, dynamic> json) {
    return FlowerPackage(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      occasion: json['occasion'] as String? ?? 'other',
      occasionDisplay: json['occasion_display'] as String?,
      basePrice: _parseDouble(json['base_price']),
      thumbnail: resolveMediaUrl(json['thumbnail'] as String?),
      isFeatured: json['is_featured'] as bool? ?? false,
      isCustomizable: json['is_customizable'] as bool? ?? true,
      preparationHours: json['preparation_hours'] as int? ?? 24,
    );
  }
}

class PackageImage {
  final int id;
  final String? image;
  final int order;

  const PackageImage({
    required this.id,
    this.image,
    this.order = 0,
  });

  factory PackageImage.fromJson(Map<String, dynamic> json) {
    return PackageImage(
      id: json['id'] as int,
      image: resolveMediaUrl(json['image'] as String?),
      order: json['order'] as int? ?? 0,
    );
  }
}

class PackageOption {
  final int id;
  final String optionType;
  final String name;
  final double additionalPrice;

  const PackageOption({
    required this.id,
    required this.optionType,
    required this.name,
    required this.additionalPrice,
  });

  factory PackageOption.fromJson(Map<String, dynamic> json) {
    return PackageOption(
      id: json['id'] as int,
      optionType: json['option_type'] as String? ?? '',
      name: json['name'] as String? ?? '',
      additionalPrice: _parseDouble(json['additional_price']),
    );
  }
}

class FlowerPackageDetail extends FlowerPackage {
  final String description;
  final List<PackageImage> images;
  final List<PackageOption> options;
  final Map<String, List<PackageOption>> optionsByType;

  const FlowerPackageDetail({
    required super.id,
    required super.name,
    required super.slug,
    required super.occasion,
    super.occasionDisplay,
    required super.basePrice,
    super.thumbnail,
    super.isFeatured,
    super.isCustomizable,
    super.preparationHours,
    required this.description,
    this.images = const [],
    this.options = const [],
    this.optionsByType = const {},
  });

  factory FlowerPackageDetail.fromJson(Map<String, dynamic> json) {
    final imagesJson = json['images'] as List<dynamic>? ?? [];
    final optionsJson = json['options'] as List<dynamic>? ?? [];
    final byTypeRaw = json['options_by_type'] as Map<String, dynamic>? ?? {};

    final byType = <String, List<PackageOption>>{};
    byTypeRaw.forEach((key, value) {
      final list = value as List<dynamic>? ?? [];
      byType[key] = list
          .map((e) => PackageOption.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    return FlowerPackageDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      occasion: json['occasion'] as String? ?? 'other',
      occasionDisplay: json['occasion_display'] as String?,
      basePrice: _parseDouble(json['base_price']),
      thumbnail: resolveMediaUrl(json['thumbnail'] as String?),
      isFeatured: json['is_featured'] as bool? ?? false,
      isCustomizable: json['is_customizable'] as bool? ?? true,
      preparationHours: json['preparation_hours'] as int? ?? 24,
      description: json['description'] as String? ?? '',
      images: imagesJson
          .map((e) => PackageImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      options: optionsJson
          .map((e) => PackageOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      optionsByType: byType,
    );
  }
}

class PaginatedPackages {
  final int count;
  final String? next;
  final String? previous;
  final List<FlowerPackage> results;

  const PaginatedPackages({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedPackages.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List<dynamic>? ?? [])
        .map((e) => FlowerPackage.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedPackages(
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
