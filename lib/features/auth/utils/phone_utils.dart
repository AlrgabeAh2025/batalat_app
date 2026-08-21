/// Batalat — Libyan phone helpers for auth forms
String normalizeLibyanLocalDigits(String raw) {
  var digits = raw.trim().replaceAll(RegExp(r'[\s\-]'), '');
  if (digits.startsWith('+218')) {
    digits = digits.substring(4);
  } else if (digits.startsWith('218')) {
    digits = digits.substring(3);
  }
  if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return digits;
}

/// Returns E.164 `+2189XXXXXXXX` or null if invalid.
String? toLibyanE164(String raw) {
  final local = normalizeLibyanLocalDigits(raw);
  if (!RegExp(r'^9\d{8}$').hasMatch(local)) return null;
  return '+218$local';
}

String? validateLibyanPhoneInput(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'أدخل رقم الهاتف';
  }
  if (toLibyanE164(value) == null) {
    return 'أدخل رقماً ليبياً صحيحاً (9XXXXXXXX)';
  }
  return null;
}
