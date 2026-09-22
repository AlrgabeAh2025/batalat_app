/// Batalat — أيقونات الأقسام من Material Icons (Google / Flutter Icons)
/// القيمة في API = اسم الأيقونة (مثل local_florist / card_giftcard)
/// يطابق ``Icons.<name>`` في Flutter ولوحة الإدارة.
import 'package:flutter/material.dart';

import 'material_icons_codepoints.dart';

/// مفاتيح قديمة (دلالي / Iconsax / إيموجي) → Material Icons
const Map<String, String> kLegacyIconToMaterial = {
  'bouquet': 'local_florist',
  'flower': 'local_florist',
  'tulip': 'local_florist',
  'blossom': 'local_florist',
  'gift': 'card_giftcard',
  'balloon': 'celebration',
  'ribbon': 'card_giftcard',
  'wrapping': 'shopping_bag',
  'message': 'message',
  'note': 'sticky_note_2',
  'card': 'credit_card',
  'color': 'palette',
  'size': 'straighten',
  'heart': 'favorite',
  'ring': 'diamond',
  'cake': 'cake',
  'party': 'celebration',
  'graduation': 'school',
  'baby': 'child_care',
  'sparkles': 'auto_awesome',
  'star': 'star',
  'candle': 'lightbulb',
  'shop': 'storefront',
  'box': 'inventory_2',
  'cart': 'shopping_cart',
  'tag': 'sell',
  'category': 'category',
  'home': 'home',
  'chair': 'chair',
  'tent': 'apartment',
  'lamp': 'lightbulb',
  'speaker': 'volume_up',
  'camera': 'photo_camera',
  'table': 'table_restaurant',
  'mic': 'mic',
  'leaf': 'park',
  'tree': 'park',
  'sun': 'wb_sunny',
  'moon': 'nightlight',
  'crown': 'workspace_premium',
  'diamond': 'diamond',
  'coffee': 'coffee',
  'chocolate': 'cake',
  'perfume': 'water_drop',
  'watch': 'watch',
  'phone': 'smartphone',
  'map': 'location_on',
  'truck': 'local_shipping',
  'handshake': 'groups',
  'building': 'business',
  // Iconsax
  'lovely': 'local_florist',
  'emoji_happy': 'sentiment_satisfied_alt',
  'bag_2': 'shopping_bag',
  'message_text': 'message',
  'note_text': 'sticky_note_2',
  'colorfilter': 'palette',
  'ruler': 'straighten',
  'diamonds': 'diamond',
  'teacher': 'school',
  'user': 'person',
  'star_1': 'star',
  'lamp_on': 'lightbulb',
  'buildings': 'apartment',
  'volume_high': 'volume_up',
  'box_1': 'inventory_2',
  'microphone': 'mic',
  'sun_1': 'wb_sunny',
  'drop': 'water_drop',
  'mobile': 'smartphone',
  'location': 'location_on',
  'people': 'groups',
  // emoji
  '💐': 'local_florist',
  '🌹': 'local_florist',
  '🌷': 'local_florist',
  '🌸': 'local_florist',
  '🎁': 'card_giftcard',
  '🎈': 'celebration',
  '❤️': 'favorite',
  '💍': 'diamond',
  '🎂': 'cake',
  '🎉': 'celebration',
  '📦': 'inventory_2',
  '🛒': 'shopping_cart',
  '🏠': 'home',
  '🪑': 'chair',
};

class CategoryIconMapper {
  CategoryIconMapper._();

  static const String _fontFamily = 'MaterialIcons';

  /// تطبيع أي قيمة مخزّنة إلى اسم Material Icon في Flutter
  static String normalize(String? raw) {
    if (raw == null || raw.isEmpty) return 'category';
    final trimmed = raw.trim();
    final legacy = kLegacyIconToMaterial[trimmed];
    if (legacy != null) return legacy;
    final underscored = trimmed.replaceAll('-', '_');
    if (kMaterialIconCodepoints.containsKey(underscored)) {
      return underscored;
    }
    return 'category';
  }

  static IconData iconData(String? raw, {bool active = false}) {
    final name = normalize(raw);
    if (active) {
      for (final candidate in ['${name}_rounded', '${name}_outlined', name]) {
        final cp = kMaterialIconCodepoints[candidate];
        if (cp != null) {
          return IconData(cp, fontFamily: _fontFamily);
        }
      }
    }
    final cp = kMaterialIconCodepoints[name];
    if (cp != null) {
      return IconData(cp, fontFamily: _fontFamily);
    }
    return active ? Icons.category : Icons.category_outlined;
  }

  static bool isKnown(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    final n = normalize(raw);
    return n != 'category' || raw == 'category' || raw == '📂';
  }
}
