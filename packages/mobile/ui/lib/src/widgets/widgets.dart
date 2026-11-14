import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaLogo — brand mark used on auth / splash screens.
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaLogo extends StatelessWidget {
  final double size;
  final bool merchant;
  final IconData? icon;
  final bool showShadow;

  const SemestaLogo({
    super.key,
    this.size = 56,
    this.merchant = false,
    this.icon,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = merchant
        ? const [AppColors.merchantPrimary, AppColors.merchantAccent]
        : const [AppColors.primary, AppColors.accent];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.32),
                  blurRadius: size * 0.3,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon ??
            (merchant
                ? Icons.storefront_rounded
                : Icons.account_balance_rounded),
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaCard — global surface card.
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  const SemestaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.gradient,
    this.borderColor,
    this.radius = 20,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1.2),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: child,
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaPrimaryButton — global filled CTA button.
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? foregroundColor;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final double radius;
  final bool expanded;

  const SemestaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.foregroundColor,
    this.icon,
    this.isLoading = false,
    this.height = 54,
    this.radius = 14,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        foregroundColor: foregroundColor ?? Colors.white,
        disabledBackgroundColor:
            (color ?? Theme.of(context).colorScheme.primary)
                .withValues(alpha: 0.35),
        elevation: 0,
        minimumSize: Size(expanded ? double.infinity : 0, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: AppTheme.font(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    return button;
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaOutlineButton
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final double height;

  const SemestaOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.icon,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: c,
        minimumSize: Size(double.infinity, height),
        side: BorderSide(color: c.withValues(alpha: 0.4), width: 1.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: AppTheme.font(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaTextField — labelled input used across auth & forms.
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const SemestaTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTheme.font(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 7),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          enabled: enabled,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          style: AppTheme.font(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 20, color: AppColors.textSecondary),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaBadge
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? background;
  final IconData? icon;

  const SemestaBadge({
    super.key,
    required this.label,
    this.color,
    this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTheme.font(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaSectionHeader — title + optional action.
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const SemestaSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(
            title,
            style: AppTheme.font(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: AppTheme.font(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaAvatar
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaAvatar extends StatelessWidget {
  final String? name;
  final double size;
  final bool merchant;
  final Color? background;

  const SemestaAvatar({
    super.key,
    this.name,
    this.size = 44,
    this.merchant = false,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final initial = (name == null || name!.trim().isEmpty)
        ? '?'
        : name!.trim().substring(0, 1).toUpperCase();
    final colors = merchant
        ? const [AppColors.merchantPrimary, AppColors.merchantAccent]
        : const [AppColors.primary, AppColors.accent];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        gradient: background == null
            ? LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTheme.font(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaEmptyState
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const SemestaEmptyState({
    super.key,
    this.icon = Icons.inbox_rounded,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 34, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.font(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTheme.font(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaInfoBanner — inline error / info message.
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaInfoBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final IconData? icon;

  const SemestaInfoBanner({
    super.key,
    required this.message,
    this.isError = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isError ? AppColors.error : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            icon ??
                (isError
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded),
            size: 19,
            color: color,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: AppTheme.font(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaSheetHandle
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaSheetHandle extends StatelessWidget {
  const SemestaSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 5,
      margin: const EdgeInsets.only(top: 10, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaNavItemData + SemestaBottomNavBar
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaNavItemData {
  final IconData icon;
  final String label;

  const SemestaNavItemData({required this.icon, required this.label});
}

class SemestaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SemestaNavItemData> items;
  final Color? activeColor;
  final Color? backgroundColor;
  final Widget? centerButton;
  final String? centerLabel;

  const SemestaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.activeColor,
    this.backgroundColor,
    this.centerButton,
    this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? Theme.of(context).colorScheme.primary;
    final left = items.sublist(0, items.length ~/ 2);
    final right = items.sublist(items.length ~/ 2);

    Widget navRow(List<SemestaNavItemData> list, int offset) {
      return Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(list.length, (i) {
            final index = offset + i;
            return _buildItem(list[i], index, active);
          }),
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: centerButton == null ? 64 : 80,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: backgroundColor ?? AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    navRow(left, 0),
                    if (centerButton != null) const SizedBox(width: 76),
                    navRow(right, left.length),
                  ],
                ),
              ),
              if (centerButton != null)
                Positioned(
                  top: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      centerButton!,
                      if (centerLabel != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          centerLabel!,
                          style: AppTheme.font(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: active,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(SemestaNavItemData item, int index, Color active) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 23,
              color: isActive ? active : AppColors.textLight,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: AppTheme.font(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? active : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaKeypad — shared numeric keypad.
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaKeypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final Color? keyColor;
  final Color? backspaceColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool transactionStyle;
  final bool showTripleZero;
  final VoidCallback? onClear;
  final Color? interactionColor;

  const SemestaKeypad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    this.keyColor,
    this.backspaceColor,
    this.actionLabel,
    this.onAction,
    this.transactionStyle = false,
    this.showTripleZero = false,
    this.onClear,
    this.interactionColor,
  });

  @override
  Widget build(BuildContext context) {
    final keyText = AppTheme.font(
      fontSize: transactionStyle ? 21 : 22,
      fontWeight: transactionStyle ? FontWeight.w700 : FontWeight.w600,
      color: AppColors.textPrimary,
    );

    Widget key(String value) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onKey(value);
          },
          borderRadius: BorderRadius.circular(transactionStyle ? 12 : 14),
          splashColor: (interactionColor ?? AppColors.primary).withValues(
            alpha: 0.12,
          ),
          highlightColor: (interactionColor ?? AppColors.primary).withValues(
            alpha: 0.06,
          ),
          child: Ink(
            height: transactionStyle ? 48 : 52,
            decoration: BoxDecoration(
              color: keyColor ??
                  (transactionStyle
                      ? const Color(0xFFF7F9FC)
                      : AppColors.surface),
              borderRadius: BorderRadius.circular(transactionStyle ? 12 : 14),
            ),
            child: Center(child: Text(value, style: keyText)),
          ),
        ),
      );
    }

    Widget backspace() {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onBackspace();
          },
          onLongPress: onClear,
          borderRadius: BorderRadius.circular(transactionStyle ? 12 : 14),
          splashColor: (interactionColor ?? AppColors.primary).withValues(
            alpha: 0.12,
          ),
          highlightColor: (interactionColor ?? AppColors.primary).withValues(
            alpha: 0.06,
          ),
          child: Ink(
            height: transactionStyle ? 48 : 52,
            decoration: BoxDecoration(
              color: backspaceColor ??
                  (transactionStyle
                      ? const Color(0xFFF7F9FC)
                      : AppColors.surface),
              borderRadius: BorderRadius.circular(transactionStyle ? 12 : 14),
            ),
            child: Center(
              child: Icon(
                Icons.backspace_outlined,
                size: transactionStyle ? 20 : 22,
                color: transactionStyle
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    Widget action() {
      if (showTripleZero) return key('000');
      if (actionLabel == null) return const SizedBox.expand();
      return InkWell(
        onTap: onAction,
        borderRadius: BorderRadius.circular(transactionStyle ? 12 : 14),
        child: Container(
          height: transactionStyle ? 48 : 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: keyColor ??
                (transactionStyle
                    ? const Color(0xFFF7F9FC)
                    : AppColors.surface),
            borderRadius: BorderRadius.circular(transactionStyle ? 12 : 14),
          ),
          child: Text(
            actionLabel!,
            style: AppTheme.font(
              fontSize: transactionStyle ? 13 : 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final rows = <List<Widget>>[
      [key('1'), key('2'), key('3')],
      [key('4'), key('5'), key('6')],
      [key('7'), key('8'), key('9')],
      [action(), key('0'), backspace()],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          Row(
            children: [
              for (var j = 0; j < rows[i].length; j++) ...[
                if (!transactionStyle && j > 0) const SizedBox(width: 8),
                Expanded(
                  child: transactionStyle
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: rows[i][j],
                        )
                      : rows[i][j],
                ),
              ],
            ],
          ),
          if (i < rows.length - 1) SizedBox(height: transactionStyle ? 6 : 8),
        ],
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// SemestaIconButton — circular icon button with optional badge.
/// ─────────────────────────────────────────────────────────────────────────────
class SemestaIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;
  final Color? color;
  final double size;

  const SemestaIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
    this.color,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: color ?? AppColors.textPrimary,
              size: size * 0.66,
            ),
          ),
          if (badge != null)
            Positioned(
              right: 1,
              top: 1,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badge',
                  style: AppTheme.font(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
