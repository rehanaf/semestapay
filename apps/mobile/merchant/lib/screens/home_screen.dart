import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import '../state/pos_state.dart';
import 'merchant_history_screen.dart';
import 'merchant_notification_screen.dart';
import 'merchant_success_screen.dart';
import 'merchant_tap_card_screen.dart' show StudentCardData;
import 'merchant_transaction_screen.dart';

class MerchantHomeScreen extends StatefulWidget {
  final PosState posState;
  const MerchantHomeScreen({super.key, required this.posState});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.posState.addListener(_onStateChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.posState.refreshMerchantSummary().catchError((_) {});
      widget.posState.refreshUserProfile().catchError((_) {});
    });
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.posState.removeListener(_onStateChange);
    super.dispose();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: Text(
          'Keluar dari Merchant',
          style: AppTheme.font(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Apakah Anda ingin keluar dari akun Semestapay Merchant?',
          style: AppTheme.font(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: AppTheme.font(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
              minimumSize: const Size(90, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.posState.logout();
            },
            child: Text(
              'Keluar',
              style: AppTheme.font(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_currentIndex != 0) {
      const titles = ['Beranda', 'Riwayat', 'Laporan', 'Pengaturan'];
      return AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.textPrimary),
          onPressed: () => setState(() => _currentIndex = 0),
        ),
        title: Text(
          titles[_currentIndex],
          style: AppTheme.font(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [
          SizedBox(width: 48),
        ],
      );
    }

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      toolbarHeight: 70,
      title: Row(
        children: [
          // Avatar Toko Lingkaran Hijau
          GestureDetector(
            onTap: () => setState(() => _currentIndex = 3),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.merchantPrimary, Color(0xFF00C896)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.merchantPrimary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: widget.posState.currentUser?.avatarUrl != null &&
                      widget.posState.currentUser!.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.posState.currentUser!.avatarUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    )
                  : const Icon(Icons.storefront_rounded,
                      color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          // Nama Toko & MID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.posState.merchantSummary?.name ??
                            widget.posState.outletName,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.merchantLightGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Buka',
                        style: AppTheme.font(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.merchantPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Outlet: ${widget.posState.outletName} • ${widget.posState.outletCode}',
                  style: AppTheme.font(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _MerchantAppBarButton(
          icon: Icons.notifications_none_rounded,
          badge: 2,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MerchantNotificationScreen(
                    posState: widget.posState),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  void _openNewTransactionSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantTransactionScreen(posState: widget.posState),
      ),
    ).then((_) {
      widget.posState.refreshMerchantSummary().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.merchantBackground,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _MerchantHomePage(posState: widget.posState),
          _MerchantHistoryPage(posState: widget.posState),
          _MerchantReportsPage(posState: widget.posState),
          _MerchantSettingsPage(
            posState: widget.posState,
            onLogout: _showLogoutDialog,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Navigation bar background
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MerchantNavItem(
                            icon: Icons.storefront_rounded,
                            label: 'Beranda',
                            isActive: _currentIndex == 0,
                            onTap: () => setState(() => _currentIndex = 0),
                          ),
                          _MerchantNavItem(
                            icon: Icons.history_rounded,
                            label: 'Riwayat',
                            isActive: _currentIndex == 1,
                            onTap: () => setState(() => _currentIndex = 1),
                          ),
                        ],
                      ),
                    ),
                    // Ruang tengah untuk tombol TRANSAKSI timbul
                    const SizedBox(width: 76),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MerchantNavItem(
                            icon: Icons.bar_chart_rounded,
                            label: 'Laporan',
                            isActive: _currentIndex == 2,
                            onTap: () => setState(() => _currentIndex = 2),
                          ),
                          _MerchantNavItem(
                            icon: Icons.store_mall_directory_outlined,
                            label: 'Toko',
                            isActive: _currentIndex == 3,
                            onTap: () => setState(() => _currentIndex = 3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tombol TRANSAKSI Timbul Bentuk SQUIRCLE HIJAU
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: _openNewTransactionSheet,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20), // SQUIRCLE SHAPE
                          gradient: const LinearGradient(
                            colors: [AppColors.merchantPrimary, Color(0xFF00875A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.merchantPrimary.withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_card_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Transaksi',
                        style: AppTheme.font(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.merchantPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
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

// ─── MERCHANT HOME PAGE ─────────────────────────────────────────────────────

class _MerchantHomePage extends StatefulWidget {
  final PosState posState;
  const _MerchantHomePage({required this.posState});

  @override
  State<_MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<_MerchantHomePage> {
  bool _balanceVisible = true;
  List<TransactionRecord> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    try {
      final list = await widget.posState.api.getTransactions();
      if (mounted) setState(() => _recent = list.take(4).toList());
    } catch (_) {
      // offline fallback: keep empty
    }
  }

  void _openNewTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantTransactionScreen(posState: widget.posState),
      ),
    ).then((_) {
      widget.posState.refreshMerchantSummary().catchError((_) {});
      _loadRecent();
    });
  }

  void _openCashOut() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantTransactionScreen(
          posState: widget.posState,
          isCashOut: true,
        ),
      ),
    ).then((_) {
      widget.posState.refreshMerchantSummary().catchError((_) {});
      _loadRecent();
    });
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantHistoryScreen(posState: widget.posState),
      ),
    ).then((_) {
      widget.posState.refreshMerchantSummary().catchError((_) {});
      _loadRecent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildBalanceCard()),
        SliverToBoxAdapter(child: _buildTodayStats()),
        SliverToBoxAdapter(child: _buildRecentTransactions()),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF00A86B), Color(0xFF006C44)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.merchantPrimary.withValues(alpha: 0.38),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -50,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Saldo Merchant + Eye icon + Spacer + Chevron icon di pojok kanan
                  Row(
                    children: [
                      Text(
                        'Saldo Siap Tarik',
                        style: AppTheme.font(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _balanceVisible = !_balanceVisible),
                        child: Icon(
                          _balanceVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 18,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openHistory,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _balanceVisible
                        ? Text(
                            widget.posState.formatCurrency(
                              widget.posState.merchantSummary?.balance ?? 0,
                            ),
                            key: const ValueKey('visible_merchant'),
                            style: AppTheme.font(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          )
                        : Text(
                            'Rp ••••••••',
                            key: const ValueKey('hidden_merchant'),
                            style: AppTheme.font(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                  const SizedBox(height: 18),
                  // 3 Aksi Merchant Sesuai Request: Kas Masuk, Kas Keluar, Riwayat
                  Row(
                    children: [
                      Expanded(
                        child: _MerchantActionButton(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Kas Masuk',
                          onTap: _openNewTransaction,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MerchantActionButton(
                          icon: Icons.payments_outlined,
                          label: 'Kas Keluar',
                          onTap: _openCashOut,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MerchantActionButton(
                          icon: Icons.history_rounded,
                          label: 'Riwayat',
                          onTap: _openHistory,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStats() {
    final summary = widget.posState.merchantSummary;
    final todayIncome = summary?.todayIncome ?? 0;
    final todayCashOut = 0; // field not yet available in API
    final txCount = summary?.transactionCount ?? 0;
    final totalRp = todayIncome + todayCashOut;

    String formatRupiah(num v) {
      final s = v.round().toString();
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
        buf.write(s[i]);
      }
      return 'Rp ${buf.toString()}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Hari Ini',
            style: AppTheme.font(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppColors.merchantPrimary,
                  label: 'Total Transaksi',
                  value: formatRupiah(totalRp),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.tag_rounded,
                  iconColor: const Color(0xFF1E88E5),
                  label: 'Jumlah Transaksi',
                  value: '$txCount Trx',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF00A86B),
                  label: 'Pemasukan',
                  value: formatRupiah(todayIncome),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_down_rounded,
                  iconColor: AppColors.error,
                  label: 'Pengeluaran',
                  value: formatRupiah(todayCashOut),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.font(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.font(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildShortcuts() {
    final shortcuts = [
      _MerchantShortcutData(Icons.point_of_sale_rounded, 'Kasir POS', AppColors.merchantPrimary),
      _MerchantShortcutData(Icons.qr_code_2_rounded, 'QRIS Statis', const Color(0xFF0284C7)),
      _MerchantShortcutData(Icons.account_balance_rounded, 'Tarik Dana', const Color(0xFFE11D48)),
      _MerchantShortcutData(Icons.inventory_2_outlined, 'Produk', const Color(0xFFD97706)),
      _MerchantShortcutData(Icons.bar_chart_rounded, 'Laporan', const Color(0xFF7C3AED)),
      _MerchantShortcutData(Icons.badge_outlined, 'Pegawai', const Color(0xFF059669)),
      _MerchantShortcutData(Icons.discount_outlined, 'Promo Toko', const Color(0xFFEA580C)),
      _MerchantShortcutData(Icons.more_horiz_rounded, 'Lainnya', AppColors.textSecondary),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Fitur Bisnis Merchant',
                  style: AppTheme.font(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Semua',
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.merchantPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Grid kebawah 4 kolom
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shortcuts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                return _MerchantShortcutItem(data: shortcuts[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPromoSection() {
    final promos = [
      _MerchantPromoCardData(
        color: AppColors.merchantPrimary,
        title: 'MDR 0% Transaksi QRIS',
        subtitle: 'Bebas potongan transaksi QRIS khusus usaha mikro s/d akhir tahun.',
        icon: Icons.qr_code_scanner_rounded,
        tag: 'Promo UMKM',
      ),
      _MerchantPromoCardData(
        color: const Color(0xFF0284C7),
        title: 'Modal Usaha s/d 100 Juta',
        subtitle: 'Ajukan pembiayaan usaha instan dengan bunga ringan khusus merchant aktif.',
        icon: Icons.savings_outlined,
        tag: 'Finansial',
      ),
      _MerchantPromoCardData(
        color: const Color(0xFFEA580C),
        title: 'Cetak Struk Bluetooth',
        subtitle: 'Hubungkan printer thermal kasir langsung dari aplikasi ReyPay Merchant.',
        icon: Icons.print_rounded,
        tag: 'Fitur Baru',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Info & Keuntungan Merchant',
                style: AppTheme.font(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Lihat semua',
                style: AppTheme.font(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.merchantPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // List menurun ke bawah
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: promos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (_, index) => _MerchantPromoVerticalCard(data: promos[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final transactions = _recent.map((tx) {
      final isCashOut = tx.type.toLowerCase().contains('cash_out');
      final time = DateTime.tryParse(tx.createdAt)?.toLocal();
      final diff = time == null ? null : DateTime.now().difference(time);
      final timeLabel = diff == null
          ? '-'
          : diff.inMinutes < 60
              ? '${diff.inMinutes} menit lalu'
              : diff.inHours < 24
                  ? '${diff.inHours} jam lalu'
                  : '${time!.day}/${time.month}/${time.year}';
      final prefix = isCashOut ? '-' : '+';
      return _MerchantTxData(
        tx.studentName ?? 'Pelanggan',
        isCashOut ? 'Kas Keluar' : 'Kas Masuk',
        '$prefix${widget.posState.formatCurrency(tx.amount)}',
        timeLabel,
        tx.invoiceNumber,
        isCashOut: isCashOut,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Text(
                'Transaksi Terbaru',
                style: AppTheme.font(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _openHistory,
                child: Text(
                  'Lihat semua',
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.merchantPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: transactions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: SemestaEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum ada transaksi hari ini',
                    subtitle: 'Transaksi akan tampil di sini.',
                  ),
                )
              : Column(
            children: List.generate(transactions.length, (i) {
              return Column(
                children: [
                  _MerchantTransactionTile(data: transactions[i]),
                  if (i < transactions.length - 1)
                    const Divider(
                      height: 1,
                      indent: 72,
                      endIndent: 20,
                      color: AppColors.divider,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─── REUSABLE MERCHANT WIDGETS ──────────────────────────────────────────────

class _MerchantAppBarButton extends StatelessWidget {
  final IconData icon;
  final int? badge;
  final VoidCallback onTap;

  const _MerchantAppBarButton({
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
          if (badge != null)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badge',
                  style: AppTheme.font(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MerchantActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MerchantActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
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
    );
  }
}

class _MerchantShortcutData {
  final IconData icon;
  final String label;
  final Color color;

  const _MerchantShortcutData(this.icon, this.label, this.color);
}

class _MerchantShortcutItem extends StatelessWidget {
  final _MerchantShortcutData data;

  const _MerchantShortcutItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Squircle icon shape
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16), // SQUIRCLE
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            data.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.font(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantPromoCardData {
  final Color color;
  final String title;
  final String subtitle;
  final IconData icon;
  final String tag;

  const _MerchantPromoCardData({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tag,
  });
}

class _MerchantPromoVerticalCard extends StatelessWidget {
  final _MerchantPromoCardData data;

  const _MerchantPromoVerticalCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.tag,
                        style: AppTheme.font(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: data.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textLight,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _MerchantTxData {
  final String title;
  final String status;
  final String amount;
  final String time;
  final String method;
  final bool isCashOut;

  const _MerchantTxData(
    this.title,
    this.status,
    this.amount,
    this.time,
    this.method, {
    this.isCashOut = false,
  });
}

class _MerchantTransactionTile extends StatelessWidget {
  final _MerchantTxData data;

  const _MerchantTransactionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.isCashOut
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.merchantLightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              data.isCashOut
                  ? Icons.payments_outlined
                  : Icons.person_rounded,
              color: data.isCashOut
                  ? AppColors.error
                  : AppColors.merchantPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: AppTheme.font(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      data.status,
                      style: AppTheme.font(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: data.isCashOut
                            ? AppColors.error
                            : AppColors.merchantPrimary,
                      ),
                    ),
                    Text(
                      ' • ${data.time}',
                      style: AppTheme.font(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            data.amount,
            style: AppTheme.font(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: data.isCashOut
                  ? AppColors.error
                  : AppColors.merchantPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _MerchantNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.merchantPrimary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? AppColors.merchantPrimary : AppColors.textLight,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.font(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.merchantPrimary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MODALS: TRANSAKSI BARU, TARIK DANA, RIWAYAT ─────────────────────────────

class _NewTransactionModal extends StatefulWidget {
  const _NewTransactionModal();

  @override
  State<_NewTransactionModal> createState() => _NewTransactionModalState();
}

class _NewTransactionModalState extends State<_NewTransactionModal> {
  final _amountController = TextEditingController(text: '50.000');
  bool _isGenerated = false;

  final List<String> _quickAmounts = ['15.000', '25.000', '50.000', '100.000'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.merchantLightGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_task_rounded,
                      color: AppColors.merchantPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Buat Tagihan QRIS Baru',
                    style: AppTheme.font(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (!_isGenerated) ...[
                // Input Nominal
                Text(
                  'Masukkan Nominal Pembayaran',
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.merchantBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.merchantPrimary, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Rp',
                        style: AppTheme.font(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.merchantPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: AppTheme.font(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Tombol Cepat
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _quickAmounts.map((amt) {
                    return GestureDetector(
                      onTap: () => setState(() => _amountController.text = amt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.merchantLightGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          amt,
                          style: AppTheme.font(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.merchantPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.merchantPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => setState(() => _isGenerated = true),
                    child: Text(
                      'Tampilkan QRIS Pelanggan',
                      style: AppTheme.font(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Tampilan QRIS yang Digenerate
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total: Rp ${_amountController.text}',
                        style: AppTheme.font(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.merchantPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scan dengan GoPay, OVO, Dana, BCA, Livin, dll',
                        style: AppTheme.font(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          size: 170,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Berlaku selama 04:59',
                            style: AppTheme.font(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.merchantPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pembayaran QRIS Berhasil Diterima! +Rp 50.000'),
                          backgroundColor: AppColors.merchantPrimary,
                        ),
                      );
                    },
                    child: Text(
                      'Simulasi Pembayaran Berhasil',
                      style: AppTheme.font(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _WithdrawModal extends StatelessWidget {
  final PosState posState;
  const _WithdrawModal({required this.posState});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Tarik Tunai / Settlement',
                style: AppTheme.font(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tarik dana pendapatan merchant langsung ke rekening bank utama.',
                style: AppTheme.font(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.merchantLightGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_rounded, color: AppColors.merchantPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ReyBank • Rekening Penampungan',
                            style: AppTheme.font(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          Text(
                            '3210 4821 9012 (Reyhan Pratama)',
                            style: AppTheme.font(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.merchantPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Permintaan Tarik Tunai Berhasil Diproses!'),
                        backgroundColor: AppColors.merchantPrimary,
                      ),
                    );
                  },
                  child: Text(
                    'Tarik Saldo ${posState.formatCurrency(posState.merchantSummary?.balance ?? 0)}',
                    style: AppTheme.font(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
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

class _TransactionHistoryModal extends StatefulWidget {
  final PosState posState;
  const _TransactionHistoryModal({required this.posState});

  @override
  State<_TransactionHistoryModal> createState() =>
      _TransactionHistoryModalState();
}

class _TransactionHistoryModalState extends State<_TransactionHistoryModal> {
  late Future<List<TransactionRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.posState.api.getTransactions();
  }

  String _timeLabel(String iso) {
    final time = DateTime.tryParse(iso)?.toLocal();
    if (time == null) return '-';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Riwayat Transaksi Toko',
                    style: AppTheme.font(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<TransactionRecord>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.merchantPrimary,
                        ),
                      );
                    }
                    final list = snapshot.data ?? [];
                    if (list.isEmpty) {
                      return const SemestaEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Belum ada transaksi',
                        subtitle: 'Transaksi pelanggan akan tampil di sini.',
                      );
                    }
                    return ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        indent: 58,
                        color: AppColors.divider,
                      ),
                      itemBuilder: (context, index) {
                        final tx = list[index];
                        return _MerchantTransactionTile(
                          data: _MerchantTxData(
                            tx.studentName ?? 'Pelanggan',
                            'Sukses',
                            '+${widget.posState.formatCurrency(tx.amount)}',
                            _timeLabel(tx.createdAt),
                            tx.invoiceNumber,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── MERCHANT HISTORY PAGE (embedded tab) ────────────────────────────────────

class _MerchantHistoryPage extends StatefulWidget {
  final PosState posState;
  const _MerchantHistoryPage({required this.posState});

  @override
  State<_MerchantHistoryPage> createState() => _MerchantHistoryPageState();
}

class _MerchantHistoryPageState extends State<_MerchantHistoryPage> {
  late Future<List<TransactionRecord>> _future;
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _future = widget.posState.api.getTransactions();
  }

  Future<void> _refresh() async {
    setState(() => _loadData());
    await _future;
  }

  String _timeLabel(String iso) {
    final time = DateTime.tryParse(iso)?.toLocal();
    if (time == null) return '-';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
  }

  String _formatRupiah(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _openDetail(TransactionRecord tx) {
    final isCashOut = tx.type.toLowerCase().contains('cash_out');
    final rawAmount = tx.amount.round();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantSuccessScreen(
          posState: widget.posState,
          amount: _formatRupiah(rawAmount),
          rawAmount: rawAmount,
          note: '',
          studentData: StudentCardData(
            name: tx.studentName ?? 'Santri',
            balance: 0,
            cardNumber: tx.invoiceNumber,
            schoolClass: '-',
          ),
          transactionId: tx.invoiceNumber,
          createdAt: tx.createdAt,
          isCashOut: isCashOut,
          fromHistory: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Cari no. invoice atau nama santri...',
                  hintStyle: AppTheme.font(fontSize: 13, color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 20, color: AppColors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _chip('Semua', 'all'),
                  const SizedBox(width: 8),
                  _chip('Pemasukan', 'pemasukan'),
                  const SizedBox(width: 8),
                  _chip('Pengeluaran', 'pengeluaran'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.merchantPrimary,
            child: FutureBuilder<List<TransactionRecord>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.merchantPrimary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.merchantPrimary),
                      onPressed: _refresh,
                      child: const Text('Coba Lagi',
                          style: TextStyle(color: Colors.white)),
                    ),
                  );
                }
                final allList = snapshot.data ?? [];
                final filtered = allList.where((tx) {
                  final isCashOut = tx.type.toLowerCase().contains('cash_out');
                  if (_filterType == 'pemasukan' && isCashOut) {
                    return false;
                  }
                  if (_filterType == 'pengeluaran' && !isCashOut) {
                    return false;
                  }
                  if (_searchQuery.isNotEmpty) {
                    final invoice = tx.invoiceNumber.toLowerCase();
                    final name = (tx.studentName ?? '').toLowerCase();
                    if (!invoice.contains(_searchQuery) &&
                        !name.contains(_searchQuery)) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: SemestaEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Tidak ada transaksi',
                      subtitle: 'Belum ada transaksi yang sesuai kriteria.',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                    color: AppColors.divider,
                  ),
                  itemBuilder: (context, index) {
                    final tx = filtered[index];
                    final isCashOut = tx.type.toLowerCase().contains('cash_out');
                    final rawAmount = tx.amount.round();
                    return InkWell(
                      onTap: () => _openDetail(tx),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88E5)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF1E88E5),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.studentName ?? 'Santri',
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.font(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tx.invoiceNumber} • ${_timeLabel(tx.createdAt)}',
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
                                  '${isCashOut ? "-" : "+"}Rp ${_formatRupiah(rawAmount)}',
                                  style: AppTheme.font(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isCashOut
                                        ? AppColors.error
                                        : AppColors.merchantPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCashOut ? 'Pengeluaran' : 'Pemasukan',
                                  style: AppTheme.font(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isCashOut
                                        ? AppColors.error
                                        : AppColors.merchantPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.merchantPrimary
              : AppColors.merchantLightGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTheme.font(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.merchantPrimary,
          ),
        ),
      ),
    );
  }
}

// ─── MERCHANT REPORTS PAGE ──────────────────────────────────────────────────

class _MerchantReportsPage extends StatefulWidget {
  final PosState posState;
  const _MerchantReportsPage({required this.posState});

  @override
  State<_MerchantReportsPage> createState() => _MerchantReportsPageState();
}

class _MerchantReportsPageState extends State<_MerchantReportsPage> {
  int _filterMode = 0; // 0: Harian, 1: Bulanan, 2: Rentang Tanggal
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );

  bool _isLoading = false;
  String? _errorMessage;
  MerchantReport? _report;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      MerchantReport res;
      if (_filterMode == 0) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        res = await widget.posState.api.getMerchantReports(
          period: 'day',
          date: dateStr,
        );
      } else if (_filterMode == 1) {
        final monthStr = DateFormat('yyyy-MM').format(_selectedMonth);
        res = await widget.posState.api.getMerchantReports(
          period: 'month',
          month: monthStr,
        );
      } else {
        final startStr = DateFormat('yyyy-MM-dd').format(_selectedRange.start);
        final endStr = DateFormat('yyyy-MM-dd').format(_selectedRange.end);
        res = await widget.posState.api.getMerchantReports(
          period: 'range',
          start: startStr,
          end: endStr,
        );
      }

      if (mounted) {
        setState(() {
          _report = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    if (_filterMode == 0) {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.merchantPrimary,
                onPrimary: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() => _selectedDate = picked);
        _loadReport();
      }
    } else if (_filterMode == 1) {
      _showMonthPicker();
    } else {
      final picked = await showDateRangePicker(
        context: context,
        initialDateRange: _selectedRange,
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.merchantPrimary,
                onPrimary: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() => _selectedRange = picked);
        _loadReport();
      }
    }
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final currentYear = DateTime.now().year;
        final months =
            List.generate(12, (i) => DateTime(currentYear, i + 1, 1));
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilih Bulan Transaksi',
                      style: AppTheme.font(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$currentYear',
                      style: AppTheme.font(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.merchantPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: months.length,
                  itemBuilder: (context, idx) {
                    final m = months[idx];
                    final isSel = m.month == _selectedMonth.month &&
                        m.year == _selectedMonth.year;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedMonth = m);
                        _loadReport();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.merchantPrimary
                              : AppColors.merchantLightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          DateFormat('MMMM', 'id_ID').format(m),
                          style: AppTheme.font(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSel
                                ? Colors.white
                                : AppColors.merchantPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String get _currentDateLabel {
    if (_filterMode == 0) {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate);
    } else if (_filterMode == 1) {
      return DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);
    } else {
      final s = DateFormat('dd MMM yyyy', 'id_ID').format(_selectedRange.start);
      final e = DateFormat('dd MMM yyyy', 'id_ID').format(_selectedRange.end);
      return '$s  –  $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.merchantPrimary,
      onRefresh: _loadReport,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter mode chips
            _buildModeSelector(),
            const SizedBox(height: 12),

            // Date picker trigger
            _buildDateBanner(),
            const SizedBox(height: 16),

            if (_isLoading) ...[
              const SizedBox(height: 60),
              const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.merchantPrimary,
                ),
              ),
              const SizedBox(height: 60),
            ] else if (_errorMessage != null) ...[
              SemestaInfoBanner(message: _errorMessage!, isError: true),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _loadReport,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba Lagi'),
                ),
              ),
            ] else if (_report != null) ...[
              // Summary cards
              _buildSummarySection(_report!),
              const SizedBox(height: 20),

              // Breakdown Series
              if (_report!.series.isNotEmpty) ...[
                _buildSeriesSection(_report!),
                const SizedBox(height: 20),
              ],

              // Transactions list
              _buildTransactionsSection(_report!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _buildFilterChip('Harian', 0),
          _buildFilterChip('Bulanan', 1),
          _buildFilterChip('Rentang Tanggal', 2),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int mode) {
    final isSelected = _filterMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_filterMode != mode) {
            setState(() => _filterMode = mode);
            _loadReport();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.merchantPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTheme.font(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateBanner() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.merchantLightGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: AppColors.merchantPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _filterMode == 0
                        ? 'Tanggal Laporan'
                        : (_filterMode == 1 ? 'Bulan Laporan' : 'Periode Kustom'),
                    style: AppTheme.font(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currentDateLabel,
                    style: AppTheme.font(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.merchantLightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ubah',
                    style: AppTheme.font(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.merchantPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.merchantPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(MerchantReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Finansial',
          style: AppTheme.font(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Penjualan',
                value: _formatCurrency(report.summary.income),
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF00A86B),
                subtitle: 'Pemasukan Kasir',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Kas Keluar',
                value: _formatCurrency(report.summary.cashOut),
                icon: Icons.trending_down_rounded,
                color: const Color(0xFFE65100),
                subtitle: 'Pencairan Santri',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Pendapatan Bersih',
                value: _formatCurrency(report.summary.net),
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.merchantPrimary,
                subtitle: 'Net Omset',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'Volume Transaksi',
                value: '${report.summary.transactionCount}',
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF1E88E5),
                subtitle: 'Total Struk / Slip',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: AppTheme.font(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTheme.font(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.font(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesSection(MerchantReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tren Seri Harian',
          style: AppTheme.font(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: report.series.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, idx) {
              final s = report.series[idx];
              final date = DateTime.tryParse(s.date);
              final dateLabel = date != null
                  ? DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date)
                  : s.date;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.merchantLightGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          date != null ? '${date.day}' : '${idx + 1}',
                          style: AppTheme.font(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.merchantPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateLabel,
                            style: AppTheme.font(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${s.count} transaksi • Kas Keluar: ${_formatCurrency(s.cashOut)}',
                            style: AppTheme.font(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${_formatCurrency(s.income)}',
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00A86B),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection(MerchantReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Rincian Transaksi',
              style: AppTheme.font(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${report.transactions.length} item',
              style: AppTheme.font(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (report.transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 40,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tidak ada transaksi pada periode ini',
                    style: AppTheme.font(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.transactions.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 56, color: AppColors.divider),
              itemBuilder: (context, idx) {
                final tx = report.transactions[idx];
                final isCashOut = tx.type == 'cash_out';
                final time = DateTime.tryParse(tx.createdAt)?.toLocal();
                final timeLabel = time != null
                    ? DateFormat('dd MMM HH:mm', 'id_ID').format(time)
                    : tx.createdAt;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCashOut
                              ? const Color(0xFFE65100).withValues(alpha: 0.1)
                              : AppColors.merchantLightGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCashOut
                              ? Icons.outbox_rounded
                              : Icons.arrow_downward_rounded,
                          size: 20,
                          color: isCashOut
                              ? const Color(0xFFE65100)
                              : AppColors.merchantPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCashOut
                                  ? (tx.studentName != null
                                      ? 'Kas Keluar: ${tx.studentName}'
                                      : 'Kas Keluar Santri')
                                  : (tx.studentName ?? 'Pelanggan POS'),
                              style: AppTheme.font(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${tx.outletName ?? 'Kantin'} • $timeLabel',
                              style: AppTheme.font(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isCashOut ? '-' : '+'}${_formatCurrency(tx.amount)}',
                        style: AppTheme.font(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isCashOut
                              ? const Color(0xFFE65100)
                              : const Color(0xFF00A86B),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── MERCHANT SETTINGS & PROFILE PAGE ────────────────────────────────────────

class _MerchantSettingsPage extends StatefulWidget {
  final PosState posState;
  final VoidCallback? onLogout;
  const _MerchantSettingsPage({
    required this.posState,
    this.onLogout,
  });

  @override
  State<_MerchantSettingsPage> createState() => _MerchantSettingsPageState();
}

class _MerchantSettingsPageState extends State<_MerchantSettingsPage> {
  bool _isUploadingAvatar = false;
  bool _isStoreOpen = true;
  bool _soundNotification = true;

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) {
        if (mounted) {
          AppToast.show(
            context,
            'Gagal membaca file gambar.',
            type: ToastType.error,
          );
        }
        return;
      }

      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          AppToast.show(
            context,
            'Ukuran foto maksimal 5 MB.',
            type: ToastType.warning,
          );
        }
        return;
      }

      setState(() => _isUploadingAvatar = true);

      final ext = pickedFile.name.split('.').last.toLowerCase();
      final mimeType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      final base64String = 'data:$mimeType;base64,${base64Encode(bytes)}';

      await widget.posState.updateAvatar(base64String);

      if (mounted) {
        AppToast.show(
          context,
          'Foto profil merchant berhasil diperbarui',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          'Gagal mengunggah foto profil: ${e.toString().replaceAll("Exception: ", "")}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showEditProfileDialog() {
    final user = widget.posState.currentUser;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.merchantLightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.store_mall_directory_rounded,
                  color: AppColors.merchantPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Ubah Data Merchant',
                style: AppTheme.font(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemestaTextField(
                  controller: nameCtrl,
                  label: 'Nama Petugas / Kasir',
                  hint: 'Nama lengkap kasir',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                SemestaTextField(
                  controller: usernameCtrl,
                  label: 'Username',
                  hint: 'username_merchant',
                  prefixIcon: Icons.alternate_email_rounded,
                ),
                const SizedBox(height: 12),
                SemestaTextField(
                  controller: emailCtrl,
                  label: 'Email Toko',
                  hint: 'kasir@kantin.id',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                SemestaTextField(
                  controller: phoneCtrl,
                  label: 'Nomor Telepon / WhatsApp',
                  hint: '081234567890',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
              child: Text(
                'Batal',
                style: AppTheme.font(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.merchantPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        await widget.posState.updateProfile(
                          name: nameCtrl.text.trim(),
                          username: usernameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                        );
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (mounted) {
                          AppToast.show(
                            context,
                            'Data profil berhasil disimpan',
                            type: ToastType.success,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setDialogState(() => isSaving = false);
                          AppToast.show(
                            context,
                            'Gagal menyimpan profil: ${e.toString().replaceAll("Exception: ", "")}',
                            type: ToastType.error,
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Simpan',
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.posState.currentUser;
    final merchantName =
        widget.posState.merchantSummary?.name ?? widget.posState.outletName;
    final hasAvatar = user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Profile Header Card ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar with upload trigger
                    GestureDetector(
                      onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                      child: Stack(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.merchantPrimary,
                                  Color(0xFF00C896)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.merchantPrimary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: hasAvatar
                                ? ClipOval(
                                    child: Image.network(
                                      user.avatarUrl!,
                                      width: 68,
                                      height: 68,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Center(
                                        child: Icon(
                                          Icons.storefront_rounded,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.storefront_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                          ),
                          if (_isUploadingAvatar)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppColors.merchantPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.name ?? merchantName,
                                  style: AppTheme.font(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.merchantLightGreen,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Kasir',
                                  style: AppTheme.font(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.merchantPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'kasir@kantin.id',
                            style: AppTheme.font(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.username != null
                                ? '@${user!.username}'
                                : 'Outlet: ${widget.posState.outletCode}',
                            style: AppTheme.font(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.merchantPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.divider),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed:
                            _isUploadingAvatar ? null : _pickAndUploadAvatar,
                        icon: const Icon(
                          Icons.photo_camera_outlined,
                          size: 16,
                          color: AppColors.merchantPrimary,
                        ),
                        label: Text(
                          'Ganti Foto',
                          style: AppTheme.font(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.merchantPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.divider),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _showEditProfileDialog,
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: AppColors.textPrimary,
                        ),
                        label: Text(
                          'Ubah Profil',
                          style: AppTheme.font(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 2. Store Info Card ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.merchantPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Informasi Toko / Kantin',
                      style: AppTheme.font(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nama Merchant',
                        style: AppTheme.font(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text(merchantName,
                        style: AppTheme.font(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Outlet / POS',
                        style: AppTheme.font(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      '${widget.posState.outletName} (${widget.posState.outletCode})',
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Saldo Merchant',
                        style: AppTheme.font(
                            fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      widget.posState.formatCurrency(
                        widget.posState.merchantSummary?.balance ?? 0,
                      ),
                      style: AppTheme.font(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.merchantPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 3. Operasional Kasir ─────────────────────────────────
          Text(
            'Operasional & Hardware Kasir',
            style: AppTheme.font(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _buildTile(
                  icon: Icons.print_rounded,
                  iconColor: AppColors.merchantPrimary,
                  title: 'Printer Thermal Kasir',
                  subtitle: 'Epson POS 58mm • Terhubung',
                  trailing: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF00A86B),
                    size: 20,
                  ),
                  onTap: () {
                    AppToast.show(
                      context,
                      'Printer thermal siap mencetak struk transaksi otomatis',
                      type: ToastType.success,
                    );
                  },
                ),
                const Divider(height: 1, indent: 56, color: AppColors.divider),
                _buildTile(
                  icon: Icons.store_rounded,
                  iconColor: const Color(0xFFE67E22),
                  title: 'Status Buka Toko',
                  subtitle: _isStoreOpen
                      ? 'Toko menerima pembayaran'
                      : 'Toko tutup sementara',
                  trailing: Switch(
                    value: _isStoreOpen,
                    activeThumbColor: AppColors.merchantPrimary,
                    activeTrackColor:
                        AppColors.merchantPrimary.withValues(alpha: 0.35),
                    onChanged: (val) {
                      setState(() => _isStoreOpen = val);
                      AppToast.show(
                        context,
                        val
                            ? 'Status toko diatur: BUKA'
                            : 'Status toko diatur: TUTUP SEMENTARA',
                        type: val ? ToastType.success : ToastType.warning,
                      );
                    },
                  ),
                ),
                const Divider(height: 1, indent: 56, color: AppColors.divider),
                _buildTile(
                  icon: Icons.volume_up_rounded,
                  iconColor: const Color(0xFF1E88E5),
                  title: 'Suara Notifikasi Kasir',
                  subtitle: 'Bunyi saat transaksi NFC berhasil',
                  trailing: Switch(
                    value: _soundNotification,
                    activeThumbColor: AppColors.merchantPrimary,
                    activeTrackColor:
                        AppColors.merchantPrimary.withValues(alpha: 0.35),
                    onChanged: (val) => setState(() => _soundNotification = val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 4. Bantuan & CS ──────────────────────────────────────
          Text(
            'Bantuan & Dukungan',
            style: AppTheme.font(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _buildTile(
                  icon: Icons.contact_support_rounded,
                  iconColor: AppColors.merchantPrimary,
                  title: 'Hubungi Admin Pesantren',
                  subtitle: 'Kendala saldo, settlement & kartu RFID',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () {
                    AppToast.show(
                      context,
                      'Hubungi Finance Semestapay: finance@semestapay.id',
                      type: ToastType.info,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 5. Logout Button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(
                'Keluar Akun Merchant',
                style: AppTheme.font(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
              onPressed: widget.onLogout,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Semestapay Merchant POS v1.2.0 • Build 2026.11\nSistem Kasir Cashless Sekolah & Pesantren',
              textAlign: TextAlign.center,
              style: AppTheme.font(
                fontSize: 11,
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.font(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.font(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
