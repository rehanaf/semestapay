import 'package:flutter/material.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import 'topup_virtual_account_screen.dart';

class TopUpScreen extends StatelessWidget {
  final SemestaPayApiClient api;
  final ValueChanged<VirtualAccountInfo>? onVirtualAccountCreated;

  const TopUpScreen({
    super.key,
    required this.api,
    this.onVirtualAccountCreated,
  });

  static const _banks = [
    SemestaBankOption(
      code: 'BC',
      name: 'BCA Virtual Account',
      abbreviation: 'BCA',
      color: Color(0xFF005696),
    ),
    SemestaBankOption(
      code: 'M2',
      name: 'Mandiri Virtual Account',
      abbreviation: 'MDR',
      color: Color(0xFF00387A),
    ),
    SemestaBankOption(
      code: 'I1',
      name: 'BNI Virtual Account',
      abbreviation: 'BNI',
      color: Color(0xFFF15A24),
    ),
    SemestaBankOption(
      code: 'BR',
      name: 'BRI Virtual Account',
      abbreviation: 'BRI',
      color: Color(0xFF00529C),
    ),
    SemestaBankOption(
      code: 'B1',
      name: 'CIMB Niaga Virtual Account',
      abbreviation: 'CIMB',
      color: Color(0xFFED1C24),
    ),
    SemestaBankOption(
      code: 'BT',
      name: 'Permata Virtual Account',
      abbreviation: 'PMT',
      color: Color(0xFF4A90E2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pilih Bank Top Up'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: SemestaBankSelector(
            banks: _banks,
            title: 'Pilih bank untuk Virtual Account',
            searchHint: 'Cari nama bank...',
            onSelected: (bank) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TopUpAmountScreen(
                    api: api,
                    bank: bank,
                    onVirtualAccountCreated: onVirtualAccountCreated,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class TopUpAmountScreen extends StatefulWidget {
  final SemestaPayApiClient api;
  final SemestaBankOption bank;
  final ValueChanged<VirtualAccountInfo>? onVirtualAccountCreated;

  const TopUpAmountScreen({
    super.key,
    required this.api,
    required this.bank,
    this.onVirtualAccountCreated,
  });

  @override
  State<TopUpAmountScreen> createState() => _TopUpAmountScreenState();
}

class _TopUpAmountScreenState extends State<TopUpAmountScreen> {
  bool _isLoading = false;

  Future<void> _createVirtualAccount(int amount) async {
    if (amount < 10000) {
      AppToast.show(
        context,
        'Nominal minimal top up Rp10.000.',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final virtualAccount = await widget.api.getOrCreateTopupVa(
        amount: amount.toDouble(),
        paymentMethod: widget.bank.code,
        vaType: 'dynamic',
        forceNew: true,
      );
      if (!mounted) return;
      widget.onVirtualAccountCreated?.call(virtualAccount);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VirtualAccountDetailScreen(virtualAccount: virtualAccount),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        AppToast.show(context, error.message, type: ToastType.error);
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          'Gagal membuat Virtual Account. Periksa koneksi internet.',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Nominal Top Up'), centerTitle: true),
      body: SafeArea(
        child: SemestaAmountEntry(
          header: _buildSelectedBank(),
          amountLabel: 'Nominal Top Up',
          continueLabel: _isLoading
              ? 'Membuat Virtual Account'
              : 'Buat Virtual Account',
          accentColor: AppColors.primary,
          minimumAmount: 10000,
          minimumAmountLabel: 'Minimal Rp10.000',
          isLoading: _isLoading,
          onContinue: _createVirtualAccount,
        ),
      ),
    );
  }

  Widget _buildSelectedBank() {
    return SemestaCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.bank.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.bank.abbreviation ?? widget.bank.code,
              style: AppTheme.font(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: widget.bank.color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank tujuan VA',
                  style: AppTheme.font(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
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
        ],
      ),
    );
  }
}
