import 'package:flutter/material.dart';
import '../state/pos_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_numpad.dart';
import 'pos_step2_tap_screen.dart';

class PosStep1CartScreen extends StatefulWidget {
  final PosState posState;
  const PosStep1CartScreen({super.key, required this.posState});

  @override
  State<PosStep1CartScreen> createState() => _PosStep1CartScreenState();
}

class _PosStep1CartScreenState extends State<PosStep1CartScreen> {
  String _amountStr = '';

  final List<double> _presetAmounts = [
    5000,
    10000,
    15000,
    20000,
    50000,
    100000,
  ];

  @override
  void initState() {
    super.initState();
    final current = widget.posState.manualAmount;
    if (current > 0) {
      _amountStr = current.toInt().toString();
    }
  }

  void _onKeyPress(String key) {
    if (_amountStr.length >= 8) return; // Prevent absurdly long numbers
    setState(() {
      if (_amountStr == '0' || _amountStr.isEmpty) {
        if (key != '0' && key != '00') {
          _amountStr = key;
        }
      } else {
        _amountStr += key;
      }
      _syncAmount();
    });
  }

  void _onDelete() {
    if (_amountStr.isEmpty) return;
    setState(() {
      _amountStr = _amountStr.substring(0, _amountStr.length - 1);
      _syncAmount();
    });
  }

  void _onClear() {
    setState(() {
      _amountStr = '';
      _syncAmount();
    });
  }

  void _setPreset(double amount) {
    setState(() {
      _amountStr = amount.toInt().toString();
      _syncAmount();
    });
  }

  void _syncAmount() {
    final parsed = double.tryParse(_amountStr) ?? 0.0;
    widget.posState.setManualAmount(parsed);
  }

  void _proceedToTap() {
    if (widget.posState.grandTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nominal pembayaran terlebih dahulu.'),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
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
            title: const Text('Input Nominal Transaksi'),
            actions: [
              if (_amountStr.isNotEmpty)
                TextButton(
                  onPressed: _onClear,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: AppTheme.dangerColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount Display Card (Fixed, never wraps down)
                  Card(
                    color: AppTheme.darkBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'NOMINAL PEMBAYARAN',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // FittedBox guarantees the amount never wraps onto a second line!
                          SizedBox(
                            height: 48,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.posState.formatCurrency(grandTotal),
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Outlet: ${widget.posState.outletName}',
                            style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Preset Chips (Horizontal Scrollable)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _presetAmounts.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 8),
                      itemBuilder: (ctx, idx) {
                        final amt = _presetAmounts[idx];
                        final isSelected = grandTotal == amt;
                        return ChoiceChip(
                          label: Text(
                            widget.posState.formatCurrency(amt),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: Colors.white,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          onSelected: (_) => _setPreset(amt),
                        );
                      },
                    ),
                  ),

                  const Spacer(),

                  // Custom On-Screen Numpad
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CustomNumpad(
                      onKeyPressed: _onKeyPress,
                      onDeletePressed: _onDelete,
                      onClearPressed: _onClear,
                      isPin: false,
                    ),
                  ),

                  const Spacer(),

                  // Action Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: grandTotal > 0
                          ? AppTheme.primaryColor
                          : const Color(0xFFCBD5E1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: grandTotal > 0 ? _proceedToTap : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Lanjut ke Tap Kartu',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
