import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import 'screens/dashboard_screen.dart';
import 'screens/tap_screen.dart';
import 'state/kiosk_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('initializeDateFormatting id_ID failed: $e');
  }
  runApp(KioskApp(state: KioskState()));
}

class KioskApp extends StatefulWidget {
  final KioskState state;

  const KioskApp({super.key, required this.state});

  @override
  State<KioskApp> createState() => _KioskAppState();
}

class _KioskAppState extends State<KioskApp> {
  @override
  void initState() {
    super.initState();
    widget.state.bootstrap();
  }

  @override
  void dispose() {
    widget.state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SemestaPAY Kiosk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          if (widget.state.booting) {
            return const _KioskSplash();
          }
          if (widget.state.bootError != null) {
            return _KioskBootError(state: widget.state);
          }
          return widget.state.isStudentAuthenticated
              ? KioskDashboardScreen(state: widget.state)
              : KioskTapScreen(state: widget.state);
        },
      ),
    );
  }
}

class _KioskSplash extends StatelessWidget {
  const _KioskSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SemestaLogo(size: 72),
            const SizedBox(height: 20),
            Text(
              'SemestaPAY Kiosk',
              style: AppTheme.font(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Menyiapkan perangkat...',
              style: AppTheme.font(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _KioskBootError extends StatelessWidget {
  final KioskState state;

  const _KioskBootError({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SemestaLogo(size: 64),
              const SizedBox(height: 20),
              SemestaInfoBanner(
                message: state.bootError ?? 'Gagal menyiapkan perangkat.',
                isError: true,
              ),
              const SizedBox(height: 18),
              SemestaPrimaryButton(
                label: 'Hubungkan Ulang',
                icon: Icons.refresh_rounded,
                onPressed: state.bootstrap,
              ),
              const SizedBox(height: 12),
              Text(
                'Pastikan akun operator kiosk sudah dikonfigurasi '
                '(KIOSK_OPERATOR_EMAIL / KIOSK_OPERATOR_PASSWORD).',
                textAlign: TextAlign.center,
                style: AppTheme.font(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
