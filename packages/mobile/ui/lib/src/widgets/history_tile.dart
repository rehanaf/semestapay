import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaHistoryTile — baris riwayat transaksi yang dipakai bersama oleh
/// aplikasi Santri, Merchant, dan Kiosk.
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaHistoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
  final String? status;
  final IconData? icon;
  final VoidCallback? onTap;

  const SemestaHistoryTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.isCredit = false,
    this.status,
    this.icon,
    this.onTap,
  });

  String get _formatted {
    final raw = amount.round().abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('.');
      buffer.write(raw[i]);
    }
    return 'Rp $buffer';
  }

  bool get _isSuccess => status == null || status == 'success' || status == 'paid';

  @override
  Widget build(BuildContext context) {
    final color = isCredit ? AppColors.success : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (isCredit ? AppColors.success : AppColors.primary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon ??
                    (isCredit
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded),
                size: 20,
                color: isCredit ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'} $_formatted',
                  style: AppTheme.font(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isSuccess ? 'Berhasil' : 'Gagal',
                  style: AppTheme.font(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _isSuccess ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
