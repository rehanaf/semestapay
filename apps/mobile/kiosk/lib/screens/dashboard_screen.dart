import 'dart:async';

import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import '../config/kiosk_config.dart';
import '../state/kiosk_state.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'transfer_screen.dart';

class KioskDashboardScreen extends StatefulWidget {
  final KioskState state;

  const KioskDashboardScreen({super.key, required this.state});

  @override
  State<KioskDashboardScreen> createState() => _KioskDashboardScreenState();
}

class _KioskDashboardScreenState extends State<KioskDashboardScreen> {
  Timer? _idleTimer;
  int _secondsLeft = KioskConfig.idleTimeout.inSeconds;

  @override
  void initState() {
    super.initState();
    _startIdleTimer();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _secondsLeft = KioskConfig.idleTimeout.inSeconds;
    _idleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        timer.cancel();
        widget.state.logoutStudent();
      }
    });
  }

  void _resetIdle() {
    if (_secondsLeft <= 0) return;
    setState(() => _secondsLeft = KioskConfig.idleTimeout.inSeconds);
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  Future<void> _openHistory() async {
    _resetIdle();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KioskHistoryScreen(state: widget.state),
      ),
    );
    _resetIdle();
    await widget.state.refresh();
  }

  Future<void> _openTransfer() async {
    _resetIdle();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KioskTransferScreen(state: widget.state),
      ),
    );
    _resetIdle();
    await widget.state.refresh();
  }

  Future<void> _openProfile() async {
    _resetIdle();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KioskProfileScreen(state: widget.state),
      ),
    );
    _resetIdle();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final student = state.student;
    final dashboard = state.dashboard;
    final recent = state.mutations.take(5).toList();

    return Listener(
      onPointerDown: (_) => _resetIdle(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              _resetIdle();
              await state.refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Row(
                  children: [
                    SemestaAvatar(name: student?.name, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${student?.name ?? "Santri"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.font(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            student?.className ?? 'Santri',
                            style: AppTheme.font(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SemestaBadge(
                      label: '${_secondsLeft}s',
                      icon: Icons.timer_outlined,
                      color: _secondsLeft <= 10
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    SemestaIconButton(
                      icon: Icons.logout_rounded,
                      onTap: () => state.logoutStudent(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SemestaBalanceCard(
                  balance: state.balance,
                  ownerName: student?.name,
                  subtitle: 'Kartu ${student?.cardUid ?? "-"}',
                  action: IconButton(
                    tooltip: 'Muat ulang',
                    onPressed: () {
                      _resetIdle();
                      state.refresh();
                    },
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SemestaCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.speed_rounded,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Limit harian',
                          style: AppTheme.font(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${state.formatCurrency(dashboard?.dailyUsed ?? 0)} / '
                        '${state.formatCurrency(student?.dailyLimit ?? 0)}',
                        style: AppTheme.font(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SemestaSectionHeader(title: 'Akses Cepat'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Transfer',
                      color: AppColors.success,
                      onTap: _openTransfer,
                    ),
                    const SizedBox(width: 8),
                    _QuickAction(
                      icon: Icons.receipt_long_rounded,
                      label: 'Riwayat',
                      color: AppColors.primary,
                      onTap: _openHistory,
                    ),
                    const SizedBox(width: 8),
                    _QuickAction(
                      icon: Icons.person_rounded,
                      label: 'Profil',
                      color: AppColors.accent,
                      onTap: _openProfile,
                    ),
                    const SizedBox(width: 8),
                    _QuickAction(
                      icon: Icons.sync_rounded,
                      label: 'Refresh',
                      color: AppColors.warning,
                      onTap: () {
                        _resetIdle();
                        state.refresh();
                      },
                    ),
                    const SizedBox(width: 8),
                    _QuickAction(
                      icon: Icons.logout_rounded,
                      label: 'Keluar',
                      color: AppColors.error,
                      onTap: () => state.logoutStudent(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SemestaSectionHeader(
                  title: 'Transaksi Terakhir',
                  actionLabel: 'Lihat semua',
                  onAction: _openHistory,
                ),
                const SizedBox(height: 8),
                if (recent.isEmpty)
                  const SemestaEmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'Belum ada transaksi',
                    subtitle: 'Riwayat belanja dan top up akan muncul di sini.',
                  )
                else
                  ...recent.map(
                    (m) => SemestaHistoryTile(
                      title: m.merchant ?? m.outlet ?? _typeLabel(m.type),
                      subtitle: state.formatDate(m.createdAt),
                      amount: m.amount,
                      isCredit: m.isCredit,
                      status: m.status,
                      onTap: _openHistory,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'payment':
        return 'Pembayaran';
      case 'topup':
        return 'Top Up Saldo';
      case 'transfer_in':
        return 'Transfer Masuk';
      case 'transfer_out':
        return 'Transfer Keluar';
      case 'adjustment':
        return 'Penyesuaian Saldo';
      default:
        return type.replaceAll('_', ' ');
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SemestaCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.font(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
