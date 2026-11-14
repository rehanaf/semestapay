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
  int _selectedTab = 0; // 0: Top Up, 1: Riwayat
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<VirtualAccountInfo> _virtualAccounts = [];
  bool _isLoadingVa = false;

  @override
  void initState() {
    super.initState();
    _loadVirtualAccounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
        onTap: () {
          setState(() {
            _selectedTab = index;
            _searchController.clear();
            _searchQuery = '';
          });
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.font(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();

    // Filtered banks
    final filteredBanks = _banks.where((bank) {
      return query.isEmpty ||
          bank.name.toLowerCase().contains(query) ||
          bank.code.toLowerCase().contains(query) ||
          (bank.abbreviation?.toLowerCase().contains(query) ?? false);
    }).toList();

    // Filtered virtual accounts (exclude pending VAs)
    final filteredVas = _virtualAccounts.where((va) {
      if (va.status == 'pending') return false;
      return query.isEmpty ||
          va.bankName.toLowerCase().contains(query) ||
          va.accountNumber.toLowerCase().contains(query) ||
          va.status.toLowerCase().contains(query);
    }).toList();

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
              child: Column(
                children: [
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: AppTheme.font(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: _selectedTab == 0
                            ? 'Cari nama bank...'
                            : 'Cari riwayat virtual account...',
                        hintStyle: AppTheme.font(
                          fontSize: 13,
                          color: AppColors.textLight,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(0, 'Top Up'),
                        _buildTabButton(1, 'Riwayat'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Pilih Bank Tujuan',
                            style: AppTheme.font(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        filteredBanks.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: Text(
                                    'Bank tidak ditemukan.',
                                    style: AppTheme.font(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.textPrimary
                                          .withValues(alpha: 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredBanks.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: AppColors.divider,
                                  ),
                                  itemBuilder: (context, index) {
                                    final bank = filteredBanks[index];
                                    return InkWell(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TopUpAmountScreen(
                                              api: widget.api,
                                              bank: bank,
                                              onVirtualAccountCreated: (va) {
                                                widget.onVirtualAccountCreated
                                                    ?.call(va);
                                                _loadVirtualAccounts();
                                              },
                                            ),
                                          ),
                                        );
                                        _loadVirtualAccounts();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: bank.color
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                bank.abbreviation ?? bank.code,
                                                style: AppTheme.font(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: bank.color,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                bank.name,
                                                style: AppTheme.font(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppColors.textLight,
                                              size: 22,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVirtualAccounts,
                      child: _isLoadingVa
                          ? const Center(child: CircularProgressIndicator())
                          : filteredVas.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: MediaQuery.sizeOf(context).height * 0.5,
                                      child: Center(
                                        child: Text(
                                          _searchQuery.isEmpty
                                              ? 'Belum ada Virtual Account.'
                                              : 'Virtual Account tidak ditemukan.',
                                          style: AppTheme.font(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                                      child: Text(
                                        'Riwayat Virtual Account',
                                        style: AppTheme.font(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.textPrimary
                                                .withValues(alpha: 0.04),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: filteredVas.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(
                                          height: 1,
                                          color: AppColors.divider,
                                        ),
                                        itemBuilder: (context, index) {
                                          final va = filteredVas[index];
                                          final amountStr = NumberFormat(
                                            '#,##0',
                                            'en_US',
                                          ).format(va.amount).replaceAll(',', '.');
                                          final statusLabel = switch (va.status) {
                                            'paid' => 'Dibayar',
                                            'expired' => 'Kedaluwarsa',
                                            'failed' => 'Gagal',
                                            _ => 'Menunggu',
                                          };
                                          final statusColor = switch (va.status) {
                                            'paid' => AppColors.success,
                                            'expired' || 'failed' =>
                                              AppColors.error,
                                            _ => AppColors.warning,
                                          };
                                          return InkWell(
                                            onTap: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      VirtualAccountDetailScreen(
                                                          virtualAccount: va),
                                                ),
                                              );
                                              _loadVirtualAccounts();
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 14,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 44,
                                                    height: 44,
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary
                                                          .withValues(
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: const Icon(
                                                      Icons
                                                          .account_balance_rounded,
                                                      color: AppColors.primary,
                                                      size: 22,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          va.bankName,
                                                          style: AppTheme.font(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .textPrimary,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          va.accountNumber,
                                                          style: AppTheme.font(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: AppColors
                                                                .textSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .end,
                                                    children: [
                                                      Text(
                                                        'Rp $amountStr',
                                                        style: AppTheme.font(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: statusColor
                                                              .withValues(
                                                                  alpha: 0.12),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10),
                                                        ),
                                                        child: Text(
                                                          statusLabel,
                                                          style: AppTheme.font(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
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
                                  ],
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
      await Navigator.pushReplacement(
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
