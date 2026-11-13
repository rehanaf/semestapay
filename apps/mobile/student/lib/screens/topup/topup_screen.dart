import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top Up Screen — Duitku Virtual Account
// ─────────────────────────────────────────────────────────────────────────────

class TopUpScreen extends StatefulWidget {
  final SemestaPayApiClient api;

  const TopUpScreen({super.key, required this.api});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  VirtualAccountInfo? _va;
  String _selectedMethod = 'BC';

  static const _methods = [
    _PaymentMethodOption(code: 'BC', name: 'BCA Virtual Account', icon: 'BCA'),
    _PaymentMethodOption(code: 'M2', name: 'Mandiri Virtual Account', icon: 'MDR'),
    _PaymentMethodOption(code: 'I1', name: 'BNI Virtual Account', icon: 'BNI'),
    _PaymentMethodOption(code: 'BR', name: 'BRI Virtual Account', icon: 'BRI'),
    _PaymentMethodOption(code: 'B1', name: 'CIMB Niaga VA', icon: 'CIMB'),
    _PaymentMethodOption(code: 'BT', name: 'Permata Bank VA', icon: 'PMT'),
  ];

  static const _quickAmounts = [10000, 25000, 50000, 100000, 200000, 500000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _amount {
    final raw = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(raw) ?? 0;
  }

  Future<void> _requestVa() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _va = null;
    });
    try {
      final va = await widget.api.getOrCreateTopupVa(
        amount: _amount,
        paymentMethod: _selectedMethod,
      );
      if (!mounted) return;
      setState(() => _va = va);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.show(context, e.message, type: ToastType.error);
    } catch (_) {
      if (!mounted) return;
      AppToast.show(context, 'Gagal membuat virtual account. Coba lagi.', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Top Up Saldo',
          style: AppTheme.font(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _va != null ? _buildVaResult() : _buildForm(),
    );
  }

  // ── Form: Pilih nominal & metode ─────────────────────────────────────────

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Nominal Top Up',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AmountField(controller: _amountController),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickAmounts
                      .map((a) => _QuickAmountChip(
                            amount: a,
                            onTap: () => setState(() {
                              _amountController.text =
                                  NumberFormat.decimalPattern('id').format(a);
                            }),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Pilih Bank Virtual Account',
            child: Column(
              children: _methods
                  .map((m) => _MethodTile(
                        method: m,
                        isSelected: _selectedMethod == m.code,
                        onTap: () => setState(() => _selectedMethod = m.code),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _requestVa,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Buat Virtual Account',
                      style: AppTheme.font(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          _InfoBox(
            icon: Icons.info_outline_rounded,
            text:
                'Virtual account bersifat sementara dan berlaku selama 24 jam. '
                'Bayar sesuai nominal yang tertera untuk mengisi saldo secara otomatis.',
          ),
        ],
      ),
    );
  }

  // ── VA Result: tampilkan nomor VA & instruksi ────────────────────────────

  Widget _buildVaResult() {
    final va = _va!;
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final expiresAt = va.expiresAt != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'id').format(DateTime.parse(va.expiresAt!).toLocal())
        : '-';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status banner
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: va.isPaid
                ? const Color(0xFF00C896)
                : va.isFailed || va.isExpired
                    ? const Color(0xFFEF5350)
                    : AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                va.isPaid
                    ? Icons.check_circle_rounded
                    : va.isFailed || va.isExpired
                        ? Icons.cancel_rounded
                        : Icons.account_balance_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      va.isPaid
                          ? 'Pembayaran Berhasil!'
                          : va.isFailed
                              ? 'Pembayaran Gagal'
                              : va.isExpired
                                  ? 'Virtual Account Kadaluarsa'
                                  : 'Menunggu Pembayaran',
                      style: AppTheme.font(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (!va.isPaid && !va.isFailed && !va.isExpired)
                      Text(
                        'Berlaku hingga $expiresAt',
                        style: AppTheme.font(fontSize: 12, color: Colors.white70),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Detail VA
        _SectionCard(
          title: 'Detail Virtual Account',
          child: Column(
            children: [
              _DetailRow(label: 'Bank', value: va.bankName),
              const Divider(height: 20),
              _VaNumberRow(accountNumber: va.accountNumber),
              const Divider(height: 20),
              _DetailRow(
                label: 'Jumlah',
                value: fmt.format(va.amount),
                valueStyle: AppTheme.font(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const Divider(height: 20),
              _DetailRow(label: 'Berlaku Hingga', value: expiresAt),
              const Divider(height: 20),
              _DetailRow(
                label: 'ID Pesanan',
                value: va.merchantOrderId,
                valueStyle: AppTheme.font(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Cara Bayar
        _SectionCard(
          title: 'Cara Bayar ATM / M-Banking',
          child: _PaymentInstructions(bankCode: va.paymentMethod),
        ),
        const SizedBox(height: 20),

        // Buat VA baru
        TextButton.icon(
          onPressed: () => setState(() => _va = null),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Buat Top Up Baru'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentMethodOption {
  final String code;
  final String name;
  final String icon;
  const _PaymentMethodOption(
      {required this.code, required this.name, required this.icon});
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.font(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  const _AmountField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTheme.font(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        prefixText: 'Rp ',
        prefixStyle: AppTheme.font(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
        hintText: '0',
        hintStyle: AppTheme.font(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textLight,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      validator: (v) {
        final amount = double.tryParse(v?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0') ?? 0;
        if (amount < 10000) return 'Minimum top up Rp 10.000';
        if (amount > 10000000) return 'Maksimum top up Rp 10.000.000';
        return null;
      },
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  final int amount;
  final VoidCallback onTap;
  const _QuickAmountChip({required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = amount >= 1000000
        ? '${amount ~/ 1000000}jt'
        : '${amount ~/ 1000}rb';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: AppTheme.font(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final _PaymentMethodOption method;
  final bool isSelected;
  final VoidCallback onTap;
  const _MethodTile(
      {required this.method, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E9F2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3FA),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                method.icon,
                style: AppTheme.font(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method.name,
                style: AppTheme.font(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _DetailRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTheme.font(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: valueStyle ??
                AppTheme.font(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}

class _VaNumberRow extends StatelessWidget {
  final String accountNumber;
  const _VaNumberRow({required this.accountNumber});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nomor Virtual Account',
                style: AppTheme.font(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                accountNumber,
                style: AppTheme.font(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: accountNumber));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nomor VA disalin ke clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.copy_rounded),
          color: AppColors.primary,
          tooltip: 'Salin',
        ),
      ],
    );
  }
}

class _PaymentInstructions extends StatelessWidget {
  final String bankCode;
  const _PaymentInstructions({required this.bankCode});

  static const _instructions = <String, List<String>>{
    'BC': [
      'Login m-BCA, pilih m-Transfer → BCA Virtual Account.',
      'Masukkan nomor virtual account.',
      'Periksa detail, lalu konfirmasi dengan PIN BCA.',
      'Saldo SemestaPay Anda akan otomatis bertambah.',
    ],
    'M2': [
      'Login Mandiri Online, pilih Pembayaran → Multi Payment.',
      'Cari "SemestaPay", masukkan nomor virtual account.',
      'Konfirmasi jumlah pembayaran, lalu selesaikan.',
      'Saldo SemestaPay Anda akan otomatis bertambah.',
    ],
    'I1': [
      'Login BNI Mobile Banking, pilih Transfer → Virtual Account.',
      'Masukkan nomor virtual account BNI.',
      'Konfirmasi jumlah dan selesaikan transaksi.',
      'Saldo SemestaPay Anda akan otomatis bertambah.',
    ],
    'BR': [
      'Login BRImo, pilih Pembayaran → BRIVA.',
      'Masukkan nomor BRIVA yang tertera.',
      'Konfirmasi jumlah dan selesaikan transaksi.',
      'Saldo SemestaPay Anda akan otomatis bertambah.',
    ],
  };

  static const _fallback = [
    'Buka aplikasi mobile banking atau kunjungi ATM terdekat.',
    'Pilih menu Transfer / Pembayaran → Virtual Account.',
    'Masukkan nomor virtual account yang tertera.',
    'Konfirmasi jumlah dan selesaikan pembayaran.',
    'Saldo SemestaPay Anda akan otomatis bertambah.',
  ];

  @override
  Widget build(BuildContext context) {
    final steps = _instructions[bankCode] ?? _fallback;
    return Column(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key + 1;
        final step = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$i',
                  style: AppTheme.font(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step,
                  style: AppTheme.font(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTheme.font(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
