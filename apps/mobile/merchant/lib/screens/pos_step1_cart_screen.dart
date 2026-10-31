import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  late TextEditingController _amountController;
  final FocusNode _focusNode = FocusNode();

  final List<double> _addShortcuts = [
    500,
    1000,
    2000,
    5000,
    10000,
    20000,
    50000,
  ];

  @override
  void initState() {
    super.initState();
    final current = widget.posState.manualAmount;
    final initialText = current > 0 ? current.toInt().toString() : '';
    _amountController = TextEditingController(text: initialText);
    _amountController.selection =
        TextSelection.collapsed(offset: initialText.length);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    final text = _amountController.text;
    final selection = _amountController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    if (text.length + key.length > 9) return; // Prevent overflow

    final newText = text.replaceRange(start, end, key);
    final newOffset = start + key.length;

    setState(() {
      _amountController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
      _syncAmount();
    });
  }

  void _onDelete() {
    final text = _amountController.text;
    final selection = _amountController.selection;
    if (text.isEmpty) return;

    final start = selection.start;
    final end = selection.end;

    if (start != end) {
      // Range delete
      final newText = text.replaceRange(start, end, '');
      setState(() {
        _amountController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start),
        );
        _syncAmount();
      });
    } else if (start > 0) {
      // Single char delete before cursor
      final newText = text.replaceRange(start - 1, start, '');
      setState(() {
        _amountController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start - 1),
        );
        _syncAmount();
      });
    }
  }

  void _onClear() {
    setState(() {
      _amountController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      _syncAmount();
    });
  }

  void _addAmount(double addVal) {
    final current = double.tryParse(_amountController.text) ?? 0.0;
    final next = current + addVal;
    final nextStr = next.toInt().toString();

    setState(() {
      _amountController.value = TextEditingValue(
        text: nextStr,
        selection: TextSelection.collapsed(offset: nextStr.length),
      );
      _syncAmount();
    });
  }

  void _syncAmount() {
    final parsed = double.tryParse(_amountController.text) ?? 0.0;
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

  String _formatChipText(double amt) {
    final f = NumberFormat('#,###', 'id_ID');
    return '+${f.format(amt.toInt())}';
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
              if (_amountController.text.isNotEmpty)
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
                  // Top Outlet / Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Outlet: ${widget.posState.outletName}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Text(
                        'Tap angka untuk atur kursor',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Amount Display Card with interactive Caret/Cursor
                  Card(
                    color: AppTheme.darkBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: InkWell(
                      onTap: () => _focusNode.requestFocus(),
                      borderRadius: BorderRadius.circular(20),
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
                            const SizedBox(height: 10),
                            // Caret Input Display
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Rp ',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Flexible(
                                  child: IntrinsicWidth(
                                    child: TextField(
                                      controller: _amountController,
                                      focusNode: _focusNode,
                                      readOnly: true,
                                      showCursor: true,
                                      autofocus: true,
                                      cursorColor: AppTheme.primaryColor,
                                      cursorWidth: 3.0,
                                      cursorRadius: const Radius.circular(2),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: '0',
                                        hintStyle: TextStyle(
                                          color: Colors.white30,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        filled: false,
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Additive Shortcut Chips (+500, +1000, +2000, ...)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _addShortcuts.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 8),
                      itemBuilder: (ctx, idx) {
                        final addVal = _addShortcuts[idx];
                        return ActionChip(
                          label: Text(
                            _formatChipText(addVal),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                          onPressed: () => _addAmount(addVal),
                        );
                      },
                    ),
                  ),

                  // Spacer pushes numpad down directly above the action button!
                  const Spacer(),

                  // Custom On-Screen Numpad with "000"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CustomNumpad(
                      onKeyPressed: _onKeyPress,
                      onDeletePressed: _onDelete,
                      onClearPressed: _onClear,
                      isPin: false,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Action Button: Lanjut ke Tap Kartu
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
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
                          Text(
                            '(${widget.posState.formatCurrency(grandTotal)})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
