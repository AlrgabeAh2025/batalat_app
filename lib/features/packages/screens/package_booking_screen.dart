import 'package:flutter/material.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';

class PackageBookingScreen extends StatelessWidget {
  final String? slug;
  final int? orderId;
  const PackageBookingScreen({super.key, this.slug, this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('PackageBookingScreen', style: AppTextStyles.headlineSmall),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text('Coming Soon...'),
      ),
    );
  }
}

