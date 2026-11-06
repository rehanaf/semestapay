import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import '../state/student_state.dart';
import 'transfer/transfer_screen.dart' show RecipientData;
import 'transfer/transfer_success_screen.dart';

enum BillStatus { unpaid, paid }

class BillItem {
  final String id;
  final String title;
  final String period;
  final String category;
  final int amount;
  final DateTime dueDate;
  BillStatus status;
  DateTime? paidAt;
  final List<String> breakdown;

  BillItem({
    required this.id,
    required this.title,
    required this.period,
    required this.category,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidAt,
    required this.breakdown,
  });

  bool get isPaid => status == BillStatus.paid;
}

class BillsPage extends StatefulWidget {
  final StudentState state;
  final VoidCallback? onBackToHome;

  const BillsPage({super.key, required this.state, this.onBackToHome});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  int _selectedTab = 0; // 0 = Belum Lunas, 1 = Riwayat Lunas

  String get _studentName => widget.state.student?.name ?? 'Santri';
  String get _nisn => widget.state.student?.nis ?? '-';
  String get _schoolName => 'Semestapay Mobile';
  String get _className => widget.state.student?.className ?? 'Santri';
  int? _balanceOverride;
  int get _balance =>
      _balanceOverride ?? (widget.state.student?.balance ?? 0).round();

  List<BillItem> get _bills {
    return (widget.state.dashboard?.bills ?? []).map((b) {
      final due = DateTime.tryParse(b.dueDate ?? '') ?? DateTime.now();
      return BillItem(
        id: 'BILL-${b.id}',
        title: b.description?.isNotEmpty == true
            ? b.description!
            : '${b.type.toUpperCase()} ${b.period ?? ''}'.trim(),
        period: b.period ?? '-',
        category: b.type,
        amount: b.amount.round(),
        dueDate: due,
        status: b.isPaid ? BillStatus.paid : BillStatus.unpaid,
        paidAt: b.isPaid ? due : null,
        breakdown: [
          'Tagihan: ${widget.state.formatCurrency(b.amount)}',
          'Dibayar: ${widget.state.formatCurrency(b.paidAmount)}',
        ],
      );
    }).toList();
  }

  List<BillItem> get _unpaidBills => _bills.where((b) => !b.isPaid).toList();
  List<BillItem> get _paidBills => _bills.where((b) => b.isPaid).toList();

  String _formatCurrency(int amount) {
    final str = amount.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  String _monthName(int m) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[m];
  }

  // ── Modal Konfirmasi Pembayaran SPP ──────────────────────────────────────────
  void _openPayModal(BillItem bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayConfirmationSheet(
        bill: bill,
        balance: _balance,
        studentName: _studentName,
        nisn: _nisn,
        schoolName: _schoolName,
        className: _className,
        onConfirmPay: () => _executePayment(bill),
      ),
    );
  }

  // ── Eksekusi Pembayaran ─────────────────────────────────────────────────────
  Future<void> _executePayment(BillItem bill) async {
    // Tutup bottom sheet & tunggu frame berikutnya agar overlay bersih
    Navigator.pop(context);
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Memproses Pembayaran...',
                style: AppTheme.font(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Menghubungkan ke sistem keuangan sekolah',
                textAlign: TextAlign.center,
                style: AppTheme.font(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.pop(context); // Tutup loading dialog

    // Update status tagihan menjadi LUNAS & kurangi saldo
    if (mounted) {
      setState(() {
        bill.status = BillStatus.paid;
        bill.paidAt = DateTime.now();
        _balanceOverride = _balance - bill.amount;
      });
    }

    // Tunggu satu frame agar dialog benar-benar hilang sebelum tampilkan toast & navigasi
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    AppToast.show(
      context,
      'Pembayaran ${bill.title} Berhasil!',
      type: ToastType.success,
    );

    // Simpan data sebelum navigasi
    final billTitle = bill.title;
    final billPeriod = bill.period;
    final billAmount = bill.amount;

    if (!mounted) return;

    // Buka Halaman Bukti Transaksi
    final recipient = RecipientData(
      name: 'Bendahara SMAN 1 Jakarta',
      bankName: 'Sistem Pembayaran Sekolah',
      accountNumber: 'NISN: $_nisn ($billPeriod)',
      avatarColor: AppColors.primary,
      icon: Icons.school_rounded,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferSuccessScreen(
          recipient: recipient,
          amount: _formatCurrency(billAmount),
          note: 'Pelunasan $billTitle - $_studentName ($_className)',
        ),
      ),
    );
  }

  // ── Lihat Struk Tagihan Lunas ───────────────────────────────────────────────
  void _viewReceipt(BillItem bill) {
    final recipient = RecipientData(
      name: 'Bendahara SMAN 1 Jakarta',
      bankName: 'Sistem Pembayaran Sekolah',
      accountNumber: 'NISN: $_nisn (${bill.period})',
      avatarColor: AppColors.primary,
      icon: Icons.school_rounded,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferSuccessScreen(
          recipient: recipient,
          amount: _formatCurrency(bill.amount),
          note: 'Pelunasan ${bill.title} - $_studentName ($_className)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unpaid = _unpaidBills;
    final paid = _paidBills;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: widget.onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.textPrimary),
                onPressed: widget.onBackToHome,
              )
            : null,
        title: Text(
          'Tagihan Sekolah',
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
            // Segmented Capsule Tab Control
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                height: 42,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Belum Lunas (${unpaid.length})'),
                    _buildTabButton(1, 'Riwayat Lunas (${paid.length})'),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  // 1. Info Card Siswa & Sekolah
                  _buildStudentInfoCard(),
                  const SizedBox(height: 16),

                  // 2. Daftar Tagihan sesuai tab
                  if (_selectedTab == 0) ...[
                    if (unpaid.isEmpty)
                      _buildAllClearCard()
                    else ...[
                      Text(
                        'Tagihan Perlu Dibayar',
                        style: AppTheme.font(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...unpaid.map((item) => _buildUnpaidBillCard(item)),
                    ],
                  ] else ...[
                    Text(
                      'Riwayat Pembayaran Lunas',
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...paid.map((item) => _buildPaidBillCard(item)),
                  ],
                ],
              ),
            ),
          ],
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

  // ─── Info Card Siswa ─────────────────────────────────────────────────────────

  Widget _buildStudentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _studentName,
                      style: AppTheme.font(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_schoolName • $_className',
                      style: AppTheme.font(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'NISN: $_nisn',
                      style: AppTheme.font(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // Saldo Dompet Semestapay
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'Saldo Semestapay:',
                    style: AppTheme.font(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Text(
                'Rp ${_formatCurrency(_balance)}',
                style: AppTheme.font(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Card Tagihan Belum Lunas (gaya promo card dari home) ──────────────────

  Widget _buildUnpaidBillCard(BillItem item) {
    final dueStr = '${item.dueDate.day} ${_monthName(item.dueDate.month)} ${item.dueDate.year}';
    final isUrgent = item.dueDate.month == 11; // November bulan berjalan
    final accentColor = isUrgent ? const Color(0xFFE65100) : AppColors.primary;

    return GestureDetector(
      onTap: () => _openPayModal(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isUrgent
              ? Border.all(color: const Color(0xFFFFB300), width: 1.5)
              : null,
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
            // Icon box (gaya promo card)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.receipt_long_rounded, color: accentColor, size: 24),
            ),
            const SizedBox(width: 14),

            // Konten tengah
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris judul + badge status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
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
                      // Badge: Belum Lunas / Mendesak
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? const Color(0xFFFFF3E0)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isUrgent ? 'Mendesak' : 'Belum Lunas',
                          style: AppTheme.font(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isUrgent ? const Color(0xFFE65100) : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Nominal + jatuh tempo
                  Text(
                    'Rp ${_formatCurrency(item.amount)}  •  Jatuh tempo $dueStr',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Tombol Bayar Sekarang inline kecil
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payment_rounded, size: 12, color: accentColor),
                          const SizedBox(width: 4),
                          Text(
                            'Bayar Sekarang',
                            style: AppTheme.font(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
          ],
        ),
      ),
    );
  }

  // ─── Card Tagihan Lunas ─────────────────────────────────────────────────────

  Widget _buildPaidBillCard(BillItem item) {
    final paidStr = item.paidAt != null
        ? '${item.paidAt!.day} ${_monthName(item.paidAt!.month)} ${item.paidAt!.year}, ${_pad(item.paidAt!.hour)}:${_pad(item.paidAt!.minute)} WIB'
        : 'Lunas';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.category,
                style: AppTheme.font(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'LUNAS',
                      style: AppTheme.font(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            item.title,
            style: AppTheme.font(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Dibayar pada: $paidStr',
            style: AppTheme.font(fontSize: 11, color: AppColors.textLight),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rp ${_formatCurrency(item.amount)}',
                style: AppTheme.font(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => _viewReceipt(item),
                child: Row(
                  children: [
                    Text(
                      'Lihat Bukti Resi',
                      style: AppTheme.font(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllClearCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F7F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.accent, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            'Semua Tagihan Lunas!',
            style: AppTheme.font(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak ada tagihan tertunda untuk akun siswa kamu.',
            textAlign: TextAlign.center,
            style: AppTheme.font(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL BOTTOM SHEET KONFIRMASI BAYAR SPP
// ─────────────────────────────────────────────────────────────────────────────

class _PayConfirmationSheet extends StatelessWidget {
  final BillItem bill;
  final int balance;
  final String studentName;
  final String nisn;
  final String schoolName;
  final String className;
  final VoidCallback onConfirmPay;

  const _PayConfirmationSheet({
    required this.bill,
    required this.balance,
    required this.studentName,
    required this.nisn,
    required this.schoolName,
    required this.className,
    required this.onConfirmPay,
  });

  String _formatCurrency(int amount) {
    final str = amount.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isBalanceSufficient = balance >= bill.amount;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 20),
      child: SingleChildScrollView(
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
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konfirmasi Pembayaran SPP',
                        style: AppTheme.font(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        bill.period,
                        style: AppTheme.font(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 14),

            // Card Siswa
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Nama Siswa', studentName),
                  const SizedBox(height: 4),
                  _row('NISN / Kelas', '$nisn • $className'),
                  const SizedBox(height: 4),
                  _row('Sekolah', schoolName),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Rincian Biaya
            Text(
              'Rincian Biaya Tagihan',
              style: AppTheme.font(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _row('SPP Rutin Sekolah', 'Rp 350.000'),
            const SizedBox(height: 6),
            _row('Praktikum & Laboratorium', 'Rp 100.000'),
            const SizedBox(height: 6),
            _row('Biaya Layanan Semestapay', 'Gratis (Rp 0)', color: AppColors.accent),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),

            // Total Tagihan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran',
                  style: AppTheme.font(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Rp ${_formatCurrency(bill.amount)}',
                  style: AppTheme.font(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sumber Dana
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isBalanceSufficient ? const Color(0xFFE6F7F0) : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isBalanceSufficient ? Icons.check_circle_rounded : Icons.warning_rounded,
                    color: isBalanceSufficient ? AppColors.accent : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sumber Dana: Saldo Semestapay',
                          style: AppTheme.font(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isBalanceSufficient ? AppColors.accent : AppColors.error,
                          ),
                        ),
                        Text(
                          'Tersedia: Rp ${_formatCurrency(balance)}',
                          style: AppTheme.font(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tombol Konfirmasi Bayar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBalanceSufficient ? AppColors.primary : const Color(0xFFD3D8E8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: isBalanceSufficient ? onConfirmPay : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Konfirmasi & Bayar Sekarang',
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
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.font(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTheme.font(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
