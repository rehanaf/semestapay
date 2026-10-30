import 'package:flutter/material.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import '../state/pos_state.dart';
import '../theme/app_theme.dart';
import 'pos_step2_tap_screen.dart';

class PosStep1CartScreen extends StatefulWidget {
  final PosState posState;
  const PosStep1CartScreen({super.key, required this.posState});

  @override
  State<PosStep1CartScreen> createState() => _PosStep1CartScreenState();
}

class _PosStep1CartScreenState extends State<PosStep1CartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MerchantItem> _items = [];
  bool _loading = false;
  final TextEditingController _manualController = TextEditingController();

  final List<double> _presetAmounts = [
    5000,
    10000,
    15000,
    20000,
    25000,
    50000,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final list = await widget.posState.api.getItems();
      if (mounted) {
        setState(() => _items = list);
      }
    } catch (_) {
      // offline / mock fallback
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _proceedToTap() {
    if (widget.posState.grandTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih produk atau masukkan nominal terlebih dahulu.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PosStep2TapScreen(posState: widget.posState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.posState,
      builder: (context, _) {
        final grandTotal = widget.posState.grandTotal;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Langkah 1: Pilih Produk / Nominal'),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(icon: Icon(Icons.fastfood_rounded), text: 'Katalog Menu'),
                Tab(icon: Icon(Icons.dialpad_rounded), text: 'Nominal Manual'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: Katalog Produk
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? const Center(child: Text('Tidak ada produk tersedia'))
                      : ListView.separated(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 100,
                          ),
                          itemCount: _items.length,
                          separatorBuilder: (c, i) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final item = _items[idx];
                            final inCart = widget.posState.cartItems.firstWhere(
                              (ci) => ci.item.id == item.id,
                              orElse: () => CartItem(item: item, quantity: 0),
                            );

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.restaurant,
                                        color: AppTheme.primaryColor,
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
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.posState
                                                .formatCurrency(item.price),
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (inCart.quantity > 0) ...[
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            color: AppTheme.dangerColor),
                                        onPressed: () =>
                                            widget.posState.removeItem(item),
                                      ),
                                      Text(
                                        '${inCart.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle,
                                            color: AppTheme.primaryColor),
                                        onPressed: () =>
                                            widget.posState.addItem(item),
                                      ),
                                    ] else ...[
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(70, 36),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                        ),
                                        onPressed: () =>
                                            widget.posState.addItem(item),
                                        child: const Text('Tambah'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

              // TAB 2: Input Manual
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Nominal Transaksi (Rp)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _manualController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: const InputDecoration(
                                prefixText: 'Rp ',
                                hintText: '0',
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val) ?? 0.0;
                                widget.posState.setManualAmount(parsed);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PILIHAN CEPAT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: _presetAmounts.length,
                      itemBuilder: (ctx, idx) {
                        final amt = _presetAmounts[idx];
                        return OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            _manualController.text = amt.toInt().toString();
                            widget.posState.setManualAmount(amt);
                          },
                          child: Text(
                            widget.posState.formatCurrency(amt),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bottom Cart Bar
          bottomSheet: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.posState.cartItems.isNotEmpty
                              ? '${widget.posState.totalItemCount} item dipilih'
                              : 'Total Pembayaran',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          widget.posState.formatCurrency(grandTotal),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: grandTotal > 0 ? _proceedToTap : null,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Lanjut ke Tap'),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
