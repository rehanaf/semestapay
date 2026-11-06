import 'package:flutter/material.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import '../state/pos_state.dart';
import 'merchant_success_screen.dart';
import 'merchant_tap_card_screen.dart' show StudentCardData;

class MerchantHistoryScreen extends StatefulWidget {
  final PosState posState;
  const MerchantHistoryScreen({super.key, required this.posState});

  @override
  State<MerchantHistoryScreen> createState() => _MerchantHistoryScreenState();
}

class _MerchantHistoryScreenState extends State<MerchantHistoryScreen> {
  late Future<List<TransactionRecord>> _future;
  // 'all', 'pemasukan', 'pengeluaran'
  String _filterType = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _future = widget.posState.api.getTransactions();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await _future;
  }

  String _timeLabel(String iso) {
    final time = DateTime.tryParse(iso)?.toLocal();
    if (time == null) return '-';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatRupiah(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _openDetail(TransactionRecord tx) {
    final isCashOut = tx.type.toLowerCase().contains('cash_out');
    final rawAmount = tx.amount.round();

    final studentData = StudentCardData(
      name: tx.studentName ?? 'Santri',
      balance: 0,
      cardNumber: tx.invoiceNumber,
      schoolClass: '-',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantSuccessScreen(
          posState: widget.posState,
          amount: _formatRupiah(rawAmount),
          rawAmount: rawAmount,
          note: '',
          studentData: studentData,
          transactionId: tx.invoiceNumber,
          createdAt: tx.createdAt,
          isCashOut: isCashOut,
          fromHistory: true,
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
          icon: const Icon(Icons.chevron_left_rounded,
              size: 28, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
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
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Chips
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari no. invoice atau nama santri...',
                      hintStyle: AppTheme.font(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: AppColors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim().toLowerCase());
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildFilterChip('Semua', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pemasukan', 'pemasukan'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pengeluaran', 'pengeluaran'),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.merchantPrimary,
                child: FutureBuilder<List<TransactionRecord>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.merchantPrimary,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(
                              'Gagal memuat riwayat',
                              style: AppTheme.font(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.merchantPrimary,
                              ),
                              onPressed: _refresh,
                              child: const Text('Coba Lagi',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }

                    final allList = snapshot.data ?? [];
                    final filtered = allList.where((tx) {
                      final isCashOut =
                          tx.type.toLowerCase().contains('cash_out');
                      if (_filterType == 'pemasukan' && isCashOut) {
                        return false;
                      }
                      if (_filterType == 'pengeluaran' && !isCashOut) {
                        return false;
                      }
                      if (_searchQuery.isNotEmpty) {
                        final invoice = tx.invoiceNumber.toLowerCase();
                        final name = (tx.studentName ?? '').toLowerCase();
                        if (!invoice.contains(_searchQuery) &&
                            !name.contains(_searchQuery)) {
                          return false;
                        }
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: SemestaEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Tidak ada transaksi',
                          subtitle: 'Belum ada transaksi yang sesuai kriteria.',
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        indent: 72,
                        endIndent: 16,
                        color: AppColors.divider,
                      ),
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        final isCashOut =
                            tx.type.toLowerCase().contains('cash_out');
                        final rawAmount = tx.amount.round();

                        return InkWell(
                          onTap: () => _openDetail(tx),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E88E5)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF1E88E5),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.studentName ?? 'Santri',
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.font(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${tx.invoiceNumber} • ${_timeLabel(tx.createdAt)}',
                                        style: AppTheme.font(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isCashOut ? "-" : "+"}Rp ${_formatRupiah(rawAmount)}',
                                      style: AppTheme.font(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isCashOut
                                            ? AppColors.error
                                            : AppColors.merchantPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isCashOut ? 'Pengeluaran' : 'Pemasukan',
                                      style: AppTheme.font(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isCashOut
                                            ? AppColors.error
                                            : AppColors.merchantPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.merchantPrimary
              : AppColors.merchantLightGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTheme.font(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.merchantPrimary,
          ),
        ),
      ),
    );
  }
}
