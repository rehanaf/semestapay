import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_toast.dart';
import 'transfer_screen.dart';

/// Model Bank
class BankInfo {
  final String code;
  final String name;
  final Color color;
  final IconData icon;

  const BankInfo({
    required this.code,
    required this.name,
    required this.color,
    this.icon = Icons.account_balance_rounded,
  });
}

/// Model Riwayat Transfer Bank
class BankAccountItem {
  final String id;
  final String name;
  final String bankName;
  final String accountNumber;
  final Color bankColor;
  final bool isFavorite;

  const BankAccountItem({
    required this.id,
    required this.name,
    required this.bankName,
    required this.accountNumber,
    required this.bankColor,
    this.isFavorite = false,
  });

  BankAccountItem copyWith({bool? isFavorite}) {
    return BankAccountItem(
      id: id,
      name: name,
      bankName: bankName,
      accountNumber: accountNumber,
      bankColor: bankColor,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  RecipientData toRecipientData() {
    return RecipientData(
      name: name,
      bankName: bankName,
      accountNumber: accountNumber,
      avatarColor: bankColor,
      icon: Icons.account_balance_rounded,
    );
  }
}

class BankTransferScreen extends StatefulWidget {
  const BankTransferScreen({super.key});

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0; // 0 = Semua, 1 = Favorit

  // Daftar transfer terakhir
  late final List<BankAccountItem> _accounts = [
    const BankAccountItem(
      id: '1',
      name: 'Budi Santoso',
      bankName: 'Bank BCA',
      accountNumber: '8820 1928 331',
      bankColor: Color(0xFF005696),
      isFavorite: true,
    ),
    const BankAccountItem(
      id: '2',
      name: 'Siti Rahmawati',
      bankName: 'Bank Mandiri',
      accountNumber: '1370 0019 8210',
      bankColor: Color(0xFF00387A),
      isFavorite: true,
    ),
    const BankAccountItem(
      id: '3',
      name: 'Ahmad Pratama',
      bankName: 'Bank BRI',
      accountNumber: '0021 9831 0021 501',
      bankColor: Color(0xFF00529C),
      isFavorite: false,
    ),
    const BankAccountItem(
      id: '4',
      name: 'Dewi Lestari',
      bankName: 'Bank BNI',
      accountNumber: '0812 9012 88',
      bankColor: Color(0xFFF15A24),
      isFavorite: true,
    ),
    const BankAccountItem(
      id: '5',
      name: 'Koperasi Siswa Mandiri',
      bankName: 'Bank Syariah Indonesia (BSI)',
      accountNumber: '7112 0049 18',
      bankColor: Color(0xFF00A39D),
      isFavorite: false,
    ),
    const BankAccountItem(
      id: '6',
      name: 'Hendra Wijaya',
      bankName: 'CIMB Niaga',
      accountNumber: '7051 8921 4400',
      bankColor: Color(0xFFED1C24),
      isFavorite: false,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BankAccountItem> get _filteredAccounts {
    final query = _searchController.text.trim().toLowerCase();
    return _accounts.where((item) {
      if (_selectedTab == 1 && !item.isFavorite) return false;
      if (query.isNotEmpty) {
        final matchName = item.name.toLowerCase().contains(query);
        final matchBank = item.bankName.toLowerCase().contains(query);
        final matchAcc = item.accountNumber.replaceAll(' ', '').contains(query.replaceAll(' ', ''));
        return matchName || matchBank || matchAcc;
      }
      return true;
    }).toList();
  }

  void _toggleFavorite(int index) {
    setState(() {
      final item = _accounts[index];
      _accounts[index] = item.copyWith(isFavorite: !item.isFavorite);
    });
    final item = _accounts[index];
    AppToast.show(
      context,
      item.isFavorite ? '${item.name} ditambahkan ke favorit' : '${item.name} dihapus dari favorit',
      type: ToastType.info,
    );
  }

  void _goToTransferAmount(BankAccountItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferScreen(
          initialRecipient: item.toRecipientData(),
        ),
      ),
    );
  }

  void _openNewTransferFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SelectBankScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAccounts;

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
          'Transfer Bank',
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
            // Area Search & Tabs
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  // Search Box
                  Container(
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
                        hintText: 'Cari nama penerima atau no. rekening...',
                        hintStyle: AppTheme.font(fontSize: 13, color: AppColors.textLight),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tab: Semua vs Favorit (Segmented Capsule Control)
                  Container(
                    height: 42,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(0, 'Semua (${_accounts.length})'),
                        _buildTabButton(1, 'Favorit (${_accounts.where((e) => e.isFavorite).length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List Transfer Terakhir
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            _selectedTab == 0 ? 'Daftar Transfer Terakhir' : 'Rekening Bank Favorit',
                            style: AppTheme.font(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
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
                              indent: 68,
                              endIndent: 16,
                              color: AppColors.divider,
                            ),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              final originalIndex = _accounts.indexOf(item);
                              return _buildAccountTile(item, originalIndex);
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),

      // Sticky Bottom Button: Buat Transfer Baru
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
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: _openNewTransferFlow,
            icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            label: Text(
              'Buat Transfer Baru',
              style: AppTheme.font(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
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
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.font(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTile(BankAccountItem item, int originalIndex) {
    return InkWell(
      onTap: () => _goToTransferAmount(item),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon Bank
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.bankColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.account_balance_rounded, color: item.bankColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Nama & Rekening
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTheme.font(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.bankName} • ${item.accountNumber}',
                    style: AppTheme.font(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Tombol Favorit
            IconButton(
              icon: Icon(
                item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: item.isFavorite ? const Color(0xFFFFB300) : AppColors.textLight,
                size: 24,
              ),
              onPressed: () => _toggleFavorite(originalIndex),
            ),
          ],
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
              child: const Icon(Icons.account_balance_rounded, color: AppColors.textLight, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              _selectedTab == 1 ? 'Belum Ada Favorit' : 'Rekening Tidak Ditemukan',
              style: AppTheme.font(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedTab == 1
                  ? 'Tandai rekening transfer dengan ikon bintang agar tersimpan di daftar favorit.'
                  : 'Coba periksa kembali kata kunci pencarian Anda.',
              textAlign: TextAlign.center,
              style: AppTheme.font(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2: PILIH BANK TUJUAN
// ─────────────────────────────────────────────────────────────────────────────

class SelectBankScreen extends StatefulWidget {
  const SelectBankScreen({super.key});

  @override
  State<SelectBankScreen> createState() => _SelectBankScreenState();
}

class _SelectBankScreenState extends State<SelectBankScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<BankInfo> _popularBanks = const [
    BankInfo(code: 'BCA', name: 'Bank Central Asia (BCA)', color: Color(0xFF005696)),
    BankInfo(code: 'MANDIRI', name: 'Bank Mandiri', color: Color(0xFF00387A)),
    BankInfo(code: 'BRI', name: 'Bank Rakyat Indonesia (BRI)', color: Color(0xFF00529C)),
    BankInfo(code: 'BNI', name: 'Bank Negara Indonesia (BNI)', color: Color(0xFFF15A24)),
    BankInfo(code: 'BSI', name: 'Bank Syariah Indonesia (BSI)', color: Color(0xFF00A39D)),
    BankInfo(code: 'CIMB', name: 'CIMB Niaga', color: Color(0xFFED1C24)),
    BankInfo(code: 'PERMATA', name: 'Permata Bank', color: Color(0xFF4A90E2)),
    BankInfo(code: 'JAGO', name: 'Bank Jago', color: Color(0xFFFF6900)),
    BankInfo(code: 'SEABANK', name: 'SeaBank Indonesia', color: Color(0xFFFF5722)),
    BankInfo(code: 'BTN', name: 'Bank Tabungan Negara (BTN)', color: Color(0xFF003366)),
    BankInfo(code: 'DANAMON', name: 'Bank Danamon', color: Color(0xFFFF9900)),
    BankInfo(code: 'BTPN', name: 'Bank BTPN / Jenius', color: Color(0xFF00A4E4)),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BankInfo> get _filteredBanks {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _popularBanks;
    return _popularBanks.where((b) {
      return b.name.toLowerCase().contains(q) || b.code.toLowerCase().contains(q);
    }).toList();
  }

  void _selectBank(BankInfo bank) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InputBankAccountScreen(bank: bank),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBanks;

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
          'Pilih Bank Tujuan',
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
            // Search Bar
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
                    hintText: 'Cari nama bank (BCA, Mandiri, BRI...)...',
                    hintStyle: AppTheme.font(fontSize: 13, color: AppColors.textLight),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    'Bank Populer & Rekomendasi',
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
                        indent: 68,
                        endIndent: 16,
                        color: AppColors.divider,
                      ),
                      itemBuilder: (context, index) {
                        final b = filtered[index];
                        return InkWell(
                          onTap: () => _selectBank(b),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: b.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(b.icon, color: b.color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    b.name,
                                    style: AppTheme.font(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
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
// STEP 3: CARD BANK + INPUT REKENING + STICKY BUTTON PERIKSA
// ─────────────────────────────────────────────────────────────────────────────

class InputBankAccountScreen extends StatefulWidget {
  final BankInfo bank;

  const InputBankAccountScreen({super.key, required this.bank});

  @override
  State<InputBankAccountScreen> createState() => _InputBankAccountScreenState();
}

class _InputBankAccountScreenState extends State<InputBankAccountScreen> {
  final TextEditingController _accountController = TextEditingController();
  bool _isChecking = false;

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _checkAccountAndProceed() async {
    final acc = _accountController.text.trim().replaceAll(' ', '');
    if (acc.length < 5) {
      AppToast.show(
        context,
        'Masukkan minimal 5 digit nomor rekening',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isChecking = true);

    // Simulasi inquiry rekening dari server
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isChecking = false);

    // Simulasi nama penerima terverifikasi
    final verifiedName = 'Hendra Pratama (${widget.bank.code})';

    final recipient = RecipientData(
      name: verifiedName,
      bankName: widget.bank.name,
      accountNumber: _accountController.text.trim(),
      avatarColor: widget.bank.color,
      icon: widget.bank.icon,
    );

    // Lanjut ke UI transfer nominal
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
          'Rekening Tujuan',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Card Nama Bank + Icon ─────────────────────────
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
                        color: widget.bank.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.bank.icon, color: widget.bank.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank Tujuan',
                            style: AppTheme.font(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.bank.name,
                            style: AppTheme.font(
                              fontSize: 14,
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

              // ── 2. Card Input Nomor Rekening ─────────────────────
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
                      'Nomor Rekening',
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
                        controller: _accountController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: AppTheme.font(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 1,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contoh: 88201928331',
                          hintStyle: AppTheme.font(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textLight,
                            letterSpacing: 0,
                          ),
                          prefixIcon: const Icon(Icons.credit_card_rounded, size: 20, color: AppColors.textSecondary),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.content_paste_rounded, size: 18, color: AppColors.primary),
                            tooltip: 'Tempel',
                            onPressed: () {
                              _accountController.text = '5410982310';
                              setState(() {});
                            },
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pastikan nomor rekening benar untuk memastikan nama pemilik rekening sesuai.',
                            style: AppTheme.font(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
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
      ),

      // ── 3. Sticky Bottom Button: Periksa ─────────────────────────
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
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: _isChecking ? null : _checkAccountAndProceed,
            child: _isChecking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Periksa Rekening',
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
