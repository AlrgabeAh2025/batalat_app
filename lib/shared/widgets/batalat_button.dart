/// Batalat — Reusable Button Widget
import 'package:flutter/material.dart';
import 'package:batalat_app/core/theme/app_colors.dart';
import 'package:batalat_app/core/theme/app_text_styles.dart';
import 'package:batalat_app/core/constants/app_constants.dart';

enum BatalatButtonStyle { primary, outline, text, danger }

class BatalatButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final BatalatButtonStyle style;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? prefix;
  final double height;

  const BatalatButton({
    super.key,
    required this.label,
    this.onTap,
    this.style = BatalatButtonStyle.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.prefix,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (style) {
      case BatalatButtonStyle.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onTap,
          child: _buildContent(Colors.white),
        );
      case BatalatButtonStyle.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onTap,
          child: _buildContent(AppColors.primary),
        );
      case BatalatButtonStyle.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: _buildContent(Colors.white),
        );
      case BatalatButtonStyle.text:
        return TextButton(
          onPressed: isLoading ? null : onTap,
          child: _buildContent(AppColors.primary),
        );
    }
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 22, height: 22,
        child: CircularProgressIndicator(color: color, strokeWidth: 2),
      );
    }
    if (prefix != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [prefix!, const SizedBox(width: 8), Text(label)],
      );
    }
    return Text(label);
  }
}

