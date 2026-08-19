/// Batalat — Packages providers (Riverpod)
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batalat_app/core/network/api_client.dart';
import '../models/package_models.dart';

// ============================================================
// Filter state
// ============================================================

class PackagesFilter {
  final String? occasion;
  final String? search;

  const PackagesFilter({this.occasion, this.search});

  PackagesFilter copyWith({
    String? occasion,
    String? search,
    bool clearOccasion = false,
    bool clearSearch = false,
  }) {
    return PackagesFilter(
      occasion: clearOccasion ? null : (occasion ?? this.occasion),
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackagesFilter &&
          occasion == other.occasion &&
          search == other.search;

  @override
  int get hashCode => Object.hash(occasion, search);
}

class PackagesFilterNotifier extends StateNotifier<PackagesFilter> {
  PackagesFilterNotifier() : super(const PackagesFilter());

  void setOccasion(String? occasion) {
    if (occasion == null || occasion == 'all') {
      state = state.copyWith(clearOccasion: true);
    } else {
      state = state.copyWith(occasion: occasion);
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

  void reset() => state = const PackagesFilter();
}

final packagesFilterProvider =
    StateNotifierProvider<PackagesFilterNotifier, PackagesFilter>((ref) {
  return PackagesFilterNotifier();
});

// ============================================================
// Occasions
// ============================================================

final occasionsProvider = FutureProvider<List<PackageOccasion>>((ref) async {
  try {
    final response = await ApiClient().dio.get('/packages/occasions/');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => PackageOccasion.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

// ============================================================
// Packages list
// ============================================================

final packagesListProvider =
    FutureProvider.autoDispose<PaginatedPackages>((ref) async {
  final filter = ref.watch(packagesFilterProvider);
  try {
    final query = <String, dynamic>{
      if (filter.occasion != null) 'occasion': filter.occasion,
      if (filter.search != null) 'search': filter.search,
    };
    final response = await ApiClient().dio.get(
      '/packages/',
      queryParameters: query.isEmpty ? null : query,
    );
    return PaginatedPackages.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

// ============================================================
// Featured packages (home)
// ============================================================

final featuredPackagesProvider =
    FutureProvider.autoDispose<List<FlowerPackage>>((ref) async {
  try {
    final response = await ApiClient().dio.get(
      '/packages/',
      queryParameters: {'is_featured': true},
    );
    final page = PaginatedPackages.fromJson(response.data as Map<String, dynamic>);
    return page.results;
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});

// ============================================================
// Package detail
// ============================================================

final packageDetailProvider =
    FutureProvider.autoDispose.family<FlowerPackageDetail, String>((ref, slug) async {
  try {
    final response = await ApiClient().dio.get('/packages/$slug/');
    return FlowerPackageDetail.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw ApiException.fromDioError(e);
  }
});
