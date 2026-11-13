import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaBalanceCard — kartu saldo dompet yang dipakai bersama oleh
/// aplikasi Santri, Merchant, dan Kiosk.
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaBalanceCard extends StatelessWidget {
  final double balance;
  final String label;
  final String? ownerName;
  final String? subtitle;
  final String currencyPrefix;
  final Gradient? gradient;
  final Widget? action;
  final VoidCallback? onTap;

  const SemestaBalanceCard({
    super.key,
    required this.balance,
    this.label = 'Saldo Dompet',
    this.ownerName,
    this.subtitle,
    this.currencyPrefix = 'Rp ',
    this.gradient,
    this.action,
    this.onTap,
  });

  String get _formatted {
    final raw = balance.round().abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write('.');
      buffer.write(raw[i]);
    }
    final sign = balance < 0 ? '-' : '';
    return '$sign$currencyPrefix$buffer';
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient ??
            const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTheme.font(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    if (ownerName != null)
                      Text(
                        ownerName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _formatted,
            style: AppTheme.font(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTheme.font(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}
