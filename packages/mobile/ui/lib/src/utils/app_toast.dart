import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tipe toast yang tersedia
enum ToastType { success, error, warning, info }

/// Utility class untuk menampilkan toast notifikasi di seluruh app.
///
/// Penggunaan:
/// ```dart
/// AppToast.show(context, 'Login berhasil!', type: ToastType.success);
/// AppToast.show(context, 'Password salah', type: ToastType.error);
/// AppToast.show(context, 'Koneksi lambat', type: ToastType.warning);
/// AppToast.show(context, 'Sesi akan berakhir', type: ToastType.info);
/// ```
class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Tampilkan toast.
  ///
  /// [message]  : Pesan yang ditampilkan.
  /// [type]     : Tipe toast (success / error / warning / info). Default: info.
  /// [duration] : Durasi tampil. Default: 3 detik.
  /// [position] : Posisi toast (top / bottom). Default: top.
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.top,
  }) {
    // Tutup toast yang sedang tampil dengan aman
    _dismiss();

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        position: position,
        onDismiss: _dismiss,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    if (_currentEntry != null) {
      try {
        if (_currentEntry!.mounted) {
          _currentEntry!.remove();
        }
      } catch (_) {}
      _currentEntry = null;
    }
  }
}

enum ToastPosition { top, bottom }

// ─── Widget Internal ─────────────────────────────────────────────────────────

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final ToastPosition position;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.position,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    final slideBegin = widget.position == ToastPosition.top
        ? const Offset(0, -0.4)
        : const Offset(0, 0.4);

    _slideAnim = Tween<Offset>(
      begin: slideBegin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Konfigurasi visual per tipe
  _ToastStyle get _style {
    switch (widget.type) {
      case ToastType.success:
        return _ToastStyle(
          backgroundColor: const Color(0xFF0E7A4F),
          icon: Icons.check_circle_rounded,
          iconColor: Colors.white,
          label: 'Berhasil',
        );
      case ToastType.error:
        return _ToastStyle(
          backgroundColor: const Color(0xFFCC2C2C),
          icon: Icons.error_rounded,
          iconColor: Colors.white,
          label: 'Error',
        );
      case ToastType.warning:
        return _ToastStyle(
          backgroundColor: const Color(0xFFB45309),
          icon: Icons.warning_rounded,
          iconColor: Colors.white,
          label: 'Peringatan',
        );
      case ToastType.info:
        return _ToastStyle(
          backgroundColor: const Color(0xFF1A56FF),
          icon: Icons.info_rounded,
          iconColor: Colors.white,
          label: 'Info',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final isTop = widget.position == ToastPosition.top;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      top: isTop ? topPadding + 12 : null,
      bottom: isTop ? null : bottomPadding + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: style.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: style.backgroundColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon
                    Icon(style.icon, color: style.iconColor, size: 22),
                    const SizedBox(width: 10),

                    // Pesan
                    Expanded(
                      child: Text(
                        widget.message,
                        style: AppTheme.font(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),

                    // Tombol tutup
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.65),
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastStyle {
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final String label;

  const _ToastStyle({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.label,
  });
}
