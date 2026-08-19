/// Batalat App — Color Palette
/// مستوحاة من هوية لوغو Batalat
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // =============================================
  // Primary — Crimson Red (لون الورد الرئيسي)
  // =============================================
  static const Color primary        = Color(0xFF8B1A1A);
  static const Color primaryLight   = Color(0xFFC94040);
  static const Color primaryDark    = Color(0xFF5C0E0E);
  static const Color primarySurface = Color(0xFFFCEEEE);

  // =============================================
  // Background — Cream Ivory (خلفية اللوغو)
  // =============================================
  static const Color background     = Color(0xFFFAF5F0);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceWarm    = Color(0xFFF5EDE8);
  static const Color cardBg         = Color(0xFFFFFFFF);

  // =============================================
  // Text Colors
  // =============================================
  static const Color textPrimary    = Color(0xFF2C1A1A);
  static const Color textSecondary  = Color(0xFF6B4040);
  static const Color textHint       = Color(0xFFA07070);
  static const Color textLight      = Color(0xFFBFA090);
  static const Color textOnPrimary  = Color(0xFFFFFFFF);

  // =============================================
  // Semantic Colors
  // =============================================
  static const Color success        = Color(0xFF2D7A4F);
  static const Color successLight   = Color(0xFFE8F5EE);
  static const Color warning        = Color(0xFFB8730A);
  static const Color warningLight   = Color(0xFFFFF4E0);
  static const Color error          = Color(0xFF8B1A1A);
  static const Color errorLight     = Color(0xFFFCEEEE);
  static const Color info           = Color(0xFF1A4F8B);
  static const Color infoLight      = Color(0xFFEEF4FC);

  // =============================================
  // Border & Divider
  // =============================================
  static const Color border         = Color(0xFFE8D8D0);
  static const Color borderLight    = Color(0xFFF0E8E4);
  static const Color divider        = Color(0xFFF0E4DF);

  // =============================================
  // Status Badge Colors
  // =============================================
  static const Color statusPending  = Color(0xFFB8730A);
  static const Color statusConfirmed= Color(0xFF1A4F8B);
  static const Color statusPreparing= Color(0xFF6B2D8B);
  static const Color statusDelivered= Color(0xFF2D7A4F);
  static const Color statusCancelled= Color(0xFF8B1A1A);

  // =============================================
  // Gradient Presets
  // =============================================
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFFF0E8E2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFAF5F0), Color(0xFFF5EDE8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAF5F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
