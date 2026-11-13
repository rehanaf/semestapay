import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import '../state/kiosk_state.dart';

class KioskHistoryScreen extends StatefulWidget {
  final KioskState state;

  const KioskHistoryScreen({super.key, required this.state});

  @override
  State<KioskHistoryScreen> createState() => _KioskHistoryScreenState();
}

class _KioskHistoryScreenState extends State<KioskHistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.state.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: widget.state.refresh,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final mutations = widget.state.mutations;
          if (widget.state.loadingDashboard && mutations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (mutations.isEmpty) {
            return const SemestaEmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Belum ada transaksi',
              subtitle: 'Semua transaksi dompet santri akan tampil di sini.',
            );
          }
          return RefreshIndicator(
            onRefresh: widget.state.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: mutations.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final m = mutations[index];
                return SemestaHistoryTile(
                  title: m.merchant ?? m.outlet ?? _typeLabel(m.type),
                  subtitle:
                      '${widget.state.formatDate(m.createdAt)} • ${_typeLabel(m.type)}',
                  amount: m.amount,
                  isCredit: m.isCredit,
                  status: m.status,
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'payment':
        return 'Pembayaran';
      case 'topup':
        return 'Top Up Saldo';
      case 'transfer_in':
        return 'Transfer Masuk';
      case 'transfer_out':
        return 'Transfer Keluar';
      case 'adjustment':
        return 'Penyesuaian Saldo';
      default:
        return type.replaceAll('_', ' ');
    }
  }
}
