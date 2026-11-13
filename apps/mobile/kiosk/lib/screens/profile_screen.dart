import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import '../state/kiosk_state.dart';

class KioskProfileScreen extends StatelessWidget {
  final KioskState state;

  const KioskProfileScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final student = state.student;
    final dashboard = state.dashboard;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Santri'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SemestaCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SemestaAvatar(name: student?.name, size: 72),
                const SizedBox(height: 12),
                Text(
                  student?.name ?? 'Santri',
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student?.nis ?? "-"} • ${student?.className ?? "Santri"}',
                  style: AppTheme.font(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                SemestaBalanceCard(
                  balance: state.balance,
                  label: 'Saldo Dompet',
                  subtitle: 'Status kartu: ${student?.cardStatus ?? "-"}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SemestaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ProfileRow(
                  icon: Icons.school_rounded,
                  label: 'Sekolah',
                  value: dashboard?.school.name ?? '-',
                ),
                _ProfileRow(
                  icon: Icons.badge_rounded,
                  label: 'NIS',
                  value: student?.nis ?? '-',
                ),
                _ProfileRow(
                  icon: Icons.class_rounded,
                  label: 'Kelas',
                  value: student?.className ?? '-',
                ),
                _ProfileRow(
                  icon: Icons.credit_card_rounded,
                  label: 'Kartu RFID',
                  value: student?.cardUid ?? '-',
                ),
                _ProfileRow(
                  icon: Icons.speed_rounded,
                  label: 'Limit Harian',
                  value: state.formatCurrency(student?.dailyLimit ?? 0),
                ),
                _ProfileRow(
                  icon: Icons.today_rounded,
                  label: 'Terpakai Hari Ini',
                  value: state.formatCurrency(dashboard?.dailyUsed ?? 0),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SemestaOutlineButton(
            label: 'Keluar Sesi Kiosk',
            icon: Icons.logout_rounded,
            color: AppColors.error,
            onPressed: () async {
              Navigator.of(context).pop();
              await state.logoutStudent();
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.font(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
      ],
    );
  }
}
