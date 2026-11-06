import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import '../state/pos_state.dart';
import 'merchant_tap_card_screen.dart' show StudentCardData;
import 'merchant_transaction_screen.dart';

class MerchantSuccessScreen extends StatefulWidget {
  final PosState posState;
  final String amount;
  final int rawAmount;
  final String note;
  final StudentCardData studentData;
  final String? transactionId;
  final String? status;
  final String? createdAt;
  final bool isCashOut;
  final double? studentBalanceAfter;
  final double? merchantBalanceAfter;
  // fromHistory: kalau true, hanya tampilkan tombol "Ke Beranda"
  final bool fromHistory;

  const MerchantSuccessScreen({
    super.key,
    required this.posState,
    required this.amount,
    required this.rawAmount,
    required this.note,
    required this.studentData,
    this.transactionId,
    this.status,
    this.createdAt,
    this.isCashOut = false,
    this.studentBalanceAfter,
    this.merchantBalanceAfter,
    this.fromHistory = false,
  });

  @override
  State<MerchantSuccessScreen> createState() => _MerchantSuccessScreenState();
}

class _MerchantSuccessScreenState extends State<MerchantSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;
  late final Animation<double> _contentFade;

  bool _detailExpanded = true;

  late final String _trxId;
  late final String _trxTime;

  @override
  void initState() {
    super.initState();

    final now = DateTime.tryParse(widget.createdAt ?? '')?.toLocal() ??
        DateTime.now();

    // No. Ref yang mudah dibaca: format waktu YYYYMMDD-HHMMSS
    _trxId = widget.transactionId ??
        'TRX-${DateFormat('yyyyMMdd-HHmmss').format(now)}';
    _trxTime = '${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(now)} WIB';

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _checkScale = CurvedAnimation(
        parent: _checkController, curve: Curves.elasticOut);
    _contentFade = CurvedAnimation(
      parent: _checkController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
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

  void _onSelesai() {
    widget.posState.resetTransaction();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onNewTransaction() {
    final isCashOut = widget.isCashOut;
    final posState = widget.posState;
    posState.resetTransaction();
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MerchantTransactionScreen(
          posState: posState,
          isCashOut: isCashOut,
        ),
      ),
    );
  }

  void _copyTrxId() {
    Clipboard.setData(ClipboardData(text: _trxId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No. Referensi disalin',
          style: AppTheme.font(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AppColors.merchantPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.merchantBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded,
              size: 26, color: AppColors.textPrimary),
          onPressed: _onSelesai,
        ),
        title: Text(
          'Transaksi Berhasil',
          style: AppTheme.font(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: FadeTransition(
                  opacity: _contentFade,
                  child: Column(
                    children: [
                      // ── Checkmark ──────────────────────────────────────────
                      ScaleTransition(
                        scale: _checkScale,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppColors.merchantLightGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.merchantPrimary
                                    .withValues(alpha: 0.22),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.merchantPrimary,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Judul selalu "Transaksi Berhasil!" ─────────────────
                      Text(
                        'Transaksi Berhasil!',
                        style: AppTheme.font(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ── No. Referensi (tap to copy) ────────────────────────
                      GestureDetector(
                        onTap: _copyTrxId,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _trxId,
                              style: AppTheme.font(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Nominal (tanpa double Rp) ───────────────────────────
                      Text(
                        'Rp ${_formatRupiah(widget.rawAmount)}',
                        style: AppTheme.font(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Card Siswa ─────────────────────────────────────────
                      _buildRecipientCard(),
                      const SizedBox(height: 12),

                      // ── Detail Transaksi Accordion ─────────────────────────
                      _buildDetailAccordion(),
                    ],
                  ),
                ),
              ),
            ),

            // ── Tombol Bawah ───────────────────────────────────────────────
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  // ─── Card Penerima ────────────────────────────────────────────────────────────

  Widget _buildRecipientCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
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
              color: AppColors.merchantLightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.merchantPrimary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentData.name,
                  style: AppTheme.font(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kelas ${widget.studentData.schoolClass}',
                  style: AppTheme.font(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.studentData.cardNumber,
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.merchantLightGreen,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.isCashOut ? 'Kas Keluar' : 'Kas Masuk',
              style: AppTheme.font(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.merchantPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Accordion Detail Transaksi ───────────────────────────────────────────────

  Widget _buildDetailAccordion() {
    final outletDisplayName = widget.posState.merchantSummary?.name ??
        widget.posState.outletName;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _detailExpanded = !_detailExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.merchantLightGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.merchantPrimary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Detail Transaksi & Saldo',
                    style: AppTheme.font(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _detailExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _detailExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 14),
                  _row('Waktu Transaksi', _trxTime),
                  _divRow(),
                  _row('No. Referensi', _trxId),
                  _divRow(),
                  _row(
                    'Jenis Transaksi',
                    widget.isCashOut ? 'Kas Keluar' : 'Kas Masuk',
                  ),
                  _divRow(),
                  _row('Outlet Kasir', outletDisplayName),
                  _divRow(),
                  _row('Kode Outlet', widget.posState.outletCode),
                  if (widget.note.isNotEmpty) ...[
                    _divRow(),
                    _row('Catatan', widget.note),
                  ],
                  if (widget.studentBalanceAfter != null) ...[
                    _divRow(),
                    _row(
                      'Sisa Saldo Santri',
                      'Rp ${_formatRupiah(widget.studentBalanceAfter!.round())}',
                      valueColor: AppColors.merchantPrimary,
                    ),
                  ],
                  if (widget.merchantBalanceAfter != null) ...[
                    _divRow(),
                    _row(
                      'Saldo Merchant Saat Ini',
                      'Rp ${_formatRupiah(widget.merchantBalanceAfter!.round())}',
                      valueColor: AppColors.merchantPrimary,
                    ),
                  ],
                  _divRow(),
                  _row('Biaya Layanan', 'Gratis (Rp 0)',
                      valueColor: AppColors.merchantPrimary),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isCashOut
                            ? 'Total Kas Keluar'
                            : 'Total Kas Masuk',
                        style: AppTheme.font(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Rp ${_formatRupiah(widget.rawAmount)}',
                        style: AppTheme.font(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.font(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTheme.font(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divRow() => const SizedBox(height: 2);

  // ─── Tombol Bawah ─────────────────────────────────────────────────────────────

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tombol Ke Beranda (selalu ada)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.home_rounded,
                    size: 20, color: Colors.white),
                label: Text(
                  'Ke Beranda',
                  style: AppTheme.font(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.merchantPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _onSelesai,
              ),
            ),

            // Tombol tambahan hanya jika BUKAN dari riwayat
            if (!widget.fromHistory) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        widget.isCashOut
                            ? Icons.payments_outlined
                            : Icons.add_card_rounded,
                        size: 16,
                        color: AppColors.merchantPrimary,
                      ),
                      label: Text(
                        widget.isCashOut
                            ? 'Kas Keluar Baru'
                            : 'Kas Masuk Baru',
                        style: AppTheme.font(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.merchantPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(
                            color: AppColors.merchantPrimary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _onNewTransaction,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
