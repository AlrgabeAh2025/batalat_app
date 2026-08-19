/// Batalat — Category icon catalog (mirrors backend icon_catalog.py)
import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';

class CategoryIconDef {
  final String key;
  final String label;
  final String emoji;
  final IconData icon;
  final IconData? activeIcon;

  const CategoryIconDef({
    required this.key,
    required this.label,
    required this.emoji,
    required this.icon,
    this.activeIcon,
  });
}

const List<CategoryIconDef> kBatalatCategoryIcons = [
  CategoryIconDef(key: 'bouquet', label: 'باقة ورد', emoji: '💐', icon: Iconsax.heart, activeIcon: Iconsax.heart5),
  CategoryIconDef(key: 'flower', label: 'وردة', emoji: '🌹', icon: Iconsax.lovely, activeIcon: Iconsax.lovely5),
  CategoryIconDef(key: 'tulip', label: 'توليب', emoji: '🌷', icon: Iconsax.lovely, activeIcon: Iconsax.lovely5),
  CategoryIconDef(key: 'blossom', label: 'زهرة', emoji: '🌸', icon: Iconsax.lovely, activeIcon: Iconsax.lovely5),
  CategoryIconDef(key: 'gift', label: 'هدية', emoji: '🎁', icon: Iconsax.gift, activeIcon: Iconsax.gift5),
  CategoryIconDef(key: 'balloon', label: 'بالونات', emoji: '🎈', icon: Iconsax.emoji_happy, activeIcon: Iconsax.emoji_happy5),
  CategoryIconDef(key: 'ribbon', label: 'شريطة', emoji: '🎀', icon: Iconsax.gift, activeIcon: Iconsax.gift5),
  CategoryIconDef(key: 'wrapping', label: 'تغليف', emoji: '🛍️', icon: Iconsax.bag_2, activeIcon: Iconsax.bag_25),
  CategoryIconDef(key: 'message', label: 'رسالة', emoji: '💌', icon: Iconsax.message_text, activeIcon: Iconsax.message_text5),
  CategoryIconDef(key: 'note', label: 'ملاحظة', emoji: '📝', icon: Iconsax.note_text, activeIcon: Iconsax.note_text5),
  CategoryIconDef(key: 'card', label: 'بطاقة', emoji: '🃏', icon: Iconsax.card, activeIcon: Iconsax.card5),
  CategoryIconDef(key: 'color', label: 'لون', emoji: '🎨', icon: Iconsax.colorfilter, activeIcon: Iconsax.colorfilter5),
  CategoryIconDef(key: 'size', label: 'مقاس', emoji: '📏', icon: Iconsax.ruler, activeIcon: Iconsax.ruler5),
  CategoryIconDef(key: 'heart', label: 'حب', emoji: '❤️', icon: Iconsax.heart, activeIcon: Iconsax.heart5),
  CategoryIconDef(key: 'ring', label: 'زفاف / خاتم', emoji: '💍', icon: Iconsax.diamonds, activeIcon: Iconsax.diamonds5),
  CategoryIconDef(key: 'cake', label: 'عيد ميلاد', emoji: '🎂', icon: Iconsax.cake, activeIcon: Iconsax.cake5),
  CategoryIconDef(key: 'party', label: 'احتفال', emoji: '🎉', icon: Iconsax.emoji_happy, activeIcon: Iconsax.emoji_happy5),
  CategoryIconDef(key: 'graduation', label: 'تخرج', emoji: '🎓', icon: Iconsax.teacher, activeIcon: Iconsax.teacher5),
  CategoryIconDef(key: 'baby', label: 'مولود', emoji: '👶', icon: Iconsax.user, activeIcon: Iconsax.user5),
  CategoryIconDef(key: 'sparkles', label: 'لمعة', emoji: '✨', icon: Iconsax.star_1, activeIcon: Iconsax.star5),
  CategoryIconDef(key: 'star', label: 'نجمة', emoji: '⭐', icon: Iconsax.star_1, activeIcon: Iconsax.star5),
  CategoryIconDef(key: 'candle', label: 'شمعة', emoji: '🕯️', icon: Iconsax.lamp_on, activeIcon: Iconsax.lamp_on5),
  CategoryIconDef(key: 'shop', label: 'متجر', emoji: '🛍️', icon: Iconsax.shop, activeIcon: Iconsax.shop5),
  CategoryIconDef(key: 'box', label: 'صندوق', emoji: '📦', icon: Iconsax.box, activeIcon: Iconsax.box5),
  CategoryIconDef(key: 'cart', label: 'سلة', emoji: '🛒', icon: Iconsax.shopping_cart, activeIcon: Iconsax.shopping_cart5),
  CategoryIconDef(key: 'tag', label: 'وسم', emoji: '🏷️', icon: Iconsax.tag, activeIcon: Iconsax.tag5),
  CategoryIconDef(key: 'category', label: 'قسم', emoji: '📂', icon: Iconsax.category, activeIcon: Iconsax.category5),
  CategoryIconDef(key: 'home', label: 'رئيسية', emoji: '🏠', icon: Iconsax.home, activeIcon: Iconsax.home_25),
  CategoryIconDef(key: 'chair', label: 'كرسي / معدة', emoji: '🪑', icon: Iconsax.box, activeIcon: Iconsax.box5),
  CategoryIconDef(key: 'tent', label: 'خيمة', emoji: '⛺', icon: Iconsax.buildings, activeIcon: Iconsax.buildings5),
  CategoryIconDef(key: 'lamp', label: 'إضاءة', emoji: '💡', icon: Iconsax.lamp_on, activeIcon: Iconsax.lamp_on5),
  CategoryIconDef(key: 'speaker', label: 'صوت', emoji: '🔊', icon: Iconsax.volume_high, activeIcon: Iconsax.volume_high5),
  CategoryIconDef(key: 'camera', label: 'تصوير', emoji: '📷', icon: Iconsax.camera, activeIcon: Iconsax.camera5),
  CategoryIconDef(key: 'table', label: 'طاولة', emoji: '🪵', icon: Iconsax.box_1, activeIcon: Iconsax.box_15),
  CategoryIconDef(key: 'mic', label: 'مايك', emoji: '🎤', icon: Iconsax.microphone, activeIcon: Iconsax.microphone5),
  CategoryIconDef(key: 'leaf', label: 'ورقة', emoji: '🍃', icon: Iconsax.lovely, activeIcon: Iconsax.lovely5),
  CategoryIconDef(key: 'tree', label: 'شجرة', emoji: '🌳', icon: Iconsax.lovely, activeIcon: Iconsax.lovely5),
  CategoryIconDef(key: 'sun', label: 'شمس', emoji: '☀️', icon: Iconsax.sun_1, activeIcon: Iconsax.sun_15),
  CategoryIconDef(key: 'moon', label: 'قمر', emoji: '🌙', icon: Iconsax.moon, activeIcon: Iconsax.moon5),
  CategoryIconDef(key: 'crown', label: 'تاج', emoji: '👑', icon: Iconsax.crown, activeIcon: Iconsax.crown5),
  CategoryIconDef(key: 'diamond', label: 'ماسة', emoji: '💎', icon: Iconsax.diamonds, activeIcon: Iconsax.diamonds5),
  CategoryIconDef(key: 'coffee', label: 'قهوة', emoji: '☕', icon: Iconsax.coffee, activeIcon: Iconsax.coffee5),
  CategoryIconDef(key: 'chocolate', label: 'شوكولاتة', emoji: '🍫', icon: Iconsax.cake, activeIcon: Iconsax.cake5),
  CategoryIconDef(key: 'perfume', label: 'عطر', emoji: '🧴', icon: Iconsax.drop, activeIcon: Iconsax.drop3),
  CategoryIconDef(key: 'watch', label: 'ساعة', emoji: '⌚', icon: Iconsax.watch, activeIcon: Iconsax.watch5),
  CategoryIconDef(key: 'phone', label: 'هاتف', emoji: '📱', icon: Iconsax.mobile, activeIcon: Iconsax.mobile5),
  CategoryIconDef(key: 'map', label: 'خريطة', emoji: '🗺️', icon: Iconsax.location, activeIcon: Iconsax.location5),
  CategoryIconDef(key: 'truck', label: 'توصيل', emoji: '🚚', icon: Iconsax.truck, activeIcon: Iconsax.truck4),
  CategoryIconDef(key: 'handshake', label: 'شركات', emoji: '🤝', icon: Iconsax.people, activeIcon: Iconsax.people5),
  CategoryIconDef(key: 'building', label: 'مبنى', emoji: '🏢', icon: Iconsax.building, activeIcon: Iconsax.building5),
];

final Map<String, CategoryIconDef> _byKey = {
  for (final i in kBatalatCategoryIcons) i.key: i,
};

final Map<String, String> _emojiToKey = {
  for (final i in kBatalatCategoryIcons) i.emoji: i.key,
  '🌹': 'flower',
  '🎁': 'gift',
  '🪑': 'chair',
  '💐': 'bouquet',
};

class CategoryIconMapper {
  CategoryIconMapper._();

  static CategoryIconDef? defFor(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (_byKey.containsKey(raw)) return _byKey[raw];
    final key = _emojiToKey[raw];
    if (key != null) return _byKey[key];
    return null;
  }

  static IconData iconData(String? raw, {bool active = false}) {
    final d = defFor(raw);
    if (d == null) return active ? Iconsax.category5 : Iconsax.category;
    if (active && d.activeIcon != null) return d.activeIcon!;
    return d.icon;
  }

  static String emoji(String? raw) {
    final d = defFor(raw);
    if (d != null) return d.emoji;
    if (raw != null && raw.isNotEmpty && raw.length <= 4) return raw;
    return '📦';
  }

  static bool isCatalogKey(String? raw) =>
      raw != null && _byKey.containsKey(raw);
}
