/// Batalat — Cart models & Riverpod provider
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CartItemType { product, equipment, package, custom }

class CartItem {
  final String key;
  final CartItemType type;
  final int itemId;
  final String slug;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? thumbnail;
  final Map<String, dynamic> extra;

  const CartItem({
    required this.key,
    required this.type,
    required this.itemId,
    required this.slug,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.thumbnail,
    this.extra = const {},
  });

  double get lineTotal => unitPrice * quantity;

  List<String> get optionLabels {
    final raw = extra['option_labels'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    final opts = extra['options'];
    if (opts is List) {
      return opts.map((e) {
        if (e is Map) {
          final name = e['name']?.toString() ?? '';
          final text = e['text']?.toString() ?? '';
          return text.isEmpty ? name : '$name: $text';
        }
        return e.toString();
      }).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  String get typeApi => switch (type) {
        CartItemType.product => 'product',
        CartItemType.equipment => 'equipment',
        CartItemType.package => 'package',
        CartItemType.custom => 'custom',
      };

  CartItem copyWith({int? quantity}) {
    return CartItem(
      key: key,
      type: type,
      itemId: itemId,
      slug: slug,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      thumbnail: thumbnail,
      extra: extra,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'type': typeApi,
        'item_id': itemId,
        'slug': slug,
        'name': name,
        'unit_price': unitPrice,
        'quantity': quantity,
        'thumbnail': thumbnail,
        'extra': extra,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'product';
    final type = switch (typeStr) {
      'equipment' => CartItemType.equipment,
      'package' => CartItemType.package,
      'custom' => CartItemType.custom,
      _ => CartItemType.product,
    };
    return CartItem(
      key: json['key'] as String? ?? '${typeStr}_${json['item_id']}',
      type: type,
      itemId: json['item_id'] as int? ?? 0,
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ??
          double.tryParse('${json['unit_price']}') ??
          0,
      quantity: json['quantity'] as int? ?? 1,
      thumbnail: json['thumbnail'] as String?,
      extra: Map<String, dynamic>.from(
        (json['extra'] as Map?) ?? const {},
      ),
    );
  }

  Map<String, dynamic> toOrderPayload() {
    final details = <String, dynamic>{
      'slug': slug,
      ...extra,
    };
    if (itemId > 0) {
      details['item_id'] = itemId;
    } else {
      details.remove('item_id');
    }
    return {
      'type': typeApi,
      'name': name,
      'price': unitPrice,
      'quantity': quantity,
      'selected_option_ids': extra['selected_option_ids'] ?? [],
      'option_texts': extra['option_texts'] ?? {},
      'custom_quote_id': extra['custom_quote_id'],
      'extra_details': details,
    };
  }

  static String buildKey({
    required CartItemType type,
    required int itemId,
    List<int> optionIds = const [],
    int? customQuoteId,
  }) {
    final opts = [...optionIds]..sort();
    final quote = customQuoteId != null ? '_q$customQuoteId' : '';
    return '${type.name}_${itemId}_${opts.join('-')}$quote';
  }
}

class CartState {
  final List<CartItem> items;

  const CartState({this.items = const []});

  int get count => items.fold(0, (s, i) => s + i.quantity);

  double get subtotal => items.fold(0.0, (s, i) => s + i.lineTotal);

  CartState copyWith({List<CartItem>? items}) =>
      CartState(items: items ?? this.items);
}

class CartNotifier extends StateNotifier<CartState> {
  static const _storageKey = 'batalat_cart_v2';

  CartNotifier() : super(const CartState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey) ?? prefs.getString('batalat_cart_v1');
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = CartState(items: list);
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(state.items.map((e) => e.toJson()).toList()),
    );
  }

  void addItem({
    required CartItemType type,
    required int itemId,
    required String slug,
    required String name,
    required double unitPrice,
    String? thumbnail,
    int quantity = 1,
    Map<String, dynamic> extra = const {},
    String? key,
  }) {
    final optionIds = (extra['selected_option_ids'] as List?)
            ?.map((e) => int.tryParse('$e') ?? 0)
            .where((e) => e > 0)
            .toList() ??
        const <int>[];
    final quoteId = extra['custom_quote_id'] is int
        ? extra['custom_quote_id'] as int
        : int.tryParse('${extra['custom_quote_id'] ?? ''}');
    final lineKey = key ??
        CartItem.buildKey(
          type: type,
          itemId: itemId,
          optionIds: optionIds,
          customQuoteId: quoteId,
        );
    final existing = state.items.indexWhere((i) => i.key == lineKey);
    final items = [...state.items];
    if (existing >= 0) {
      final cur = items[existing];
      items[existing] = cur.copyWith(quantity: cur.quantity + quantity);
    } else {
      items.add(CartItem(
        key: lineKey,
        type: type,
        itemId: itemId,
        slug: slug,
        name: name,
        unitPrice: unitPrice,
        quantity: quantity,
        thumbnail: thumbnail,
        extra: extra,
      ));
    }
    state = CartState(items: items);
    _persist();
  }

  void updateQuantity(String key, int quantity) {
    if (quantity < 1) {
      removeItem(key);
      return;
    }
    final items = state.items.map((i) {
      if (i.key == key) return i.copyWith(quantity: quantity);
      return i;
    }).toList();
    state = CartState(items: items);
    _persist();
  }

  void removeItem(String key) {
    state = CartState(items: state.items.where((i) => i.key != key).toList());
    _persist();
  }

  void clear() {
    state = const CartState();
    _persist();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).count;
});
