/// Batalat — Products providers (Riverpod) — كتالوج موحّد من Backend
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batalat_app/core/network/api_client.dart';
import '../models/product_models.dart';

Future<List<ProductCategory>> _fetchCategories({
  bool? isFeatured,
  bool rootOnly = false,
  bool tree = false,
  bool nav = false,
  String? parentSlug,
}) async {
  try {
    final query = <String, dynamic>{
      if (isFeatured != null) 'is_featured': isFeatured,
      if (rootOnly) 'root_only': true,
      if (tree) 'tree': 1,
      if (nav) 'nav': 1,
      if (parentSlug != null) 'parent': parentSlug,
    };
    final response = await ApiClient().dio.get(
      '/products/categories/',
      queryParameters: query.isEmpty ? null : query,
    );
    final data = response.data;
    final list = data is List
        ? data
        : (data is Map
            ? (data['results'] as List<dynamic>? ?? [])
            : <dynamic>[]);
    return list
        .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
}

Future<List<ProductItem>> _fetchProducts({
  String? categorySlug,
  String? itemKind,
  bool? isFeatured,
  String? search,
}) async {
  try {
    final query = <String, dynamic>{
      if (categorySlug != null) 'category': categorySlug,
      if (categorySlug != null) 'include_children': 1,
      if (itemKind != null) 'item_kind': itemKind,
      if (isFeatured != null) 'is_featured': isFeatured,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final response = await ApiClient().dio.get(
      '/products/',
      queryParameters: query.isEmpty ? null : query,
    );
    final page =
        PaginatedProducts.fromJson(response.data as Map<String, dynamic>);
    return page.results;
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
}

// ============================================================
// Filter state
// ============================================================

class ProductsFilter {
  final String? categorySlug;
  final String? itemKind;
  final String? search;

  const ProductsFilter({this.categorySlug, this.itemKind, this.search});

  ProductsFilter copyWith({
    String? categorySlug,
    String? itemKind,
    String? search,
    bool clearCategory = false,
    bool clearItemKind = false,
    bool clearSearch = false,
  }) {
    return ProductsFilter(
      categorySlug:
          clearCategory ? null : (categorySlug ?? this.categorySlug),
      itemKind: clearItemKind ? null : (itemKind ?? this.itemKind),
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductsFilter &&
          categorySlug == other.categorySlug &&
          itemKind == other.itemKind &&
          search == other.search;

  @override
  int get hashCode => Object.hash(categorySlug, itemKind, search);
}

class ProductsFilterNotifier extends StateNotifier<ProductsFilter> {
  ProductsFilterNotifier([ProductsFilter? initial])
      : super(initial ?? const ProductsFilter());

  void setCategory(String? slug) {
    if (slug == null || slug == 'all') {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(categorySlug: slug);
    }
  }

  void setItemKind(String? kind) {
    if (kind == null || kind.isEmpty) {
      state = state.copyWith(clearItemKind: true);
    } else {
      state = state.copyWith(itemKind: kind);
    }
  }

  void setSearch(String? search) {
    final q = search?.trim();
    if (q == null || q.isEmpty) {
      state = state.copyWith(clearSearch: true);
    } else {
      state = state.copyWith(search: q);
    }
  }

  void reset() => state = const ProductsFilter();
}

final productsFilterProvider =
    StateNotifierProvider<ProductsFilterNotifier, ProductsFilter>((ref) {
  return ProductsFilterNotifier();
});

/// Filter scoped to a catalog tab (by root category slug)
final catalogFilterProvider = StateNotifierProvider.autoDispose
    .family<ProductsFilterNotifier, ProductsFilter, String>((ref, rootSlug) {
  return ProductsFilterNotifier(ProductsFilter(categorySlug: rootSlug));
});

// ============================================================
// Categories / Home / Nav
// ============================================================

final productCategoriesProvider =
    FutureProvider<List<ProductCategory>>((ref) async {
  return _fetchCategories(rootOnly: true);
});

final categoryTreeProvider =
    FutureProvider<List<ProductCategory>>((ref) async {
  return _fetchCategories(tree: true);
});

/// تبويبات الشريط السفلي الديناميكية
final navCategoriesProvider =
    FutureProvider<List<ProductCategory>>((ref) async {
  return _fetchCategories(nav: true);
});

final featuredCategoriesProvider =
    FutureProvider<List<ProductCategory>>((ref) async {
  return _fetchCategories(isFeatured: true);
});

final homeFeedProvider = FutureProvider.autoDispose<HomeFeed>((ref) async {
  try {
    final response = await ApiClient().dio.get('/products/home/');
    return HomeFeed.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

final categoryChildrenProvider = FutureProvider.autoDispose
    .family<List<ProductCategory>, String>((ref, parentSlug) async {
  return _fetchCategories(parentSlug: parentSlug);
});

// ============================================================
// Products list
// ============================================================

final productsListProvider =
    FutureProvider.autoDispose<PaginatedProducts>((ref) async {
  final filter = ref.watch(productsFilterProvider);
  try {
    final query = <String, dynamic>{
      if (filter.categorySlug != null) 'category': filter.categorySlug,
      if (filter.categorySlug != null) 'include_children': 1,
      if (filter.itemKind != null) 'item_kind': filter.itemKind,
      if (filter.search != null) 'search': filter.search,
    };
    final response = await ApiClient().dio.get(
      '/products/',
      queryParameters: query.isEmpty ? null : query,
    );
    return PaginatedProducts.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

final catalogProductsProvider = FutureProvider.autoDispose
    .family<PaginatedProducts, String>((ref, rootSlug) async {
  final filter = ref.watch(catalogFilterProvider(rootSlug));
  try {
    final query = <String, dynamic>{
      'category': filter.categorySlug ?? rootSlug,
      'include_children': 1,
      if (filter.itemKind != null) 'item_kind': filter.itemKind,
      if (filter.search != null) 'search': filter.search,
    };
    final response = await ApiClient().dio.get(
      '/products/',
      queryParameters: query,
    );
    return PaginatedProducts.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

final featuredProductsProvider =
    FutureProvider.autoDispose<List<ProductItem>>((ref) async {
  return _fetchProducts(isFeatured: true);
});

final productDetailProvider = FutureProvider.autoDispose
    .family<ProductDetail, String>((ref, slug) async {
  try {
    final response = await ApiClient().dio.get('/products/$slug/');
    return ProductDetail.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});
