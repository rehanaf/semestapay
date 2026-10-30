library semestapay_mobile_ui;

import 'package:flutter/material.dart';

class SemestaColors {
  // Brand colors
  static const Color primaryAdmin = Color(0xFF4F46E5);    // Indigo
  static const Color primarySchool = Color(0xFF10B981);   // Emerald
  static const Color primaryMerchant = Color(0xFFF59E0B); // Amber
  static const Color primaryStudent = Color(0xFF0EA5E9);  // Sky Blue
  static const Color primaryParent = Color(0xFF8B5CF6);   // Purple
}

class SemestaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const SemestaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
