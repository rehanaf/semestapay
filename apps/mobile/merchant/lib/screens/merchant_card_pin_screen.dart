import 'package:flutter/material.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import 'package:uuid/uuid.dart';
import '../state/pos_state.dart';
import 'merchant_success_screen.dart';
import 'merchant_tap_card_screen.dart' show StudentCardData;

class MerchantCardPinScreen extends StatefulWidget {
  final PosState posState;
  final String amount;
  final int rawAmount;
  final String note;
  final StudentCardData studentData;
  final bool isCashOut;

  const MerchantCardPinScreen({
    super.key,
    required this.posState,
    required this.amount,
    required this.rawAmount,
    required this.note,
    required this.studentData,
    this.isCashOut = false,
  });

  @override
  State<MerchantCardPinScreen> createState() => _MerchantCardPinScreenState();
}

class _MerchantCardPinScreenState extends State<MerchantCardPinScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isProcessing = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onPinKey(String digit) {
    if (_pin.length >= 6 || _isProcessing) return;
    setState(() => _pin += digit);
    if (_pin.length == 6) _processPin();
  }

  void _onBackspace() {
    if (_pin.isEmpty || _isProcessing) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _processPin() async {
    if (_pin.length < 6) {
      _shakeController.forward(from: 0);
      AppToast.show(
        context,
        'Masukkan 6 digit PIN kartu santri.',
        type: ToastType.warning,
      );
      return;
    }

    final card = widget.posState.scannedCard;
    if (card == null) {
      AppToast.show(
        context,
        'Data kartu belum terbaca. Ulangi tap kartu.',
        type: ToastType.error,
      );
      return;
    }

    final total = widget.posState.grandTotal;

    if (widget.isCashOut) {
      final merchantBal = widget.posState.merchantSummary?.balance;
      if (merchantBal != null && merchantBal < total) {
        _shakeController.forward(from: 0);
        AppToast.show(
          context,
          'Saldo merchant tidak mencukupi untuk kas keluar.',
          type: ToastType.error,
        );
        return;
      }
    } else {
      if (card.wallet.balance < total) {
        _shakeController.forward(from: 0);
        AppToast.show(
          context,
          'Saldo santri tidak mencukupi.',
          type: ToastType.error,
        );
        return;
      }
      if (card.dailyLimit > 0 && total > card.remainingDailyLimit) {
        _shakeController.forward(from: 0);
        AppToast.show(
          context,
          'Melebihi limit harian santri (${widget.posState.formatCurrency(card.remainingDailyLimit)}).',
          type: ToastType.error,
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      if (widget.isCashOut) {
        final res = await widget.posState.api.cashOut(
          cardUid: card.card.uid,
          amount: total,
          pin: _pin,
          note: widget.note.isNotEmpty ? widget.note : 'Kas keluar merchant',
          outletCode: widget.posState.outletCode,
          idempotencyKey: const Uuid().v4(),
        );

        if (!mounted) return;
        await widget.posState.refreshMerchantSummary().catchError((_) {});
        widget.posState.resetTransaction();

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MerchantSuccessScreen(
              posState: widget.posState,
              amount: widget.posState.formatCurrency(res.amount),
              rawAmount: res.amount.round(),
              note: widget.note.isNotEmpty ? widget.note : 'Kas keluar',
              studentData: widget.studentData,
              transactionId: 'TX-${res.transactionId}',
              status: 'SUCCESS',
              createdAt: DateTime.now().toIso8601String(),
              isCashOut: true,
              studentBalanceAfter: res.balanceAfter,
              merchantBalanceAfter: res.merchantBalanceAfter,
            ),
          ),
        );
      } else {
        final res = await widget.posState.api.tapPayment(
          TapPaymentRequest(
            cardUid: card.card.uid,
            outletCode: widget.posState.outletCode,
            amount: total,
            idempotencyKey: const Uuid().v4(),
            note: widget.note.isNotEmpty ? widget.note : null,
            pin: _pin,
          ),
        );

        if (!mounted) return;
        await widget.posState.refreshMerchantSummary().catchError((_) {});
        widget.posState.resetTransaction();

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MerchantSuccessScreen(
              posState: widget.posState,
              amount: widget.posState.formatCurrency(res.amount),
              rawAmount: res.amount.round(),
              note: res.note ?? widget.note,
              studentData: widget.studentData,
              transactionId: res.invoiceNumber,
              status: res.status,
              createdAt: res.createdAt,
              isCashOut: false,
              studentBalanceAfter: res.balanceAfter,
              merchantBalanceAfter: widget.posState.merchantSummary?.balance,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _pin = '';
      });
      _shakeController.forward(from: 0);
      AppToast.show(context, e.message, type: ToastType.error);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _pin = '';
      });
      _shakeController.forward(from: 0);
      AppToast.show(
        context,
        'Gagal memproses transaksi ke server.',
        type: ToastType.error,
      );
    }
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
          icon: const Icon(Icons.chevron_left_rounded,
              size: 28, color: AppColors.textPrimary),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
        title: Text(
          widget.isCashOut ? 'PIN Kas Keluar' : 'Masukkan PIN',
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
            // ── Konten Tengah ──────────────────────────────────────
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon kunci
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.merchantLightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isCashOut
                            ? Icons.payments_rounded
                            : Icons.lock_rounded,
                        color: AppColors.merchantPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama siswa
                    Text(
                      widget.studentData.name,
                      style: AppTheme.font(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Total tagihan/kas keluar kecil
                    Text(
                      '${widget.isCashOut ? "Kas Keluar" : "Tagihan"}  Rp ${widget.amount}',
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Instruksi
                    Text(
                      'Masukkan 6 digit PIN kartu santri',
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // PIN Dots
                    _buildPinDots(),
                  ],
                ),
              ),
            ),

            // ── Keypad Bawah ───────────────────────────────────────
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final offset =
            _shakeAnim.value * 8 * (0.5 - (_shakeAnim.value % 1.0)).sign;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (i) {
          final filled = i < _pin.length;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? AppColors.merchantPrimary : Colors.transparent,
              border: Border.all(
                color:
                    filled ? AppColors.merchantPrimary : AppColors.textLight,
                width: 2,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['1', '2', '3'].map(_keypadButton).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['4', '5', '6'].map(_keypadButton).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['7', '8', '9'].map(_keypadButton).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const SizedBox(width: 72, height: 56),
              _keypadButton('0'),
              _backspaceButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keypadButton(String digit) {
    return SizedBox(
      width: 72,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isProcessing ? null : () => _onPinKey(digit),
          child: Center(
            child: Text(
              digit,
              style: AppTheme.font(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backspaceButton() {
    return SizedBox(
      width: 72,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isProcessing ? null : _onBackspace,
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
