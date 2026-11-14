import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'widgets.dart';

class SemestaAmountQuickAction {
  final String label;
  final int amount;
  final bool setAmount;

  const SemestaAmountQuickAction({
    required this.label,
    required this.amount,
    this.setAmount = false,
  });
}

typedef SemestaAmountSubmit = FutureOr<void> Function(int amount);

class SemestaAmountFormatter {
  static String format(int amount) {
    final digits = amount.abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }
    return '${amount < 0 ? '-' : ''}${buffer.toString()}';
  }
}

class SemestaAmountEntry extends StatefulWidget {
  final Widget header;
  final String amountLabel;
  final String continueLabel;
  final Color accentColor;
  final String? balanceLabel;
  final String? minimumAmountLabel;
  final int minimumAmount;
  final int initialAmount;
  final int maxDigits;
  final bool isLoading;
  final List<SemestaAmountQuickAction> quickActions;
  final Widget? extraContent;
  final FocusNode? extraContentFocusNode;
  final ValueChanged<int>? onAmountChanged;
  final SemestaAmountSubmit onContinue;

  const SemestaAmountEntry({
    super.key,
    required this.header,
    required this.amountLabel,
    required this.continueLabel,
    required this.onContinue,
    this.accentColor = AppColors.primary,
    this.balanceLabel,
    this.minimumAmountLabel,
    this.minimumAmount = 1,
    this.initialAmount = 0,
    this.maxDigits = 12,
    this.isLoading = false,
    this.quickActions = const [],
    this.extraContent,
    this.extraContentFocusNode,
    this.onAmountChanged,
  });

  @override
  State<SemestaAmountEntry> createState() => _SemestaAmountEntryState();
}

class _SemestaAmountEntryState extends State<SemestaAmountEntry>
    with SingleTickerProviderStateMixin {
  final GlobalKey _amountTextKey = GlobalKey();
  late String _rawDigits;
  late int _cursorIndex;
  bool _isNumpadVisible = true;
  late final AnimationController _cursorController;
  late final Animation<double> _cursorAnimation;

  int get _amount => int.tryParse(_rawDigits) ?? 0;

  String get _formattedAmount => _format(_rawDigits);

  int get _formattedCursorOffset =>
      _offsetForDigitCount(_formattedAmount, _cursorIndex);

  @override
  void initState() {
    super.initState();
    _rawDigits = widget.initialAmount > 0 ? '${widget.initialAmount}' : '';
    _cursorIndex = _rawDigits.length;
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _cursorAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _cursorController, curve: Curves.easeInOut),
    );
    widget.extraContentFocusNode?.addListener(_onExtraContentFocusChanged);
  }

  @override
  void didUpdateWidget(covariant SemestaAmountEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.extraContentFocusNode != widget.extraContentFocusNode) {
      oldWidget.extraContentFocusNode?.removeListener(
        _onExtraContentFocusChanged,
      );
      widget.extraContentFocusNode?.addListener(_onExtraContentFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.extraContentFocusNode?.removeListener(_onExtraContentFocusChanged);
    _cursorController.dispose();
    super.dispose();
  }

  static String _format(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  static int _countDigitsBefore(String text, int offset) {
    var count = 0;
    final clamped = offset.clamp(0, text.length);
    for (var index = 0; index < clamped; index++) {
      if (text[index] != '.') count++;
    }
    return count;
  }

  static int _offsetForDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;
    var digitsSeen = 0;
    for (var index = 0; index < formatted.length; index++) {
      if (formatted[index] != '.') {
        digitsSeen++;
        if (digitsSeen == digitCount) return index + 1;
      }
    }
    return formatted.length;
  }

  void _onExtraContentFocusChanged() {
    if (widget.extraContentFocusNode?.hasFocus == true && _isNumpadVisible) {
      setState(() => _isNumpadVisible = false);
    }
  }

  void _restartCursor() {
    _cursorController
      ..reset()
      ..repeat(reverse: true);
  }

  void _onKey(String value) {
    widget.extraContentFocusNode?.unfocus();
    if (_rawDigits.isEmpty && int.tryParse(value) == 0) return;
    if (_rawDigits.length + value.length > widget.maxDigits) return;

    final cursor = _cursorIndex.clamp(0, _rawDigits.length);
    _rawDigits =
        _rawDigits.substring(0, cursor) + value + _rawDigits.substring(cursor);
    _cursorIndex = cursor + value.length;
    _isNumpadVisible = true;
    _restartCursor();
    _notifyAmountChanged();
  }

  void _onBackspace() {
    widget.extraContentFocusNode?.unfocus();
    if (_rawDigits.isEmpty || _cursorIndex <= 0) {
      setState(() => _isNumpadVisible = true);
      return;
    }
    final cursor = _cursorIndex.clamp(0, _rawDigits.length);
    _rawDigits =
        _rawDigits.substring(0, cursor - 1) + _rawDigits.substring(cursor);
    _cursorIndex = cursor - 1;
    _isNumpadVisible = true;
    _restartCursor();
    _notifyAmountChanged();
  }

  void _clearAmount() {
    _rawDigits = '';
    _cursorIndex = 0;
    _isNumpadVisible = true;
    _restartCursor();
    _notifyAmountChanged();
  }

  void _setAmount(int amount) {
    final digits = amount > 0 ? '$amount' : '';
    if (digits.length > widget.maxDigits) return;
    _rawDigits = digits;
    _cursorIndex = digits.length;
    _isNumpadVisible = true;
    widget.extraContentFocusNode?.unfocus();
    _restartCursor();
    _notifyAmountChanged();
  }

  void _applyQuickAction(SemestaAmountQuickAction action) {
    _setAmount(action.setAmount ? action.amount : _amount + action.amount);
  }

  void _notifyAmountChanged() {
    setState(() {});
    widget.onAmountChanged?.call(_amount);
  }

  void _handleAmountTap(TapUpDetails details) {
    widget.extraContentFocusNode?.unfocus();
    _isNumpadVisible = true;
    if (_rawDigits.isEmpty) {
      _cursorIndex = 0;
      _restartCursor();
      setState(() {});
      return;
    }

    final style = AppTheme.font(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      letterSpacing: -0.3,
    );
    final painter = TextPainter(
      text: TextSpan(text: _formattedAmount, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final renderBox =
        _amountTextKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPosition = renderBox.globalToLocal(details.globalPosition);
      final textPosition = painter.getPositionForOffset(localPosition);
      _cursorIndex = _countDigitsBefore(
        _formattedAmount,
        textPosition.offset,
      );
    } else {
      _cursorIndex = _rawDigits.length;
    }
    _restartCursor();
    setState(() {});
  }

  Future<void> _submit() async {
    if (_amount < widget.minimumAmount) return;
    FocusScope.of(context).unfocus();
    await widget.onContinue(_amount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _isNumpadVisible = false);
            },
            behavior: HitTestBehavior.opaque,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.header,
                  const SizedBox(height: 14),
                  _buildAmountCard(),
                  if (widget.extraContent != null) ...[
                    const SizedBox(height: 12),
                    widget.extraContent!,
                  ],
                  if (widget.quickActions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                  ],
                ],
              ),
            ),
          ),
        ),
        _buildBottomSection(),
      ],
    );
  }

  Widget _buildAmountCard() {
    final amountStyle = AppTheme.font(
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
    var caretX = 0.0;
    if (_rawDigits.isNotEmpty) {
      final painter = TextPainter(
        text: TextSpan(text: _formattedAmount, style: amountStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      caretX = painter
          .getOffsetForCaret(
            TextPosition(offset: _formattedCursorOffset),
            const Rect.fromLTWH(0, 0, 2.5, 32),
          )
          .dx;
    }

    return GestureDetector(
      onTapUp: _handleAmountTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
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
                  widget.amountLabel,
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (widget.balanceLabel != null)
                  Text(
                    widget.balanceLabel!,
                    style: AppTheme.font(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Rp',
                  style: AppTheme.font(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
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
                            _rawDigits.isEmpty ? '0' : _formattedAmount,
                            style: _rawDigits.isEmpty ? hintStyle : amountStyle,
                            key: const Key('semesta-amount-display'),
                          ),
                          if (_isNumpadVisible)
                            Positioned(
                              left: _rawDigits.isEmpty ? 0 : caretX,
                              top: 2,
                              bottom: 2,
                              child: AnimatedBuilder(
                                animation: _cursorAnimation,
                                builder: (context, child) => Opacity(
                                  opacity: _cursorAnimation.value,
                                  child: Container(
                                    width: 2.5,
                                    decoration: BoxDecoration(
                                      color: widget.accentColor,
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.minimumAmountLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.minimumAmountLabel!,
                style: AppTheme.font(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: widget.quickActions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _applyQuickAction(action),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  action.label,
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

  Widget _buildBottomSection() {
    final hasAmount = _amount >= widget.minimumAmount;
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
          crossFadeState: _isNumpadVisible
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
              SemestaKeypad(
                onKey: _onKey,
                onBackspace: _onBackspace,
                onClear: _clearAmount,
                showTripleZero: true,
                transactionStyle: true,
                interactionColor: widget.accentColor,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: _buildContinueButton(hasAmount),
              ),
            ],
          ),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: _buildContinueButton(hasAmount),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(bool hasAmount) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              hasAmount ? widget.accentColor : const Color(0xFFD3D8E8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: hasAmount && !widget.isLoading ? _submit : null,
        child: widget.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.continueLabel,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.font(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
      ),
    );
  }
}
