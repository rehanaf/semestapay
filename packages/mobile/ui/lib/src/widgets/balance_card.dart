import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SemestaBalanceAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const SemestaBalanceAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

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
  final bool balanceVisible;
  final VoidCallback? onToggleBalanceVisibility;
  final VoidCallback? onDetailsTap;
  final List<SemestaBalanceAction> actions;

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
    this.balanceVisible = true,
    this.onToggleBalanceVisibility,
    this.onDetailsTap,
    this.actions = const [],
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
              if (onDetailsTap != null)
                IconButton(
                  tooltip: 'Lihat detail',
                  onPressed: onDetailsTap,
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                  ),
                )
              else if (action != null)
                action!,
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    balanceVisible ? _formatted : 'Rp ••••••••',
                    key: ValueKey(balanceVisible),
                    style: AppTheme.font(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (onToggleBalanceVisibility != null)
                IconButton(
                  tooltip:
                      balanceVisible ? 'Sembunyikan saldo' : 'Tampilkan saldo',
                  onPressed: onToggleBalanceVisibility,
                  icon: Icon(
                    balanceVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
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
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(child: _BalanceActionButton(action: actions[index])),
                ],
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

class _BalanceActionButton extends StatelessWidget {
  final SemestaBalanceAction action;

  const _BalanceActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: Colors.white, size: 17),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
