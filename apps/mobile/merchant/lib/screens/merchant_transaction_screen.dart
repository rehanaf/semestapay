import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import '../state/pos_state.dart';
import 'merchant_tap_card_screen.dart';

class MerchantTransactionScreen extends StatefulWidget {
  final PosState posState;
  final bool isCashOut;

  const MerchantTransactionScreen({
    super.key,
    required this.posState,
    this.isCashOut = false,
  });

  @override
  State<MerchantTransactionScreen> createState() =>
      _MerchantTransactionScreenState();
}

class _MerchantTransactionScreenState extends State<MerchantTransactionScreen> {
  int _numericAmount = 0;
  String _formattedAmount = '0';
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _proceedToTapCard() {
    if (_numericAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Masukkan nominal pembayaran terlebih dahulu',
            style: AppTheme.font(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final formatted = _formattedAmount;
    final note = _noteController.text.trim();

    widget.posState.setManualAmount(_numericAmount.toDouble());
    if (note.isNotEmpty) widget.posState.setNote(note);

    // Navigasi ke Step 2: UI Tap Kartu dengan Simulasi Tap
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantTapCardScreen(
          posState: widget.posState,
          amount: formatted,
          rawAmount: _numericAmount,
          note: note,
          isCashOut: widget.isCashOut,
        ),
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
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isCashOut ? 'Kas Keluar' : 'Transaksi Kasir',
          style: AppTheme.font(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: SemestaAmountEntry(
          header: _buildStoreHeader(),
          amountLabel: widget.isCashOut
              ? 'Nominal Kas Keluar'
              : 'Nominal Kas Masuk',
          continueLabel: 'Lanjutkan ke Tap Kartu',
          accentColor: AppColors.merchantPrimary,
          quickActions: const [
            SemestaAmountQuickAction(label: '+10 rb', amount: 10000),
            SemestaAmountQuickAction(label: '+25 rb', amount: 25000),
            SemestaAmountQuickAction(label: '+50 rb', amount: 50000),
            SemestaAmountQuickAction(label: '+100 rb', amount: 100000),
            SemestaAmountQuickAction(label: '+200 rb', amount: 200000),
            SemestaAmountQuickAction(
              label: 'Pas 50 rb',
              amount: 50000,
              setAmount: true,
            ),
          ],
          extraContent: _buildNoteInput(),
          extraContentFocusNode: _noteFocusNode,
          onAmountChanged: (amount) {
            setState(() {
              _numericAmount = amount;
              _formattedAmount = SemestaAmountFormatter.format(amount);
            });
          },
          onContinue: (_) => _proceedToTapCard(),
        ),
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.merchantLightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.merchantPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.posState.merchantSummary?.name ??
                            widget.posState.outletName,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Outlet: ${widget.posState.outletName} • ${widget.posState.outletCode}',
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

  Widget _buildNoteInput() {
    return Container(
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
      child: TextField(
        controller: _noteController,
        focusNode: _noteFocusNode,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        maxLength: 50,
        style: AppTheme.font(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          prefixIcon: const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          hintText: 'Nomor meja / catatan kasir (opsional)...',
          hintStyle: AppTheme.font(fontSize: 13, color: AppColors.textLight),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
