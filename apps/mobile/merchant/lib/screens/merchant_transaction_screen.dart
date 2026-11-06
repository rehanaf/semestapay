import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import '../state/pos_state.dart';
import '../theme/app_theme.dart';
import 'merchant_tap_card_screen.dart';

class MerchantTransactionScreen extends StatefulWidget {
  final PosState posState;
  final bool isCashOut;

  const MerchantTransactionScreen({
    super.key,
    required this.posState,
    this.isCashOut = false,
  });

  @override
  State<MerchantTransactionScreen> createState() => _MerchantTransactionScreenState();
}

class _MerchantTransactionScreenState extends State<MerchantTransactionScreen>
    with SingleTickerProviderStateMixin {
  String _rawDigits = '';
  int _cursorIndex = 0;

  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  final GlobalKey _amountTextKey = GlobalKey();

  bool _isNumpadVisible = true;

  late final AnimationController _cursorAnimController;
  late final Animation<double> _cursorAnim;

  @override
  void initState() {
    super.initState();
    _cursorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _cursorAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _cursorAnimController, curve: Curves.easeInOut),
    );

    _noteFocusNode.addListener(() {
      if (_noteFocusNode.hasFocus) {
        setState(() {
          _isNumpadVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _cursorAnimController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _resetCursorBlink() {
    _cursorAnimController.reset();
    _cursorAnimController.repeat(reverse: true);
  }

  int get _numericAmount {
    return int.tryParse(_rawDigits) ?? 0;
  }

  String get _formattedAmount {
    return NumberInputHelper.format(_rawDigits);
  }

  int get _formattedCursorOffset {
    return NumberInputHelper.offsetForDigitCount(_formattedAmount, _cursorIndex);
  }

  void _onKeyPressed(String key) {
    if (_noteFocusNode.hasFocus) {
      _noteFocusNode.unfocus();
    }
    _isNumpadVisible = true;

    if (_rawDigits.isEmpty && (key == '0' || key == '000')) {
      return;
    }

    if (_rawDigits.length + key.length > 12) {
      return;
    }

    final clampedCursor = _cursorIndex.clamp(0, _rawDigits.length);
    final before = _rawDigits.substring(0, clampedCursor);
    final after = _rawDigits.substring(clampedCursor);

    _rawDigits = before + key + after;
    _cursorIndex = clampedCursor + key.length;

    _resetCursorBlink();
    setState(() {});
  }

  void _onBackspacePressed() {
    if (_noteFocusNode.hasFocus) {
      _noteFocusNode.unfocus();
    }
    _isNumpadVisible = true;

    if (_rawDigits.isEmpty || _cursorIndex <= 0) return;

    final clampedCursor = _cursorIndex.clamp(0, _rawDigits.length);
    final before = _rawDigits.substring(0, clampedCursor - 1);
    final after = _rawDigits.substring(clampedCursor);

    _rawDigits = before + after;
    _cursorIndex = clampedCursor - 1;

    _resetCursorBlink();
    setState(() {});
  }

  void _onClearAll() {
    _rawDigits = '';
    _cursorIndex = 0;
    _resetCursorBlink();
    setState(() {});
  }

  void _setDirectAmount(int amount) {
    if (_noteFocusNode.hasFocus) {
      _noteFocusNode.unfocus();
    }
    _isNumpadVisible = true;

    _rawDigits = amount.toString();
    _cursorIndex = _rawDigits.length;

    _resetCursorBlink();
    setState(() {});
  }

  void _addAmount(int amountToAdd) {
    final current = _numericAmount;
    final total = current + amountToAdd;
    _setDirectAmount(total);
  }

  void _handleAmountTap(TapUpDetails details) {
    if (_noteFocusNode.hasFocus) {
      _noteFocusNode.unfocus();
    }
    _isNumpadVisible = true;

    if (_rawDigits.isEmpty) {
      _cursorIndex = 0;
      _resetCursorBlink();
      setState(() {});
      return;
    }

    final formatted = _formattedAmount;
    final textPainter = TextPainter(
      text: TextSpan(
        text: formatted,
        style: AppTheme.font(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final renderBox = _amountTextKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPos = renderBox.globalToLocal(details.globalPosition);
      final position = textPainter.getPositionForOffset(localPos);
      final formattedOffset = position.offset;

      _cursorIndex = NumberInputHelper.countDigitsBefore(formatted, formattedOffset);
    } else {
      _cursorIndex = _rawDigits.length;
    }

    _resetCursorBlink();
    setState(() {});
  }

  void _proceedToTapCard() {
    if (_numericAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Masukkan nominal pembayaran terlebih dahulu',
            style: AppTheme.font(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final formatted = _formattedAmount;
    final note = _noteController.text.trim();

    widget.posState.setManualAmount(_numericAmount.toDouble());
    if (note.isNotEmpty) widget.posState.setNote(note);

    // Navigasi ke Step 2: UI Tap Kartu dengan Simulasi Tap
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantTapCardScreen(
          posState: widget.posState,
          amount: formatted,
          rawAmount: _numericAmount,
          note: note,
          isCashOut: widget.isCashOut,
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
          icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isCashOut ? 'Kas Keluar' : 'Transaksi Kasir',
          style: AppTheme.font(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Area Atas Scrollable
            Expanded(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _isNumpadVisible = false;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStoreHeader(),
                      const SizedBox(height: 14),
                      _buildAmountCard(),
                      const SizedBox(height: 12),
                      _buildNoteInput(),
                      const SizedBox(height: 12),
                      _buildQuickChips(),
                    ],
                  ),
                ),
              ),
            ),

            // Area Bawah: Numpad + Tombol Lanjutkan
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.merchantLightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, color: AppColors.merchantPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.posState.merchantSummary?.name ??
                            widget.posState.outletName,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Outlet: ${widget.posState.outletName} • ${widget.posState.outletCode}',
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    final formatted = _formattedAmount;
    final cursorOffset = _formattedCursorOffset;

    final numberStyle = AppTheme.font(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: -0.3,
    );

    final hintStyle = AppTheme.font(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      color: AppColors.textLight.withValues(alpha: 0.45),
      letterSpacing: -0.3,
    );

    double caretX = 0;
    if (_rawDigits.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(text: formatted, style: numberStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final caret = textPainter.getOffsetForCaret(
        TextPosition(offset: cursorOffset),
        const Rect.fromLTWH(0, 0, 2.5, 32),
      );
      caretX = caret.dx;
    }

    return GestureDetector(
      onTapUp: _handleAmountTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          // BORDER DIHILANGKAN
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 10,
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
                Text(
                  widget.isCashOut ? 'Nominal Kas Keluar' : 'Nominal Kas Masuk',
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rp dengan warna sama dengan angka
                Text(
                  'Rp',
                  style: AppTheme.font(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),

                // Area angka & kursor overlay
                Expanded(
                  child: KeyedSubtree(
                    key: _amountTextKey,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          Text(
                            _rawDigits.isEmpty ? '0' : formatted,
                            style: _rawDigits.isEmpty ? hintStyle : numberStyle,
                          ),
                          if (_isNumpadVisible)
                            Positioned(
                              left: _rawDigits.isEmpty ? 0 : caretX,
                              top: 2,
                              bottom: 2,
                              child: _buildBlinkingCursor(),
                            ),
                        ],
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

  Widget _buildBlinkingCursor() {
    return AnimatedBuilder(
      animation: _cursorAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _cursorAnim.value,
          child: Container(
            width: 2.5,
            decoration: BoxDecoration(
              color: AppColors.merchantPrimary,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _noteController,
        focusNode: _noteFocusNode,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        maxLength: 50,
        style: AppTheme.font(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          prefixIcon: const Icon(
            Icons.receipt_long_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          hintText: 'Nomor meja / catatan kasir (opsional)...',
          hintStyle: AppTheme.font(
            fontSize: 13,
            color: AppColors.textLight,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildQuickChips() {
    final chips = [
      {'label': '+10 rb', 'amount': 10000},
      {'label': '+25 rb', 'amount': 25000},
      {'label': '+50 rb', 'amount': 50000},
      {'label': '+100 rb', 'amount': 100000},
      {'label': '+200 rb', 'amount': 200000},
      {'label': 'Pas 50 rb', 'amount': 50000, 'set': true},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: chips.map((c) {
          final isSet = c['set'] == true;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (isSet) {
                  _setDirectAmount(c['amount'] as int);
                } else {
                  _addAmount(c['amount'] as int);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  c['label'] as String,
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanjutkanButton({required bool hasAmount}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: hasAmount ? AppColors.merchantPrimary : const Color(0xFFD3D8E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: hasAmount ? _proceedToTapCard : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Lanjutkan ke Tap Kartu',
              style: AppTheme.font(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final hasAmount = _numericAmount > 0;
    final showNumpad = _isNumpadVisible;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 240),
          crossFadeState: showNumpad
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 2),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              _buildNumpad(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: _buildLanjutkanButton(hasAmount: hasAmount),
              ),
            ],
          ),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: _buildLanjutkanButton(hasAmount: hasAmount),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['000', '0', 'backspace'],
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildNumpadKey(key),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNumpadKey(String key) {
    final isBackspace = key == 'backspace';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isBackspace) {
            _onBackspacePressed();
          } else {
            _onKeyPressed(key);
          }
        },
        onLongPress: isBackspace ? _onClearAll : null,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.merchantPrimary.withValues(alpha: 0.12),
        highlightColor: AppColors.merchantPrimary.withValues(alpha: 0.06),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: isBackspace
                ? const Icon(
                    Icons.backspace_outlined,
                    size: 20,
                    color: AppColors.textPrimary,
                  )
                : Text(
                    key,
                    style: AppTheme.font(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper input angka (dipakai untuk mengatur posisi kursor) ───────────────
class NumberInputHelper {
  static String format(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static String extractDigits(String formatted) {
    return formatted.replaceAll('.', '');
  }

  static int countDigitsBefore(String text, int offset) {
    int count = 0;
    final clamped = offset.clamp(0, text.length);
    for (int i = 0; i < clamped; i++) {
      if (text[i] != '.') count++;
    }
    return count;
  }

  static int offsetForDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;
    int digitsSeen = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (formatted[i] != '.') {
        digitsSeen++;
        if (digitsSeen == digitCount) {
          return i + 1;
        }
      }
    }
    return formatted.length;
  }
}
