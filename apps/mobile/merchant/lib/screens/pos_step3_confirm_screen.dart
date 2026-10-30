import 'package:flutter/material.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:uuid/uuid.dart';
import '../state/pos_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class PosStep3ConfirmScreen extends StatefulWidget {
  final PosState posState;
  const PosStep3ConfirmScreen({super.key, required this.posState});

  @override
  State<PosStep3ConfirmScreen> createState() => _PosStep3ConfirmScreenState();
}

class _PosStep3ConfirmScreenState extends State<PosStep3ConfirmScreen> {
  final _pinController = TextEditingController();
  final _noteController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    final card = widget.posState.scannedCard;
    if (card == null) {
      setState(() => _errorMessage = 'Data kartu santri tidak ditemukan.');
      return;
    }

    final total = widget.posState.grandTotal;

    // Check balance
    if (card.wallet.balance < total) {
      setState(() => _errorMessage = 'Saldo santri tidak mencukupi.');
      return;
    }

    // Check daily limit
    if (card.dailyLimit > 0 && total > card.remainingDailyLimit) {
      setState(() => _errorMessage =
          'Transaksi melebihi sisa limit harian santri (${widget.posState.formatCurrency(card.remainingDailyLimit)}).');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final req = TapPaymentRequest(
        cardUid: card.card.uid,
        outletCode: widget.posState.outletCode,
        amount: total,
        idempotencyKey: const Uuid().v4(),
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        pin: _pinController.text.trim().isNotEmpty
            ? _pinController.text.trim()
            : null,
        items: widget.posState.cartItems.isNotEmpty
            ? widget.posState.cartItems
                .map((ci) => TapPaymentItem(
                      itemId: ci.item.id,
                      quantity: ci.quantity,
                    ))
                .toList()
            : null,
      );

      final res = await widget.posState.api.tapPayment(req);

      if (mounted) {
        _showSuccessDialog(res);
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Gagal memproses pembayaran.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccessDialog(TapPaymentResponse res) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pembayaran Berhasil!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Invoice: #${res.invoiceNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Dibayar',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          widget.posState.formatCurrency(res.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (res.walletBalanceAfter != null) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sisa Saldo Santri',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            widget.posState
                                .formatCurrency(res.walletBalanceAfter!),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.posState.resetTransaction();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(posState: widget.posState),
                  ),
                  (route) => false,
                );
              },
              child: const Text('Transaksi Baru'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.posState.scannedCard;
    final total = widget.posState.grandTotal;

    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Konfirmasi Pembayaran')),
        body: const Center(child: Text('Data kartu tidak valid.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Langkah 3: Konfirmasi & PIN'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Student Card Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                AppTheme.primaryColor.withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.student.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'NIS: ${card.student.nis} • ${card.student.className ?? 'Santri'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.successColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AKTIF',
                              style: TextStyle(
                                color: AppTheme.successColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Saldo Dompet Santri',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.posState
                                    .formatCurrency(card.wallet.balance),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Sisa Limit Harian',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.posState.formatCurrency(
                                    card.remainingDailyLimit),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Transaction Detail Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rincian Transaksi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.posState.cartItems.isNotEmpty) ...[
                        ...widget.posState.cartItems.map((ci) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${ci.item.name} x${ci.quantity}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    widget.posState.formatCurrency(ci.subtotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.posState.formatCurrency(total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // PIN Input Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PIN Santri (6 Digit)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _pinController.text = '123456';
                            },
                            child: const Text('Isi Demo PIN (123456)'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan PIN kartu santri',
                          prefixIcon: Icon(Icons.pin_outlined),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          hintText: 'Catatan tambahan (opsional)',
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.dangerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.dangerColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.dangerColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitting ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Konfirmasi & Bayar ${widget.posState.formatCurrency(total)}',
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
}
