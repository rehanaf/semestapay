import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomNumpad extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onClearPressed;
  final bool isPin;

  const CustomNumpad({
    super.key,
    required this.onKeyPressed,
    required this.onDeletePressed,
    this.onClearPressed,
    this.isPin = false,
  });

  Widget _buildKey(
    BuildContext context, {
    String? text,
    IconData? icon,
    VoidCallback? onTap,
    Color? textColor,
    Color? bgColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        highlightColor: AppTheme.primaryColor.withValues(alpha: 0.08),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    size: 24,
                    color: textColor ?? AppTheme.textPrimary,
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text ?? '',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textColor ?? AppTheme.textPrimary,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: 1, 2, 3
        _buildRow(context, ['1', '2', '3']),
        const SizedBox(height: 10),
        // Row 2: 4, 5, 6
        _buildRow(context, ['4', '5', '6']),
        const SizedBox(height: 10),
        // Row 3: 7, 8, 9
        _buildRow(context, ['7', '8', '9']),
        const SizedBox(height: 10),
        // Row 4: Action/00, 0, Backspace
        Row(
          children: [
            // Left Action: "00" for amount, or "C" for PIN/Clear
            Expanded(
              child: SizedBox(
                height: 56,
                child: isPin
                    ? (onClearPressed != null
                        ? _buildKey(
                            context,
                            text: 'C',
                            textColor: AppTheme.dangerColor,
                            bgColor: const Color(0xFFFEF2F2),
                            onTap: onClearPressed,
                          )
                        : const SizedBox.shrink())
                    : _buildKey(
                        context,
                        text: '00',
                        onTap: () => onKeyPressed('00'),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            // Middle: 0
            Expanded(
              child: SizedBox(
                height: 56,
                child: _buildKey(
                  context,
                  text: '0',
                  onTap: () => onKeyPressed('0'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Right Action: Backspace
            Expanded(
              child: SizedBox(
                height: 56,
                child: _buildKey(
                  context,
                  icon: Icons.backspace_outlined,
                  textColor: AppTheme.textSecondary,
                  bgColor: const Color(0xFFF1F5F9),
                  onTap: onDeletePressed,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: SizedBox(
              height: 56,
              child: _buildKey(
                context,
                text: key,
                onTap: () => onKeyPressed(key),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PinDotsIndicator extends StatelessWidget {
  final int totalDots;
  final int filledCount;

  const PinDotsIndicator({
    super.key,
    this.totalDots = 6,
    required this.filledCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (index) {
        final isFilled = index < filledCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: isFilled ? 18 : 16,
          height: isFilled ? 18 : 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppTheme.primaryColor : Colors.transparent,
            border: Border.all(
              color: isFilled ? AppTheme.primaryColor : const Color(0xFFCBD5E1),
              width: 2,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
