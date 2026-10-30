import 'package:flutter/material.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import '../state/pos_state.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final PosState posState;
  const HistoryScreen({super.key, required this.posState});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = false;
  List<TransactionRecord> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final list = await widget.posState.api.getTransactions();
      if (mounted) {
        setState(() => _transactions = list);
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(child: Text('Belum ada riwayat transaksi.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final tx = _transactions[idx];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          tx.studentName ?? 'Santri',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${tx.invoiceNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (tx.outletName != null)
                              Text(
                                tx.outletName!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          widget.posState.formatCurrency(tx.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
