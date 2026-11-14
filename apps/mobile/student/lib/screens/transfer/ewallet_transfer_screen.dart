import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_toast.dart';
import 'transfer_screen.dart';

/// Model E-Wallet
class EWalletInfo {
  final String id;
  final String name;
  final String description;
  final Color color;
  final IconData icon;

  const EWalletInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    this.icon = Icons.account_balance_wallet_rounded,
  });
}

/// Model Saran Transaksi E-Wallet Sebelumnya
class EWalletRecentItem {
  final String name;
  final String phoneNumber;
  final String walletId;

  const EWalletRecentItem({
    required this.name,
    required this.phoneNumber,
    required this.walletId,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1: DAFTAR PILIHAN E-WALLET
// ─────────────────────────────────────────────────────────────────────────────

class EWalletTransferScreen extends StatefulWidget {
  const EWalletTransferScreen({super.key});

  @override
  State<EWalletTransferScreen> createState() => _EWalletTransferScreenState();
}

class _EWalletTransferScreenState extends State<EWalletTransferScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<EWalletInfo> _wallets = const [
    EWalletInfo(
      id: 'gopay',
      name: 'GoPay',
      description: 'Transfer & Top Up Saldo GoPay',
      color: Color(0xFF00AED6),
      icon: Icons.account_balance_wallet_rounded,
    ),
    EWalletInfo(
      id: 'ovo',
      name: 'OVO',
      description: 'Transfer Saldo OVO Cash',
      color: Color(0xFF4C3494),
      icon: Icons.smartphone_rounded,
    ),
    EWalletInfo(
      id: 'dana',
      name: 'DANA',
      description: 'Transfer Saldo DANA Dompet Digital',
      color: Color(0xFF118EEA),
      icon: Icons.account_balance_wallet_rounded,
    ),
    EWalletInfo(
      id: 'shopeepay',
      name: 'ShopeePay',
      description: 'Top Up & Transfer Saldo ShopeePay',
      color: Color(0xFFEE4D2D),
      icon: Icons.shopping_bag_rounded,
    ),
    EWalletInfo(
      id: 'linkaja',
      name: 'LinkAja',
      description: 'Transfer Saldo LinkAja Reguler & Syariah',
      color: Color(0xFFED1C24),
      icon: Icons.wallet_rounded,
    ),
    EWalletInfo(
      id: 'astrapay',
      name: 'AstraPay',
      description: 'Top Up Saldo AstraPay',
      color: Color(0xFF003399),
      icon: Icons.electric_car_rounded,
    ),
    EWalletInfo(
      id: 'isaku',
      name: 'i.saku',
      description: 'Transfer Saldo i.saku Indomaret',
      color: Color(0xFF3F51B5),
      icon: Icons.store_rounded,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EWalletInfo> get _filteredWallets {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _wallets;
    return _wallets.where((w) {
      return w.name.toLowerCase().contains(query) || w.description.toLowerCase().contains(query);
    }).toList();
  }

  void _onSelectWallet(EWalletInfo wallet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InputEWalletNumberScreen(wallet: wallet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredWallets;

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
          'Pilih E-Wallet',
          style: AppTheme.font(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: AppTheme.font(fontSize: 13, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari GoPay, OVO, DANA, ShopeePay...',
                    hintStyle: AppTheme.font(fontSize: 13, color: AppColors.textLight),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  ),
                ),
              ),
            ),

            // Banner Bebas Admin
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 18, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gratis biaya admin transfer ke seluruh dompet digital.',
                        style: AppTheme.font(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // List E-Wallet
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    'Dompet Digital Populer',
                    style: AppTheme.font(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: AppColors.divider,
                      ),
                      itemBuilder: (context, index) {
                        final w = filtered[index];
                        return InkWell(
                          onTap: () => _onSelectWallet(w),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: w.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(w.icon, color: w.color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        w.name,
                                        style: AppTheme.font(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        w.description,
                                        style: AppTheme.font(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textLight),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2: CARD NAMA WALLET + INPUT NOMOR + SARAN / BUAT TRANSAKSI DENGAN NOMOR
// ─────────────────────────────────────────────────────────────────────────────

class InputEWalletNumberScreen extends StatefulWidget {
  final EWalletInfo wallet;

  const InputEWalletNumberScreen({super.key, required this.wallet});

  @override
  State<InputEWalletNumberScreen> createState() => _InputEWalletNumberScreenState();
}

class _InputEWalletNumberScreenState extends State<InputEWalletNumberScreen> {
  final TextEditingController _phoneController = TextEditingController();

  // Saran transaksi sebelumnya untuk e-wallet ini
  final List<EWalletRecentItem> _allRecents = const [
    EWalletRecentItem(name: 'Dina Marcelina', phoneNumber: '081234567890', walletId: 'gopay'),
    EWalletRecentItem(name: 'Rizky Ramadhan', phoneNumber: '085711223344', walletId: 'dana'),
    EWalletRecentItem(name: 'Siti Nurhaliza', phoneNumber: '087899001122', walletId: 'ovo'),
    EWalletRecentItem(name: 'Ahmad Fauzi', phoneNumber: '082188990011', walletId: 'shopeepay'),
    EWalletRecentItem(name: 'Kantin Sekolah', phoneNumber: '081399887766', walletId: 'linkaja'),
    EWalletRecentItem(name: 'Budi Santoso', phoneNumber: '089677889900', walletId: 'gopay'),
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _cleanDigits => _phoneController.text.trim().replaceAll(' ', '').replaceAll('-', '');

  bool get _isValidPhone => _cleanDigits.length >= 10;

  void _proceedWithNumber(String phone, {String? customName}) {
    final clean = phone.trim().replaceAll(' ', '').replaceAll('-', '');
    if (clean.length < 10) {
      AppToast.show(
        context,
        'Nomor ponsel e-wallet minimal 10 digit',
        type: ToastType.warning,
      );
      return;
    }

    // Nama penerima
    final name = customName ?? 'Akun ${widget.wallet.name} ($clean)';

    final recipient = RecipientData(
      name: name,
      bankName: widget.wallet.name,
      accountNumber: clean,
      avatarColor: widget.wallet.color,
      icon: widget.wallet.icon,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferScreen(
          initialRecipient: recipient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentInput = _phoneController.text.trim();
    final hasInput = currentInput.length >= 4;

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
          'Kirim ke ${widget.wallet.name}',
          style: AppTheme.font(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Card Nama Wallet + Icon ───────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: widget.wallet.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.wallet.icon, color: widget.wallet.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dompet Digital',
                            style: AppTheme.font(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.wallet.name,
                            style: AppTheme.font(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Ganti',
                          style: AppTheme.font(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 2. Input Nomor Telepon E-Wallet ──────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nomor Handphone Akun',
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        style: AppTheme.font(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contoh: 081234567890',
                          hintStyle: AppTheme.font(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textLight,
                            letterSpacing: 0,
                          ),
                          prefixIcon: const Icon(Icons.phone_iphone_rounded, size: 20, color: AppColors.textSecondary),
                          suffixIcon: currentInput.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                                  onPressed: () {
                                    _phoneController.clear();
                                    setState(() {});
                                  },
                                )
                              : IconButton(
                                  icon: const Icon(Icons.contact_phone_rounded, size: 20, color: AppColors.primary),
                                  tooltip: 'Kontak',
                                  onPressed: () {
                                    _phoneController.text = '081298765432';
                                    setState(() {});
                                  },
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 3. Opsi: Buat Transaksi Dengan Nomor [nomor] (Saat nomor diketik) ──
              if (hasInput) ...[
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => _proceedWithNumber(currentInput),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Buat transaksi dengan nomor $currentInput',
                                  style: AppTheme.font(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kirim saldo ke akun ${widget.wallet.name}',
                                  style: AppTheme.font(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── 4. Saran Transaksi Sebelumnya ─────────────────────
              Text(
                'Saran Transaksi Sebelumnya',
                style: AppTheme.font(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allRecents.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    color: AppColors.divider,
                  ),
                  itemBuilder: (context, index) {
                    final item = _allRecents[index];
                    return InkWell(
                      onTap: () {
                        _phoneController.text = item.phoneNumber;
                        setState(() {});
                        _proceedWithNumber(item.phoneNumber, customName: item.name);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: widget.wallet.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(widget.wallet.icon, color: widget.wallet.color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: AppTheme.font(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.phoneNumber,
                                    style: AppTheme.font(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.textLight),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // ── 5. Sticky Bottom Button: Lanjutkan ────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isValidPhone ? AppColors.primary : const Color(0xFFD3D8E8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: _isValidPhone ? () => _proceedWithNumber(currentInput) : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lanjutkan',
                  style: AppTheme.font(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
