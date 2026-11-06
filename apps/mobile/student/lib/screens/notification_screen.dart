import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_toast.dart';

enum NotificationType { transaction, security, promo, system }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime dateTime;
  final NotificationType type;
  final IconData icon;
  final Color iconColor;
  bool isRead;
  final String? actionLabel;
  final String? detail;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.dateTime,
    required this.type,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
    this.actionLabel,
    this.detail,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedFilter = 0; // 0 = Semua, 1 = Transaksi, 2 = Info & Keamanan

  late final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'notif-1',
      title: 'Uang Saku Masuk Rp 1.500.000',
      message: 'Transfer dari Ibu Ratna berhasil diterima di akun Semestapay kamu.',
      dateTime: DateTime.now().subtract(const Duration(minutes: 15)),
      type: NotificationType.transaction,
      icon: Icons.arrow_downward_rounded,
      iconColor: AppColors.accent,
      isRead: false,
      detail: 'Sumber dana: Bank BCA (•••• 9012)\nNominal: Rp 1.500.000\nWaktu: Hari ini, 11:05 WIB\nCatatan: Uang saku & jajan minggu ke-1 November.',
    ),
    NotificationItem(
      id: 'notif-2',
      title: 'Pembayaran Kantin Berhasil',
      message: 'Transaksi Rp 25.000 di Kopi Reyhan & Bakery via Kartu Siswa NFC berhasil.',
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.transaction,
      icon: Icons.storefront_rounded,
      iconColor: AppColors.merchantPrimary,
      isRead: false,
      detail: 'Merchant: Kopi Reyhan & Bakery (Terminal #01)\nNominal: Rp 25.000\nMetode: Kartu RFID / NFC Siswa\nSisa Saldo: Rp 125.000.',
    ),
    NotificationItem(
      id: 'notif-3',
      title: 'Login Baru Terdeteksi',
      message: 'Akun Anda baru saja login pada perangkat baru (Windows Terminal POS).',
      dateTime: DateTime.now().subtract(const Duration(hours: 5)),
      type: NotificationType.security,
      icon: Icons.shield_rounded,
      iconColor: const Color(0xFFE67E22),
      isRead: false,
      detail: 'Perangkat: Windows Chrome / POS App\nLokasi: Jakarta, Indonesia\nWaktu: 04 Nov 2026, 08:30 WIB\nJika ini bukan Anda, segera ubah PIN akun Anda.',
    ),
    NotificationItem(
      id: 'notif-4',
      title: 'Limit Jajan Harian Tercapai 50%',
      message: 'Kamu sudah menggunakan Rp 25.000 dari batas harian Rp 50.000 hari ini.',
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      type: NotificationType.system,
      icon: Icons.speed_rounded,
      iconColor: AppColors.primary,
      isRead: true,
      detail: 'Batas harian: Rp 50.000\nTerpakai: Rp 25.000 (50%)\nSisa kuota jajan hari ini: Rp 25.000.',
    ),
    NotificationItem(
      id: 'notif-5',
      title: 'Cashback 20% Jajan di Kantin Sekolah',
      message: 'Dapatkan cashback koin jajan setiap transaksi di kantin sekolah menggunakan kartu digital.',
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationType.promo,
      icon: Icons.local_offer_rounded,
      iconColor: const Color(0xFFFF6B35),
      isRead: true,
      detail: 'Periode promo: 1 - 30 November 2026\nBerlaku untuk seluruh merchant dan kantin terdaftar di SMAN 1 Jakarta.',
    ),
    NotificationItem(
      id: 'notif-6',
      title: 'Kartu Siswa NFC Telah Aktif',
      message: 'Kartu fisik RFID / NFC kamu siap digunakan untuk bertransaksi tanpa uang tunai.',
      dateTime: DateTime.now().subtract(const Duration(days: 3)),
      type: NotificationType.system,
      icon: Icons.contactless_rounded,
      iconColor: AppColors.accent,
      isRead: true,
      detail: 'Nomor Kartu: •••• •••• •••• 4821\nStatus: Terverifikasi & Aktif\nSekolah: SMAN 1 Jakarta.',
    ),
  ];

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationItem> get _filteredNotifications {
    return _notifications.where((item) {
      if (_selectedFilter == 1 && item.type != NotificationType.transaction) return false;
      if (_selectedFilter == 2 && (item.type == NotificationType.transaction)) return false;
      return true;
    }).toList();
  }

  void _markAllAsRead() {
    if (_unreadCount == 0) {
      AppToast.show(
        context,
        'Semua notifikasi sudah dibaca',
        type: ToastType.info,
      );
      return;
    }

    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });

    AppToast.show(
      context,
      'Semua notifikasi ditandai telah dibaca',
      type: ToastType.success,
    );
  }

  void _onNotificationTap(NotificationItem item) {
    // 1. Otomatis tandai sebagai dibaca saat list di-klik
    if (!item.isRead) {
      setState(() {
        item.isRead = true;
      });
    }

    // 2. Buka detail notifikasi
    _showDetailSheet(item);
  }

  void _showDetailSheet(NotificationItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header notifikasi
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTheme.font(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimeAgo(item.dateTime),
                        style: AppTheme.font(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 14),

            // Isi pesan lengkap
            Text(
              item.message,
              style: AppTheme.font(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),

            // Rincian detail jika ada
            if (item.detail != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  item.detail!,
                  style: AppTheme.font(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Tombol Tutup
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Tutup',
                  style: AppTheme.font(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else {
      return '${diff.inDays} hari lalu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotifications;
    final hasUnread = _unreadCount > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.textPrimary),
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
        actions: [
          // Tombol Tandai dibaca di pojok kanan AppBar
          TextButton(
            onPressed: hasUnread ? _markAllAsRead : null,
            child: Text(
              'Tandai dibaca',
              style: AppTheme.font(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasUnread ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segmented Capsule Filter
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                height: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildFilterTab(0, 'Semua ($_unreadCount Baru)'),
                    _buildFilterTab(1, 'Transaksi'),
                    _buildFilterTab(2, 'Info & Keamanan'),
                  ],
                ),
              ),
            ),

            // List Notifikasi
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildNotificationCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.font(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return Container(
      decoration: BoxDecoration(
        color: item.isRead ? AppColors.surface : const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead ? AppColors.divider : AppColors.primary.withValues(alpha: 0.25),
          width: item.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _onNotificationTap(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Kategori
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Konten Notifikasi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTheme.font(
                              fontSize: 13,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Indikator Belum Dibaca (Dot Biru)
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        fontSize: 12,
                        fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w500,
                        color: item.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimeAgo(item.dateTime),
                      style: AppTheme.font(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_off_rounded, color: AppColors.textLight, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              'Tidak Ada Notifikasi',
              style: AppTheme.font(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Saat ini belum ada pemberitahuan baru untuk akun Semestapay kamu.',
              textAlign: TextAlign.center,
              style: AppTheme.font(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
