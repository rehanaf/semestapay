import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import '../state/pos_state.dart';

class MerchantNotificationScreen extends StatelessWidget {
  final PosState posState;

  const MerchantNotificationScreen({super.key, required this.posState});

  @override
  Widget build(BuildContext context) {
    final notifications = _demoNotifications();

    return Scaffold(
      backgroundColor: AppColors.merchantBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              size: 28, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: AppTheme.font(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: notifications.isEmpty
          ? const Center(
              child: SemestaEmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Tidak ada notifikasi',
                subtitle: 'Semua notifikasi akan muncul di sini.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
                color: AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _NotificationTile(data: notif);
              },
            ),
    );
  }

  List<_NotifData> _demoNotifications() {
    return [
      _NotifData(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.merchantPrimary,
        title: 'Transaksi Berhasil',
        body: 'Transaksi Kas Masuk sebesar Rp 25.000 dari Ahmad Fauzi berhasil.',
        time: '2 mnt lalu',
        isRead: false,
      ),
      _NotifData(
        icon: Icons.payments_outlined,
        iconColor: const Color(0xFFE65100),
        title: 'Kas Keluar Diproses',
        body: 'Kas keluar Rp 50.000 untuk Siti Rahayu berhasil diproses.',
        time: '15 mnt lalu',
        isRead: false,
      ),
      _NotifData(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFF1E88E5),
        title: 'Saldo Diperbarui',
        body: 'Saldo merchant Anda telah diperbarui menjadi Rp 1.250.000.',
        time: '1 jam lalu',
        isRead: true,
      ),
      _NotifData(
        icon: Icons.campaign_rounded,
        iconColor: const Color(0xFFD97706),
        title: 'Informasi Sistem',
        body: 'Pemeliharaan sistem dijadwalkan pada pukul 23:00 – 23:30 WIB.',
        time: '3 jam lalu',
        isRead: true,
      ),
      _NotifData(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.merchantPrimary,
        title: 'Transaksi Berhasil',
        body: 'Transaksi Kas Masuk sebesar Rp 12.000 dari Budi Santoso berhasil.',
        time: 'Kemarin',
        isRead: true,
      ),
    ];
  }
}

class _NotifData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String time;
  final bool isRead;

  const _NotifData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });
}

class _NotificationTile extends StatelessWidget {
  final _NotifData data;

  const _NotificationTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.title,
                        style: AppTheme.font(
                          fontSize: 14,
                          fontWeight: data.isRead
                              ? FontWeight.w600
                              : FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data.time,
                      style: AppTheme.font(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data.body,
                  style: AppTheme.font(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (!data.isRead) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.merchantPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
