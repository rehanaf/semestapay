import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import 'topup_virtual_account_screen.dart';

class TopUpScreen extends StatefulWidget {
  final SemestaPayApiClient api;
  final ValueChanged<VirtualAccountInfo>? onVirtualAccountCreated;

  const TopUpScreen({
    super.key,
    required this.api,
    this.onVirtualAccountCreated,
  });

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  int _selectedTab = 0; // 0: Top Up, 1: Riwayat VA
  List<VirtualAccountInfo> _virtualAccounts = [];
  bool _isLoadingVa = false;

  @override
  void initState() {
    super.initState();
    _loadVirtualAccounts();
  }

  Future<void> _loadVirtualAccounts() async {
    setState(() => _isLoadingVa = true);
    try {
      final vas = await widget.api.getStudentVirtualAccounts(limit: 50);
      if (mounted) {
        setState(() {
          _virtualAccounts = vas;
          _isLoadingVa = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingVa = false);
      }
    }
  }

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

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTheme.font(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Top Up Saldo'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                height: 42,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Top Up'),
                    _buildTabButton(1, 'Riwayat VA (${_virtualAccounts.length})'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: SemestaBankSelector(
                        banks: _banks,
                        title: 'Pilih bank untuk Virtual Account',
                        searchHint: 'Cari nama bank...',
                        onSelected: (bank) async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TopUpAmountScreen(
                                api: widget.api,
                                bank: bank,
                                onVirtualAccountCreated: (va) {
                                  widget.onVirtualAccountCreated?.call(va);
                                  _loadVirtualAccounts();
                                },
                              ),
                            ),
                          );
                          _loadVirtualAccounts();
                        },
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVirtualAccounts,
                      child: _isLoadingVa
                          ? const Center(child: CircularProgressIndicator())
                          : _virtualAccounts.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: MediaQuery.sizeOf(context).height * 0.5,
                                      child: Center(
                                        child: Text(
                                          'Belum ada Virtual Account.',
                                          style: AppTheme.font(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _virtualAccounts.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final va = _virtualAccounts[index];
                                    final amountStr = NumberFormat('#,##0', 'en_US')
                                        .format(va.amount)
                                        .replaceAll(',', '.');
                                    final statusLabel = switch (va.status) {
                                      'paid' => 'Dibayar',
                                      'expired' => 'Kedaluwarsa',
                                      'failed' => 'Gagal',
                                      _ => 'Menunggu',
                                    };
                                    final statusColor = switch (va.status) {
                                      'paid' => AppColors.success,
                                      'expired' || 'failed' => AppColors.error,
                                      _ => AppColors.warning,
                                    };
                                    return InkWell(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                VirtualAccountDetailScreen(virtualAccount: va),
                                          ),
                                        );
                                        _loadVirtualAccounts();
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: SemestaCard(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.account_balance_rounded,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    va.bankName,
                                                    style: AppTheme.font(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    va.accountNumber,
                                                    style: AppTheme.font(
                                                      fontSize: 12,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Rp $amountStr',
                                                  style: AppTheme.font(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    statusLabel,
                                                    style: AppTheme.font(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
            ),
          ],
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
