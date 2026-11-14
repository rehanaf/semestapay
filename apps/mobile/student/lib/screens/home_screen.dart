import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import '../state/student_state.dart';
import 'topup/topup_flow.dart';
import 'transfer/student_transfer_list_screen.dart';
import 'transfer/ewallet_transfer_screen.dart';
import 'bills_page.dart';
import 'history_page.dart';
import 'notification_screen.dart';
import 'profile_page.dart';

class StudentShell extends StatefulWidget {
  final StudentState state;
  const StudentShell({super.key, required this.state});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.state.refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.state.refresh();
    }
  }

  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    widget.state.refresh();
  }
  late final List<Widget> _pages = [
    _HomePage(
      state: widget.state,
      onGoToTransfer: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentTransferListScreen(
              api: widget.state.api,
              balance: widget.state.student?.balance ?? 0,
              onTransferComplete: widget.state.refresh,
            ),
          ),
        );
      },
      onGoToHistory: () => _changeTab(2),
    ),
    BillsPage(
      state: widget.state,
      onBackToHome: () => _changeTab(0),
    ),
    HistoryPage(
      state: widget.state,
      onBackToHome: () => _changeTab(0),
    ),
    ProfilePage(
      state: widget.state,
      onBackToHome: () => _changeTab(0),
      onLogout: _showLogoutDialog,
    ),
  ];

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: Text(
          'Konfirmasi Logout',
          style: AppTheme.font(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Semestapay?',
          style: AppTheme.font(fontSize: 14, color: AppColors.textSecondary),
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
              widget.state.logout();
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
    if (_currentIndex != 0) return null;

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      toolbarHeight: 70,
      title: Row(
        children: [
          // Avatar Lingkaran
          GestureDetector(
            onTap: () => _changeTab(3),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child:
                  widget.state.student?.avatarUrl != null &&
                      widget.state.student!.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.state.student!.avatarUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Nama & No Rekening
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.state.student?.name ?? 'Santri Semestapay',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIS ${widget.state.student?.nis ?? '-'}',
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _AppBarButton(
          icon: Icons.notifications_none_rounded,
          badge: 3,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _openQrisScanner() {
    openQrisScanner(context);
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
                          _NavItem(
                            icon: Icons.home_rounded,
                            label: 'Beranda',
                            isActive: _currentIndex == 0,
                            onTap: () => _changeTab(0),
                          ),
                          _NavItem(
                            icon: Icons.receipt_rounded,
                            label: 'Tagihan',
                            isActive: _currentIndex == 1,
                            onTap: () => _changeTab(1),
                          ),
                        ],
                      ),
                    ),
                    // Ruang tengah untuk tombol QRIS timbul
                    const SizedBox(width: 76),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _NavItem(
                            icon: Icons.history_rounded,
                            label: 'Riwayat',
                            isActive: _currentIndex == 2,
                            onTap: () => _changeTab(2),
                          ),
                          _NavItem(
                            icon: Icons.person_rounded,
                            label: 'Profil',
                            isActive: _currentIndex == 3,
                            onTap: () => _changeTab(3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tombol Scan QRIS Timbul Bentuk SQUIRCLE
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: _openQrisScanner,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // SQUIRCLE SHAPE
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A56FF), Color(0xFF00C896)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.42),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'QRIS',
                        style: AppTheme.font(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.4,
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

// ─── HOME PAGE ──────────────────────────────────────────────────────────────

class _HomePage extends StatefulWidget {
  final StudentState state;
  final VoidCallback? onGoToTransfer;
  final VoidCallback? onGoToHistory;
  const _HomePage({
    required this.state,
    this.onGoToTransfer,
    this.onGoToHistory,
  });

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  bool _balanceVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.state.refresh();
    });
  }

  String _topupTitle(String? note) {
    final n = (note ?? '').toLowerCase();
    if (n.contains('bca') || n == 'bc') return 'Isi Saldo dari Bank BCA';
    if (n.contains('mandiri') || n == 'm2') return 'Isi Saldo dari Bank Mandiri';
    if (n.contains('bni') || n == 'i1') return 'Isi Saldo dari Bank BNI';
    if (n.contains('bri') || n == 'br') return 'Isi Saldo dari Bank BRI';
    if (n.contains('cimb') || n == 'b1') return 'Isi Saldo dari CIMB Niaga';
    if (n.contains('permata') || n == 'bt') return 'Isi Saldo dari Bank Permata';
    if (n.contains('duitku')) return 'Isi Saldo Online';
    if (n.isNotEmpty && n != 'cash' && n != 'topup') return 'Isi Saldo dari $note';
    return 'Top Up Saldo';
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildBalanceCard()),
        SliverToBoxAdapter(child: _buildShortcuts()),
        SliverToBoxAdapter(child: _buildPromoSection()),
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
            colors: [Color(0xFF1A56FF), Color(0xFF0D3BCC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.38),
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
                  color: Colors.white.withValues(alpha: 0.06),
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
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Saldo Tersedia + Eye icon + Spacer + Chevron icon di pojok kanan
                  Row(
                    children: [
                      Text(
                        'Saldo Tersedia',
                        style: AppTheme.font(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
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
                        onTap: () {},
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
                            widget.state.formatCurrency(
                              widget.state.student?.balance ?? 0,
                            ),
                            key: const ValueKey('visible'),
                            style: AppTheme.font(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          )
                        : Text(
                            'Rp ••••••••',
                            key: const ValueKey('hidden'),
                            style: AppTheme.font(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  // Actions: Top Up, Kirim, Terima berbentuk Button dengan icon di kiri
                  Row(
                    children: [
                      Expanded(
                        child: _BalanceActionButton(
                          icon: Icons.add_rounded,
                          label: 'Top Up',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TopUpScreen(
                                  api: widget.state.api,
                                  onVirtualAccountCreated:
                                      widget.state.addVirtualAccount,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BalanceActionButton(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Kirim',
                          onTap: () => widget.onGoToTransfer?.call(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BalanceActionButton(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Terima',
                          onTap: () {},
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

  Widget _buildShortcuts() {
    final shortcuts = [
      _ShortcutData(
        Icons.account_balance_rounded,
        'Transfer Bank',
        AppColors.primary,
        type: _ShortcutType.bankTransfer,
      ),
      _ShortcutData(
        Icons.account_balance_wallet_rounded,
        'E-Wallet',
        const Color(0xFF00C896),
        type: _ShortcutType.ewallet,
      ),
      _ShortcutData(Icons.water_drop_rounded, 'PDAM', const Color(0xFF29B6F6)),
      _ShortcutData(Icons.wifi_rounded, 'Internet', const Color(0xFF66BB6A)),
      _ShortcutData(
        Icons.local_gas_station_rounded,
        'BBM',
        const Color(0xFFAB47BC),
      ),
      _ShortcutData(
        Icons.credit_card_rounded,
        'Kartu',
        const Color(0xFFEF5350),
      ),
      _ShortcutData(
        Icons.receipt_long_rounded,
        'Tagihan',
        const Color(0xFFFF9800),
      ),
      _ShortcutData(
        Icons.more_horiz_rounded,
        'Lainnya',
        AppColors.textSecondary,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                  'Layanan Cepat',
                  style: AppTheme.font(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Atur',
                    style: AppTheme.font(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Grid kebawah (4 kolom)
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
                return _ShortcutItem(
                  data: shortcuts[index],
                  onTransfer: widget.onGoToTransfer,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoSection() {
    final promos = [
      _PromoCardData(
        color: const Color(0xFF1A56FF),
        title: 'Cashback 20% Sesama ReyBank',
        subtitle: 'Khusus transfer min. Rp 100.000 ke sesama ReyBank.',
        icon: Icons.swap_horiz_rounded,
        tag: 'Cashback',
      ),
      _PromoCardData(
        color: const Color(0xFF00C896),
        title: 'Bebas Biaya Admin Tagihan',
        subtitle: 'Bayar PLN, PDAM, & Internet tanpa biaya admin s/d 31 Des.',
        icon: Icons.bolt_rounded,
        tag: 'Gratis',
      ),
      _PromoCardData(
        color: const Color(0xFFFF6B35),
        title: 'Bunga Deposito Spesial 6% p.a.',
        subtitle: 'Buka tabungan deposito instan mulai dari Rp 1.000.000.',
        icon: Icons.savings_rounded,
        tag: 'Investasi',
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
                'Promo Untukmu',
                style: AppTheme.font(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onGoToHistory,
                child: Text(
                  'Lihat semua',
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // List Promo disusun menurun (kebawah)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: promos.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (_, index) => _PromoVerticalCard(data: promos[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final mutations = widget.state.mutations.take(4).toList();
    final transactions = mutations.map((m) {
      final isCredit = m.isCredit;
      final isTopup = m.type == 'topup';
      final title = isTopup
          ? _topupTitle(m.note)
          : (m.merchant?.isNotEmpty == true
              ? m.merchant!
              : (m.note?.isNotEmpty == true ? m.note! : _titleForMutation(m.type)));
      final category = m.outlet?.isNotEmpty == true
          ? m.outlet!
          : _titleForMutation(m.type);
      return _TxData(
        _iconForMutation(m.type),
        title,
        category,
        '${isCredit ? '+' : '-'}${widget.state.formatCurrency(m.amount)}',
        isCredit,
        isCredit ? AppColors.accent : _colorForMutation(m.type),
        _shortTime(m.createdAt),
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
                onTap: widget.onGoToHistory,
                child: Text(
                  'Lihat semua',
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
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
                  padding: const EdgeInsets.symmetric(vertical: 26),
                  child: SemestaEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum ada transaksi',
                    subtitle: 'Transaksi jajan dan top up akan tampil di sini.',
                  ),
                )
              : Column(
                  children: List.generate(transactions.length, (i) {
                    return Column(
                      children: [
                        _TransactionTile(data: transactions[i]),
                        if (i < transactions.length - 1)
                          const Divider(
                            height: 1,
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

  String _shortTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final date = DateTime.tryParse(iso)?.toLocal();
    if (date == null) return '-';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _titleForMutation(String type) {
    switch (type) {
      case 'topup':
        return 'Top Up Saldo';
      case 'payment':
        return 'Pembayaran Merchant';
      case 'transfer':
      case 'transfer_in':
      case 'transfer_out':
        return 'Transfer';
      case 'withdraw':
        return 'Tarik Tunai';
      case 'reversal':
        return 'Pengembalian Dana';
      default:
        return 'Transaksi';
    }
  }

  IconData _iconForMutation(String type) {
    switch (type) {
      case 'topup':
        return Icons.account_balance_wallet_rounded;
      case 'payment':
        return Icons.storefront_rounded;
      case 'transfer':
      case 'transfer_in':
      case 'transfer_out':
        return Icons.swap_horiz_rounded;
      case 'withdraw':
        return Icons.atm_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _colorForMutation(String type) {
    switch (type) {
      case 'payment':
        return AppColors.merchantPrimary;
      case 'transfer':
      case 'transfer_in':
      case 'transfer_out':
        return const Color(0xFF00C896);
      case 'withdraw':
        return const Color(0xFFFF6B35);
      default:
        return AppColors.primary;
    }
  }
}

// ─── REUSABLE WIDGETS ────────────────────────────────────────────────────────

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final int? badge;
  final VoidCallback onTap;

  const _AppBarButton({required this.icon, required this.onTap, this.badge});

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
            child: Icon(icon, color: AppColors.textPrimary, size: 24),
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

class _BalanceActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BalanceActionButton({
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
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.font(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ShortcutType { bankTransfer, ewallet, general }

class _ShortcutData {
  final IconData icon;
  final String label;
  final Color color;
  final _ShortcutType type;
  _ShortcutData(
    this.icon,
    this.label,
    this.color, {
    this.type = _ShortcutType.general,
  });
}

class _ShortcutItem extends StatelessWidget {
  final _ShortcutData data;
  final VoidCallback? onTransfer;

  const _ShortcutItem({required this.data, this.onTransfer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (data.type == _ShortcutType.bankTransfer) {
          onTransfer?.call();
        } else if (data.type == _ShortcutType.ewallet) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EWalletTransferScreen()),
          );
        } else {
          AppToast.show(
            context,
            'Layanan ${data.label} segera hadir',
            type: ToastType.info,
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Squircle container
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16), // SQUIRCLE shape
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

class _PromoCardData {
  final Color color;
  final String title;
  final String subtitle;
  final IconData icon;
  final String tag;

  const _PromoCardData({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tag,
  });
}

class _PromoVerticalCard extends StatelessWidget {
  final _PromoCardData data;

  const _PromoVerticalCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
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
            // Squircle Promo Icon
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
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
      ),
    );
  }
}

class _TxData {
  final IconData icon;
  final String name;
  final String category;
  final String amount;
  final bool isCredit;
  final Color color;
  final String time;

  const _TxData(
    this.icon,
    this.name,
    this.category,
    this.amount,
    this.isCredit,
    this.color,
    this.time,
  );
}

class _TransactionTile extends StatelessWidget {
  final _TxData data;

  const _TransactionTile({required this.data});

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
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: AppTheme.font(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.category,
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.amount,
                style: AppTheme.font(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: data.isCredit
                      ? AppColors.accent
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.time,
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
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
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
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textLight,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.font(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── QRIS SCANNER MODAL ─────────────────────────────────────────────────────

void openQrisScanner(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _QrisScannerSheet(),
  );
}

class _QrisScannerSheet extends StatefulWidget {
  const _QrisScannerSheet();

  @override
  State<_QrisScannerSheet> createState() => _QrisScannerSheetState();
}

class _QrisScannerSheetState extends State<_QrisScannerSheet>
    with SingleTickerProviderStateMixin {
  bool _isFlashOn = false;
  late AnimationController _scanAnimController;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Scan QRIS',
                  style: AppTheme.font(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Arahkan kamera ke kode QRIS merchant untuk membayar',
              textAlign: TextAlign.center,
              style: AppTheme.font(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  _buildCorner(top: 0, left: 0, isTop: true, isLeft: true),
                  _buildCorner(top: 0, right: 0, isTop: true, isLeft: false),
                  _buildCorner(bottom: 0, left: 0, isTop: false, isLeft: true),
                  _buildCorner(
                    bottom: 0,
                    right: 0,
                    isTop: false,
                    isLeft: false,
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _scanAnimController,
                    builder: (context, child) {
                      return Positioned(
                        top: 20 + _scanAnimController.value * 200,
                        left: 16,
                        right: 16,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.accent,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 36),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ScannerAction(
                  icon: _isFlashOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  label: 'Flashlight',
                  isActive: _isFlashOn,
                  onTap: () => setState(() => _isFlashOn = !_isFlashOn),
                ),
                _ScannerAction(
                  icon: Icons.image_rounded,
                  label: 'Galeri',
                  onTap: () {},
                ),
                _ScannerAction(
                  icon: Icons.qr_code_2_rounded,
                  label: 'QR Saya',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool isTop,
    required bool isLeft,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: AppColors.accent, width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: AppColors.accent, width: 4)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: AppColors.accent, width: 4)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: AppColors.accent, width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(20) : Radius.zero,
            topRight: isTop && !isLeft
                ? const Radius.circular(20)
                : Radius.zero,
            bottomLeft: !isTop && isLeft
                ? const Radius.circular(20)
                : Radius.zero,
            bottomRight: !isTop && !isLeft
                ? const Radius.circular(20)
                : Radius.zero,
          ),
        ),
      ),
    );
  }
}

class _ScannerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ScannerAction({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.font(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
