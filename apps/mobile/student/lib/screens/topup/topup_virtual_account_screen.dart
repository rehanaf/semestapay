import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

class VirtualAccountDetailScreen extends StatelessWidget {
  final VirtualAccountInfo virtualAccount;

  const VirtualAccountDetailScreen({super.key, required this.virtualAccount});

  String get _formattedAmount => NumberFormat(
    '#,##0',
    'en_US',
  ).format(virtualAccount.amount).replaceAll(',', '.');

  String get _expiryLabel {
    final expiresAt = DateTime.tryParse(virtualAccount.expiresAt ?? '');
    if (expiresAt == null) return '-';
    return DateFormat('dd/MM/yyyy, HH:mm').format(expiresAt.toLocal());
  }

  String get _statusLabel => switch (virtualAccount.status) {
    'paid' => 'Dibayar',
    'expired' => 'Kedaluwarsa',
    'failed' => 'Gagal',
    _ => 'Menunggu pembayaran',
  };

  String get _pageTitle => switch (virtualAccount.status) {
    'paid' => 'Top Up Berhasil',
    'expired' => 'Virtual Account Kedaluwarsa',
    'failed' => 'Virtual Account Gagal',
    _ => 'Virtual Account Siap Dibayar',
  };

  Color get _statusColor => switch (virtualAccount.status) {
    'paid' => AppColors.success,
    'expired' || 'failed' => AppColors.error,
    _ => AppColors.warning,
  };

  void _copyAccountNumber(BuildContext context) {
    Clipboard.setData(ClipboardData(text: virtualAccount.accountNumber));
    AppToast.show(
      context,
      'Nomor Virtual Account disalin.',
      type: ToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Virtual Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        virtualAccount.isPaid
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        color: _statusColor,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _pageTitle,
                    textAlign: TextAlign.center,
                    style: AppTheme.font(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel,
                        style: AppTheme.font(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Rp $_formattedAmount',
                    textAlign: TextAlign.center,
                    style: AppTheme.font(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAccountCard(context),
                  const SizedBox(height: 12),
                  _buildExpiryCard(),
                  const SizedBox(height: 12),
                  _buildInstructionCard(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SemestaPrimaryButton(
                label: 'Selesai',
                icon: Icons.check_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return SemestaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      virtualAccount.bankName,
                      style: AppTheme.font(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      virtualAccount.accountName ??
                          virtualAccount.studentName ??
                          'SemestaPay',
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
          const SizedBox(height: 18),
          Text(
            'NOMOR VIRTUAL ACCOUNT',
            style: AppTheme.font(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  virtualAccount.accountNumber,
                  style: AppTheme.font(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Salin nomor VA',
                onPressed: () => _copyAccountNumber(context),
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryCard() {
    return SemestaInfoBanner(
      icon: Icons.timer_outlined,
      message: 'Bayar tepat Rp $_formattedAmount sebelum $_expiryLabel.',
    );
  }

  Widget _buildInstructionCard() {
    return SemestaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cara pembayaran',
            style: AppTheme.font(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text('1. Buka mobile banking atau ATM bank yang dipilih.'),
          const SizedBox(height: 6),
          const Text('2. Pilih menu pembayaran Virtual Account.'),
          const SizedBox(height: 6),
          const Text('3. Masukkan nomor VA dan nominal yang tertera.'),
          const SizedBox(height: 6),
          const Text('4. Pastikan nama tujuan benar, lalu konfirmasi.'),
        ],
      ),
    );
  }
}
