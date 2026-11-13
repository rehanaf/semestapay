import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import '../state/kiosk_state.dart';

/// Layar utama Kiosk: deteksi tap kartu RFID lalu masuk ke input PIN.
class KioskTapScreen extends StatefulWidget {
  final KioskState state;

  const KioskTapScreen({super.key, required this.state});

  @override
  State<KioskTapScreen> createState() => _KioskTapScreenState();
}

class _KioskTapScreenState extends State<KioskTapScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rippleController;
  late final AnimationController _successController;
  late final Animation<double> _glowAnim;

  final StringBuffer _keyBuffer = StringBuffer();
  DateTime _lastKeyTime = DateTime.now();

  CardReadResponse? _card;
  bool _scanning = false;
  String? _error;

  // PIN state
  String _pin = '';
  bool _pinError = false;
  String? _pinMessage;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _rippleController.dispose();
    _successController.dispose();
    super.dispose();
  }

  bool _handleHardwareKey(KeyEvent event) {
    // Saat sudah di layar PIN, biarkan keypad yang menangani input.
    if (_card != null) return false;
    if (event is! KeyDownEvent) return false;

    final now = DateTime.now();
    if (now.difference(_lastKeyTime).inMilliseconds > 500) {
      _keyBuffer.clear();
    }
    _lastKeyTime = now;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final uid = _keyBuffer.toString().trim();
      _keyBuffer.clear();
      if (uid.length >= 3) {
        _processCard(uid);
        return true;
      }
    } else if (event.character != null && event.character!.isNotEmpty) {
      _keyBuffer.write(event.character);
    }
    return false;
  }

  Future<void> _processCard(String uid) async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _error = null;
    });

    try {
      final card = await widget.state.readCard(uid);
      if (!mounted) return;
      await _successController.forward(from: 0);
      if (!mounted) return;
      setState(() {
        _card = card;
        _pin = '';
        _pinError = false;
        _pinMessage = null;
        _scanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _error = e is ApiException
            ? e.message
            : 'Kartu tidak dikenali. Silakan tap ulang.';
      });
    }
  }

  void _onKey(String digit) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += digit;
      _pinError = false;
      _pinMessage = null;
    });
    if (_pin.length == 6) _submitPin();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submitPin() async {
    if (_pin.length < 6) {
      setState(() {
        _pinError = true;
        _pinMessage = 'Masukkan 6 digit PIN.';
      });
      return;
    }
    setState(() {
      _pinError = false;
      _pinMessage = null;
    });

    try {
      await widget.state.loginWithPin(_pin);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pin = '';
        _pinError = true;
        _pinMessage = e is ApiException
            ? e.message
            : 'PIN salah. Silakan coba lagi.';
      });
    }
  }

  void _cancelPin() {
    widget.state.clearScannedCard();
    setState(() {
      _card = null;
      _pin = '';
      _pinError = false;
      _pinMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onRetryBoot: widget.state.bootError == null ? null : widget.state.bootstrap),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _card == null
                        ? _buildTapView()
                        : _buildPinView(),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'SemestaPAY Kiosk • Stasiun Mandiri Santri',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Layar tap kartu ────────────────────────────────────────────────────────

  Widget _buildTapView() {
    return Column(
      key: const ValueKey('tap'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Tap Kartu Santri',
          style: AppTheme.font(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tempelkan kartu RFID pada mesin pembaca untuk memulai.',
          textAlign: TextAlign.center,
          style: AppTheme.font(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 36),
        AnimatedBuilder(
          animation: _rippleController,
          builder: (context, child) {
            return SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    _buildRipple(
                      progress: (_rippleController.value + i / 3) % 1,
                    ),
                  child!,
                ],
              ),
            );
          },
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, _) {
              return Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: 0.25 + 0.15 * _glowAnim.value,
                      ),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _scanning
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(
                        Icons.contactless_rounded,
                        size: 68,
                        color: Colors.white,
                      ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        if (_error != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SemestaInfoBanner(message: _error!, isError: true),
          ),
        if (_error != null) const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _scanning ? null : _simulateTap,
          icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
          label: const Text('Simulasi tap kartu (demo)'),
        ),
      ],
    );
  }

  Future<void> _simulateTap() async {
    final uid = await widget.state.resolveDemoCardUid();
    if (!mounted) return;
    _processCard(uid);
  }

  Widget _buildRipple({required double progress}) {
    final size = 150 + (110 * progress);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35 * (1 - progress)),
          width: 1.5,
        ),
      ),
    );
  }

  // ── Layar PIN ──────────────────────────────────────────────────────────────

  Widget _buildPinView() {
    final card = _card!;
    return ConstrainedBox(
      key: const ValueKey('pin'),
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SemestaAvatar(name: card.student.name, size: 64),
          const SizedBox(height: 12),
          Text(
            card.student.name,
            textAlign: TextAlign.center,
            style: AppTheme.font(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${card.student.nis} • ${card.student.className ?? "Santri"}',
            style: AppTheme.font(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          SemestaBadge(
            label: 'Saldo ${widget.state.formatCurrency(card.wallet.balance)}',
            icon: Icons.account_balance_wallet_rounded,
          ),
          const SizedBox(height: 24),
          Text(
            'Masukkan PIN Keamanan',
            style: AppTheme.font(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final filled = index < _pin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: filled ? 15 : 13,
                height: filled ? 15 : 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? AppColors.primary
                      : AppColors.surface,
                  border: Border.all(
                    color: _pinError
                        ? AppColors.error
                        : (filled ? AppColors.primary : AppColors.divider),
                    width: 2,
                  ),
                ),
              );
            }),
          ),
          if (_pinMessage != null) ...[
            const SizedBox(height: 14),
            SemestaInfoBanner(message: _pinMessage!, isError: true),
          ],
          const SizedBox(height: 22),
          SemestaKeypad(
            onKey: _onKey,
            onBackspace: _onBackspace,
            actionLabel: 'Batal',
            onAction: _cancelPin,
          ),
          if (widget.state.signingIn) ...[
            const SizedBox(height: 18),
            const CircularProgressIndicator(strokeWidth: 2.5),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback? onRetryBoot;

  const _Header({this.onRetryBoot});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          const SemestaLogo(size: 42),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SemestaPAY',
                style: AppTheme.font(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Kiosk Santri',
                style: AppTheme.font(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (onRetryBoot != null)
            TextButton.icon(
              onPressed: onRetryBoot,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Hubungkan ulang'),
            )
          else
            const SemestaBadge(
              label: 'TERHUBUNG',
              icon: Icons.wifi_rounded,
              color: AppColors.success,
            ),
        ],
      ),
    );
  }
}
