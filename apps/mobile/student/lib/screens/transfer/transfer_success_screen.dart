import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'transfer_screen.dart';

class TransferSuccessScreen extends StatefulWidget {
  final RecipientData recipient;
  final String amount;
  final String note;
  final String? transactionId;
  final String? transactionAt;
  final VoidCallback? onBackToHome;

  const TransferSuccessScreen({
    super.key,
    required this.recipient,
    required this.amount,
    required this.note,
    this.transactionId,
    this.transactionAt,
    this.onBackToHome,
  });

  @override
  State<TransferSuccessScreen> createState() => _TransferSuccessScreenState();
}

class _TransferSuccessScreenState extends State<TransferSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;
  late final Animation<double> _contentFade;

  bool _detailExpanded = false;

  late final String _trxId;
  late final String _trxTime;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _trxId =
        widget.transactionId ??
        'TRX-${now.millisecondsSinceEpoch.toString().substring(4)}';
    final transactionDate = DateTime.tryParse(
      widget.transactionAt ?? '',
    )?.toLocal();
    final displayDate = transactionDate ?? now;
    _trxTime =
        '${_pad(displayDate.day)} ${_monthName(displayDate.month)} ${displayDate.year}, ${_pad(displayDate.hour)}:${_pad(displayDate.minute)} WIB';

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _checkScale = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
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

  String _pad(int v) => v.toString().padLeft(2, '0');

  String _monthName(int m) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[m];
  }

  void _handleDone() {
    if (widget.onBackToHome != null) widget.onBackToHome!();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _copyTrxId() {
    Clipboard.setData(ClipboardData(text: _trxId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ID Transaksi disalin',
          style: AppTheme.font(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
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
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: AppColors.textPrimary,
          ),
          onPressed: _handleDone,
        ),
        title: Text(
          'Bukti Transaksi',
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
                      // ── Checkmark ────────────────────────────────────────
                      ScaleTransition(
                        scale: _checkScale,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7F0),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.22),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.accent,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Judul ──────────────────────────────────────────────
                      Text(
                        'Transaksi Berhasil!',
                        style: AppTheme.font(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ── ID Transaksi (tap to copy) ──────────────────────────
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

                      // ── Nominal ──────────────────────────────────────────────
                      Text(
                        'Rp ${widget.amount}',
                        style: AppTheme.font(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Card Penerima ─────────────────────────────────────
                      _buildRecipientCard(),
                      const SizedBox(height: 12),

                      // ── Accordion Detail ──────────────────────────────────
                      _buildDetailAccordion(),
                    ],
                  ),
                ),
              ),
            ),

            // ── Tombol Bawah ──────────────────────────────────────────────
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
          // Icon bank / e-wallet
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipient.name,
                  style: AppTheme.font(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.recipient.bankName,
                  style: AppTheme.font(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.recipient.accountNumber,
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
          // Badge sukses
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Sukses',
              style: AppTheme.font(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Accordion Detail Transaksi ───────────────────────────────────────────────

  Widget _buildDetailAccordion() {
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
          // Header
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
                      color: const Color(0xFFE6F7F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.accent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Detail Transaksi',
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

          // Konten
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
                  _row('Sumber Dana', 'Semestapay (3210 4821 9012)'),
                  _divRow(),
                  _row('Nama Penerima', widget.recipient.name, isBold: true),
                  _divRow(),
                  _row('Bank / E-Wallet', widget.recipient.bankName),
                  _divRow(),
                  _row('No. Rekening', widget.recipient.accountNumber),
                  if (widget.note.isNotEmpty) ...[
                    _divRow(),
                    _row('Catatan', widget.note),
                  ],
                  _divRow(),
                  _row(
                    'Biaya Admin',
                    'Gratis (Rp 0)',
                    valueColor: AppColors.accent,
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Transaksi',
                        style: AppTheme.font(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Rp ${widget.amount}',
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

  Widget _row(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.font(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTheme.font(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _handleDone,
                child: Text(
                  'Selesai',
                  style: AppTheme.font(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.share_outlined, size: 17),
                label: Text(
                  'Bagikan Bukti Transaksi',
                  style: AppTheme.font(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bukti transaksi berhasil disalin & siap dibagikan',
                        style: AppTheme.font(fontSize: 13, color: Colors.white),
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
