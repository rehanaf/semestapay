import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import '../state/student_state.dart';
import 'topup/topup_virtual_account_screen.dart';

/// Model transaksi riwayat
class HistoryItem {
  final String id;
  final String title;
  final String category;
  final int amount; // positif = uang masuk, negatif = uang keluar
  final DateTime dateTime;
  final IconData icon;
  final Color iconColor;
  final String? note;
  final String sourceOrTarget;
  final String typeLabel; // e.g., 'Transfer', 'Merchant', 'Tagihan', 'Top Up'
  final VirtualAccountInfo? virtualAccount;

  const HistoryItem({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dateTime,
    required this.icon,
    required this.iconColor,
    this.note,
    required this.sourceOrTarget,
    required this.typeLabel,
    this.virtualAccount,
  });

  bool get isIncome => virtualAccount == null && amount > 0;
}

class HistoryPage extends StatefulWidget {
  final StudentState state;
  final VoidCallback? onBackToHome;

  const HistoryPage({super.key, required this.state, this.onBackToHome});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.state.refresh();
    });
  }

  String _topupTitle(String? note) {
    final n = (note ?? '').toLowerCase();
    if (n.contains('bca') || n == 'bc') return 'Isi Saldo dari Bank BCA';
    if (n.contains('mandiri') || n == 'm2') return 'Isi Saldo dari Bank Mandiri';
    if (n.contains('bni') || n == 'i1') return 'Isi Saldo dari Bank BNI';
    if (n.contains('bri') || n == 'br') return 'Isi Saldo dari Bank BRI';
    if (n.contains('cimb') || n == 'b1') return 'Isi Saldo dari CIMB Niaga';
    if (n.contains('permata') || n == 'bt') return 'Isi Saldo dari Bank Permata';
    if (n.contains('duitku')) return 'Isi Saldo Online';
    if (n.isNotEmpty && n != 'cash' && n != 'topup') return 'Isi Saldo dari $note';
    return 'Top Up Saldo';
  }

  final List<String> _filters = [
    'Semua',
    'Uang Masuk',
    'Uang Keluar',
    'Kantin / Merchant',
    'Transfer',
    'Tagihan',
  ];

  List<HistoryItem> get _allTransactions {
    final transactions = widget.state.mutations.map((m) {
      final isCredit = m.isCredit;
      final typeLabel = _typeLabel(m.type);
      final isTopup = m.type == 'topup';
      final title = isTopup
          ? _topupTitle(m.note)
          : (m.merchant?.isNotEmpty == true
              ? m.merchant!
              : (m.note?.isNotEmpty == true ? m.note! : typeLabel));
      return HistoryItem(
        id: m.id,
        title: title,
        category: m.outlet?.isNotEmpty == true
            ? m.outlet!
            : (m.note?.isNotEmpty == true ? m.note! : typeLabel),
        amount: (isCredit ? m.amount : -m.amount).round(),
        dateTime:
            DateTime.tryParse(m.createdAt ?? '')?.toLocal() ?? DateTime.now(),
        icon: _iconFor(m.type),
        iconColor: isCredit ? AppColors.accent : _colorFor(m.type),
        note: m.note,
        sourceOrTarget: m.outlet ?? m.merchant ?? 'Semestapay',
        typeLabel: typeLabel,
      );
    }).toList();
    return transactions;
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'topup':
        return 'Uang Masuk';
      case 'payment':
        return 'Kantin / Merchant';
      case 'transfer':
      case 'transfer_in':
      case 'transfer_out':
        return 'Transfer';
      case 'withdraw':
        return 'Tarik Tunai';
      default:
        return 'Tagihan';
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'topup':
        return Icons.account_balance_wallet_rounded;
      case 'payment':
        return Icons.storefront_rounded;
      case 'transfer':
      case 'transfer_in':
      case 'transfer_out':
        return Icons.swap_horiz_rounded;
      case 'withdraw':
        return Icons.atm_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'payment':
        return AppColors.merchantPrimary;
      case 'transfer':
      case 'transfer_in':
      case 'transfer_out':
        return const Color(0xFF00C896);
      case 'withdraw':
        return const Color(0xFFFF6B35);
      default:
        return AppColors.primary;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HistoryItem> get _filteredTransactions {
    final query = _searchController.text.trim().toLowerCase();

    return _allTransactions.where((item) {
      // Filter kategori
      if (_selectedFilter == 'Virtual Account' && item.virtualAccount == null) {
        return false;
      }
      if (_selectedFilter != 'Semua' &&
          _selectedFilter != 'Virtual Account' &&
          item.virtualAccount != null) {
        return false;
      }
      if (_selectedFilter == 'Uang Masuk' && !item.isIncome) {
        return false;
      }
      if (_selectedFilter == 'Uang Keluar' && item.isIncome) {
        return false;
      }
      if (_selectedFilter == 'Kantin / Merchant' &&
          item.typeLabel != 'Kantin / Merchant') {
        return false;
      }
      if (_selectedFilter == 'Transfer' && item.typeLabel != 'Transfer') {
        return false;
      }
      if (_selectedFilter == 'Tagihan' && item.typeLabel != 'Tagihan') {
        return false;
      }

      // Filter query pencarian
      if (query.isNotEmpty) {
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchCategory = item.category.toLowerCase().contains(query);
        final matchNote = item.note?.toLowerCase().contains(query) ?? false;
        final matchId = item.id.toLowerCase().contains(query);
        return matchTitle || matchCategory || matchNote || matchId;
      }

      return true;
    }).toList();
  }

  // Hitung total masuk & keluar untuk bulan ini
  int get _totalIncome {
    return _allTransactions
        .where((e) => e.virtualAccount == null && e.isIncome)
        .fold<int>(0, (sum, e) => sum + e.amount);
  }

  int get _totalExpense {
    return _allTransactions
        .where((e) => e.virtualAccount == null && !e.isIncome)
        .fold<int>(0, (sum, e) => sum + e.amount.abs());
  }

  String _formatCurrency(int amount) {
    final str = amount.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  void _openDetailModal(HistoryItem item) {
    final virtualAccount = item.virtualAccount;
    if (virtualAccount != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VirtualAccountDetailScreen(virtualAccount: virtualAccount),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistoryDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final filtered = _filteredTransactions;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: widget.onBackToHome != null
                ? IconButton(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      size: 28,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: widget.onBackToHome,
                  )
                : null,
            title: Text(
              'Riwayat Transaksi',
              style: AppTheme.font(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.download_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                tooltip: 'Unduh Rekening Koran',
                onPressed: () {
                  AppToast.show(
                    context,
                    'Laporan riwayat transaksi berhasil diunduh (PDF)',
                    type: ToastType.success,
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Area Filter & Search tetap di atas
                _buildTopControlBar(),

                // List Transaksi
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: widget.state.refresh,
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.6,
                                child: _buildEmptyState(),
                              ),
                            ],
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildMonthlySummaryCard(),
                              const SizedBox(height: 16),
                              _buildGroupedList(filtered),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Header Pencarian & Chip Filter ────────────────────────────────────────

  Widget _buildTopControlBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Input Search
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: AppTheme.font(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari nama merchant, transfer, atau catatan...',
                hintStyle: AppTheme.font(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Chip Horizontal Filter
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: AppTheme.font(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ringkasan Bulan Ini Card ───────────────────────────────────────────────

  Widget _buildMonthlySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ringkasan November 2026',
                    style: AppTheme.font(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Aktif',
                  style: AppTheme.font(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              // Uang Masuk
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6F7F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Uang Masuk',
                            style: AppTheme.font(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+Rp ${_formatCurrency(_totalIncome)}',
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.font(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(width: 1, height: 36, color: AppColors.divider),
              const SizedBox(width: 12),

              // Uang Keluar
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Uang Keluar',
                            style: AppTheme.font(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '-Rp ${_formatCurrency(_totalExpense)}',
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.font(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── List Transaksi Grouped ────────────────────────────────────────────────

  Widget _buildGroupedList(List<HistoryItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          color: AppColors.divider,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildTransactionTile(item);
        },
      ),
    );
  }

  Widget _buildTransactionTile(HistoryItem item) {
    final isIncome = item.isIncome;
    final virtualAccount = item.virtualAccount;
    final prefix = virtualAccount != null
        ? 'Rp '
        : isIncome
        ? '+Rp '
        : '-Rp ';
    final nominalStr = '$prefix${_formatCurrency(item.amount)}';
    final statusLabel = virtualAccount == null
        ? 'Berhasil'
        : switch (virtualAccount.status) {
            'paid' => 'Dibayar',
            'expired' => 'Kedaluwarsa',
            'failed' => 'Gagal',
            _ => 'Menunggu',
          };
    final statusColor = virtualAccount == null
        ? AppColors.accent
        : switch (virtualAccount.status) {
            'paid' => AppColors.success,
            'expired' || 'failed' => AppColors.error,
            _ => AppColors.warning,
          };

    final timeStr =
        '${_pad(item.dateTime.hour)}:${_pad(item.dateTime.minute)} WIB';
    final dateStr = '${item.dateTime.day} ${_monthName(item.dateTime.month)}';

    return InkWell(
      onTap: () => _openDetailModal(item),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Nama & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.font(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$dateStr, $timeStr',
                    style: AppTheme.font(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),

            // Nominal
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  nominalStr,
                  style: AppTheme.font(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: virtualAccount != null
                        ? AppColors.textPrimary
                        : isIncome
                        ? AppColors.accent
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
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
  }

  // ─── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.textLight,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Transaksi',
              style: AppTheme.font(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ditemukan transaksi dengan filter atau kata kunci tersebut.',
              textAlign: TextAlign.center,
              style: AppTheme.font(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
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
}

// ─── Modal Detail Transaksi (Sesuai Desain Resi Standard) ────────────────────

class _HistoryDetailSheet extends StatefulWidget {
  final HistoryItem item;

  const _HistoryDetailSheet({required this.item});

  @override
  State<_HistoryDetailSheet> createState() => _HistoryDetailSheetState();
}

class _HistoryDetailSheetState extends State<_HistoryDetailSheet> {
  bool _accordionOpen = false;

  String _formatCurrency(int amount) {
    final str = amount.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
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

  void _copyTrxId() {
    Clipboard.setData(ClipboardData(text: widget.item.id));
    AppToast.show(context, 'ID Transaksi disalin', type: ToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isIncome = item.isIncome;
    final prefix = isIncome ? '+Rp ' : 'Rp ';
    final amountStr = '$prefix${_formatCurrency(item.amount)}';

    final d = item.dateTime;
    final timeStr =
        '${d.day} ${_monthName(d.month)} ${d.year}, ${_pad(d.hour)}:${_pad(d.minute)} WIB';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Icon Checkmark
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F7F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 40,
              ),
            ),
            const SizedBox(height: 12),

            // Judul
            Text(
              'Transaksi Berhasil!',
              style: AppTheme.font(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // ID Transaksi (tap to copy)
            GestureDetector(
              onTap: _copyTrxId,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.id,
                    style: AppTheme.font(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.copy_rounded,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Nominal Besar
            Text(
              amountStr,
              style: AppTheme.font(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isIncome ? AppColors.accent : AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 18),

            // Card Penerima / Sumber Dana
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTheme.font(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.sourceOrTarget,
                          style: AppTheme.font(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
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
                      color: const Color(0xFFE6F7F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sukses',
                      style: AppTheme.font(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Accordion Detail Transaksi (Default Tertutup)
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _accordionOpen = !_accordionOpen),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F7F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.accent,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Detail Transaksi',
                            style: AppTheme.font(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          AnimatedRotation(
                            turns: _accordionOpen ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _accordionOpen
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Column(
                        children: [
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 10),
                          _detailRow('Waktu Transaksi', timeStr),
                          _detailRow('No. Referensi', item.id),
                          _detailRow('Kategori', item.category),
                          _detailRow('Jenis Transaksi', item.typeLabel),
                          if (item.note != null && item.note!.isNotEmpty)
                            _detailRow('Catatan', item.note!),
                          _detailRow(
                            'Biaya Admin',
                            'Gratis (Rp 0)',
                            color: AppColors.accent,
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Transaksi',
                                style: AppTheme.font(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                amountStr,
                                style: AppTheme.font(
                                  fontSize: 15,
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
            ),

            const SizedBox(height: 20),

            // Tombol Bagikan & Tutup
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                    label: Text(
                      'Bagikan',
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    onPressed: () {
                      AppToast.show(
                        context,
                        'Bukti transaksi berhasil disalin & siap dibagikan',
                        type: ToastType.success,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Tutup',
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.font(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTheme.font(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
