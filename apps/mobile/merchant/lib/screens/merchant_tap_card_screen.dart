import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import '../state/pos_state.dart';
import 'merchant_card_pin_screen.dart';

// ─── Model Data Siswa ─────────────────────────────────────────────────────────

class StudentCardData {
  final String name;
  final int balance;
  final String cardNumber;
  final String schoolClass;

  const StudentCardData({
    required this.name,
    required this.balance,
    required this.cardNumber,
    required this.schoolClass,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class MerchantTapCardScreen extends StatefulWidget {
  final PosState posState;
  final String amount;
  final int rawAmount;
  final String note;
  final bool isCashOut;

  const MerchantTapCardScreen({
    super.key,
    required this.posState,
    required this.amount,
    required this.rawAmount,
    required this.note,
    this.isCashOut = false,
  });

  @override
  State<MerchantTapCardScreen> createState() => _MerchantTapCardScreenState();
}

class _MerchantTapCardScreenState extends State<MerchantTapCardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rippleController;
  late final AnimationController _tapController;
  late final Animation<double> _glowAnim;

  late final FocusNode _rfidFocusNode;
  late final TextEditingController _rfidController;

  bool _isTapping = false;
  bool _tapDone = false;
  bool _tapFailed = false;

  StudentCardData? _studentData;

  StudentCardData get _fallbackStudentData => const StudentCardData(
        name: 'Santri',
        balance: 0,
        cardNumber: '-',
        schoolClass: '-',
      );

  @override
  void initState() {
    super.initState();

    _rfidFocusNode = FocusNode();
    _rfidController = TextEditingController();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _tapController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // RFID reader listens via hardware keyboard; no auto-focus to avoid
    // the software keyboard popping up on screen load.
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _tapController.dispose();
    _rfidFocusNode.dispose();
    _rfidController.dispose();
    super.dispose();
  }

  // ── Pemrosesan Tap Kartu (RFID reader / simulasi) ──────────────────────────

  Future<void> _processCardTap(String uid) async {
    if (_isTapping) return;
    setState(() {
      _isTapping = true;
      _tapFailed = false;
      _tapDone = false;
    });

    try {
      final card = await widget.posState.api.readCard(uid);
      if (!card.isUsable) {
        throw Exception('Kartu santri tidak aktif atau diblokir.');
      }
      widget.posState.setScannedCard(card);
      _studentData = StudentCardData(
        name: card.student.name,
        balance: card.wallet.balance.round(),
        cardNumber: card.card.uid,
        schoolClass: card.student.className ?? 'Santri',
      );

      if (!mounted) return;
      await _tapController.forward();
      setState(() => _tapDone = true);

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      _showStudentBottomSheet(success: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTapping = false;
        _tapFailed = true;
        _tapDone = false;
      });
      _tapController.reset();
      _showStudentBottomSheet(success: false);
    }
  }

  Future<void> _simulateTapSuccess() async {
    await _processCardTap('DEMO-UID-0001');
  }

  // ── Bottom Sheet ─────────────────────────────────────────────────────────────

  void _showStudentBottomSheet({required bool success}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TapResultBottomSheet(
        success: success,
        studentData: _studentData ?? _fallbackStudentData,
        rawAmount: widget.rawAmount,
        amount: widget.amount,
        isCashOut: widget.isCashOut,
        onProceed: _proceedToPin,
        onRetry: () {
          Navigator.pop(context);
          _resetState();
        },
        onCancel: () {
          Navigator.pop(context); // tutup sheet
          Navigator.pop(context); // balik ke transaksi screen
        },
      ),
    ).then((_) {
      // Ketika bottom sheet ditutup, kembali ke status ready to tap
      if (mounted) {
        _resetState();
      }
    });
  }

  void _resetState() {
    _tapController.reset();
    setState(() {
      _isTapping = false;
      _tapDone = false;
      _tapFailed = false;
    });
    _rfidController.clear();
    // _rfidFocusNode.requestFocus(); // intentionally not auto-focusing to keep keyboard hidden
  }

  void _proceedToPin() {
    Navigator.pop(context); // tutup bottom sheet
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantCardPinScreen(
          posState: widget.posState,
          amount: widget.amount,
          rawAmount: widget.rawAmount,
          note: widget.note,
          studentData: _studentData ?? _fallbackStudentData,
          isCashOut: widget.isCashOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
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
            'Tap Kartu',
            style: AppTheme.font(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          actions: const [SizedBox(width: 48)],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // Hidden RFID/HID input field (always active)
              Opacity(
                opacity: 0.0,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    controller: _rfidController,
                    focusNode: _rfidFocusNode,
                    autofocus: false,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      final uid = value.trim();
                      _rfidController.clear();
                      if (uid.isNotEmpty) {
                        _processCardTap(uid);
                      }
                    },
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStoreCard(),
                    const SizedBox(height: 12),
                    _buildTagihanCard(),
                    const SizedBox(height: 32),

                    // NFC Area
                    _buildNfcArea(),
                    const SizedBox(height: 20),

                    // Instruksi
                    _buildInstruction(),
                    const SizedBox(height: 32),

                    // Tombol Simulasi (hanya simulasi berhasil)
                    if (!_isTapping && !_tapDone) ...[
                      _buildSimulateButton(
                        label: 'Simulasi Tap Berhasil',
                        icon: Icons.wifi_rounded,
                        color: AppColors.merchantPrimary,
                        onTap: _simulateTapSuccess,
                      ),
                    ],

                    // Loading saat tapping
                    if (_isTapping && !_tapDone && !_tapFailed)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(
                            color: AppColors.merchantPrimary,
                            strokeWidth: 3,
                          ),
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

  // ─── Card Toko ──────────────────────────────────────────────────────────────

  Widget _buildStoreCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.merchantLightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded,
                color: AppColors.merchantPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.posState.merchantSummary?.name ??
                      widget.posState.outletName,
                  style: AppTheme.font(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Outlet: ${widget.posState.outletName} • ${widget.posState.outletCode}',
                  style: AppTheme.font(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card Tagihan ────────────────────────────────────────────────────────────

  Widget _buildTagihanCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isCashOut ? 'Total Kas Keluar' : 'Total Tagihan',
                  style: AppTheme.font(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rp ${widget.amount}',
                  style: AppTheme.font(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.merchantLightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isCashOut
                      ? Icons.payments_outlined
                      : Icons.contactless_rounded,
                  size: 14,
                  color: AppColors.merchantPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isCashOut ? 'Kas Keluar' : 'Kas Masuk',
                  style: AppTheme.font(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.merchantPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── NFC Area ────────────────────────────────────────────────────────────────

  Widget _buildNfcArea() {
    final isDone = _tapDone;
    final isError = _tapFailed;

    return Center(
      child: AnimatedBuilder(
        animation: _rippleController,
        builder: (context, _) {
          return SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ripple 3
                if (!isDone && !isError)
                  _buildRipple(
                    size: 220,
                    progress: (_rippleController.value + 0.66) % 1.0,
                  ),
                // Ripple 2
                if (!isDone && !isError)
                  _buildRipple(
                    size: 170,
                    progress: (_rippleController.value + 0.33) % 1.0,
                  ),
                // Ripple 1
                if (!isDone && !isError)
                  _buildRipple(
                    size: 120,
                    progress: _rippleController.value,
                  ),

                // Glow saat sukses
                if (isDone)
                  FadeTransition(
                    opacity: _glowAnim,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.merchantPrimary.withValues(alpha: 0.2),
                      ),
                    ),
                  ),

                // Lingkaran utama
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isError
                            ? AppColors.error.withValues(alpha: 0.3)
                            : isDone
                                ? AppColors.merchantPrimary.withValues(alpha: 0.35)
                                : AppColors.merchantPrimary.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isError
                        ? AppColors.error.withValues(alpha: 0.15)
                        : isDone
                            ? AppColors.merchantPrimary
                            : AppColors.merchantLightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError
                        ? Icons.wifi_off_rounded
                        : isDone
                            ? Icons.check_rounded
                            : Icons.wifi_rounded,
                    color: isError
                        ? AppColors.error
                        : isDone
                            ? Colors.white
                            : AppColors.merchantPrimary,
                    size: 32,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRipple({required double size, required double progress}) {
    final opacity = (1.0 - progress).clamp(0.0, 0.4);
    final scale = 0.5 + (progress * 0.5);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.merchantPrimary.withValues(alpha: opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ─── Instruksi ───────────────────────────────────────────────────────────────

  Widget _buildInstruction() {
    return Column(
      children: [
        Text(
          _tapFailed
              ? 'Kartu Tidak Terbaca'
              : _tapDone
                  ? 'Kartu Berhasil Terbaca!'
                  : 'Tempelkan Kartu Siswa',
          style: AppTheme.font(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _tapFailed
                ? AppColors.error
                : _tapDone
                    ? AppColors.merchantPrimary
                    : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _tapFailed
              ? 'Pastikan posisi kartu tepat atau coba lagi'
              : _tapDone
                  ? 'Memverifikasi data siswa...'
                  : 'Gunakan reader RFID USB atau tap NFC di perangkat',
          style: AppTheme.font(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── Tombol Simulasi ─────────────────────────────────────────────────────────

  Widget _buildSimulateButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(
          label,
          style: AppTheme.font(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          shadowColor: color.withValues(alpha: 0.3),
        ),
        onPressed: onTap,
      ),
    );
  }
}

// ─── Bottom Sheet Hasil Tap ───────────────────────────────────────────────────

class _TapResultBottomSheet extends StatelessWidget {
  final bool success;
  final StudentCardData studentData;
  final int rawAmount;
  final String amount;
  final bool isCashOut;
  final VoidCallback onProceed;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const _TapResultBottomSheet({
    required this.success,
    required this.studentData,
    required this.rawAmount,
    required this.amount,
    required this.isCashOut,
    required this.onProceed,
    required this.onRetry,
    required this.onCancel,
  });

  String _formatRupiah(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: success ? _buildSuccess(context) : _buildFailed(context),
    );
  }

  // ── Konten Berhasil ──────────────────────────────────────────────────────────

  Widget _buildSuccess(BuildContext context) {
    final saldo = studentData.balance;
    final postBalance = isCashOut ? (saldo + rawAmount) : (saldo - rawAmount);
    final cukup = isCashOut ? true : (saldo >= rawAmount);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        _handle(),
        const SizedBox(height: 16),

        // Header Siswa
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.merchantLightGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded,
                  color: AppColors.merchantPrimary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentData.name,
                    style: AppTheme.font(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kelas ${studentData.schoolClass} • UID: ${studentData.cardNumber}',
                    style: AppTheme.font(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 16),

        // Saldo & Tagihan/Kas Keluar
        Row(
          children: [
            Expanded(
              child: _infoItem(
                label: 'Sisa Saldo Saat Ini',
                value: 'Rp ${_formatRupiah(saldo)}',
                valueColor: cukup ? AppColors.merchantPrimary : AppColors.error,
              ),
            ),
            Container(width: 1, height: 40, color: AppColors.divider),
            const SizedBox(width: 16),
            Expanded(
              child: _infoItem(
                label: isCashOut ? 'Nominal Kas Keluar' : 'Nominal Tagihan',
                value: 'Rp $amount',
                valueColor: AppColors.textPrimary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Estimasi Sisa Saldo Setelah Transaksi
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo Setelah Transaksi:',
                style: AppTheme.font(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Rp ${_formatRupiah(postBalance < 0 ? 0 : postBalance)}',
                style: AppTheme.font(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: postBalance >= 0 ? AppColors.merchantPrimary : AppColors.error,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Tombol Lanjut
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cukup
                  ? AppColors.merchantPrimary
                  : const Color(0xFFD3D8E8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: cukup ? onProceed : null,
            child: Text(
              'Lanjutkan',
              style: AppTheme.font(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),

        if (!cukup) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onCancel,
              child: Text(
                'Batalkan Transaksi',
                style: AppTheme.font(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Konten Gagal ─────────────────────────────────────────────────────────────

  Widget _buildFailed(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _handle(),
        const SizedBox(height: 20),

        // Icon error
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.error,
            size: 32,
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Kartu Tidak Terbaca',
          style: AppTheme.font(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),

        Text(
          'Kartu siswa tidak dapat dideteksi atau tidak aktif.\nPastikan kartu dalam kondisi baik dan coba tempelkan kembali.',
          style: AppTheme.font(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
            label: Text(
              'Coba Lagi',
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
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onRetry,
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onCancel,
            child: Text(
              'Batalkan',
              style: AppTheme.font(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper ───────────────────────────────────────────────────────────────────

  Widget _handle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _infoItem({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.font(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.font(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: valueColor,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
