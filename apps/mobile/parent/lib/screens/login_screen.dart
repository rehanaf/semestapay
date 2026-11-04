import 'package:flutter/material.dart';
import '../state/parent_state.dart';
import '../theme/app_theme.dart';
import '../widgets/parent_shell.dart';

enum _LoginMode { nis, otp }

class ParentLoginScreen extends StatefulWidget {
  final ParentState state;
  const ParentLoginScreen({super.key, required this.state});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _phoneController = TextEditingController(text: '081312000010');
  final _nisController = TextEditingController(text: '2026-001');
  final _otpController = TextEditingController();
  _LoginMode _mode = _LoginMode.nis;
  bool _loading = false;
  bool _otpSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _nisController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Nomor HP wali wajib diisi.');
      return;
    }

    if (_mode == _LoginMode.nis && _nisController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'NIS anak wajib diisi.');
      return;
    }

    if (_mode == _LoginMode.otp && _otpController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Kode OTP wajib diisi.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (_mode == _LoginMode.nis) {
        await widget.state.loginWithNis(phone, _nisController.text.trim());
      } else {
        await widget.state.verifyOtp(phone, _otpController.text.trim());
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ParentShell(state: widget.state),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _messageFromError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Nomor HP wali wajib diisi.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await widget.state.requestOtp(phone);
      if (mounted) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kode OTP dibuat di server. Untuk demo, kode tercatat di log server.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _messageFromError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _messageFromError(Object error) {
    final text = error.toString();
    if (text.contains('message: ')) {
      return text.split('message: ').last.replaceAll('}', '').trim();
    }
    return 'Gagal masuk. Periksa data dan koneksi internet.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.family_restroom_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SmPay Ortu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pantau saldo, limit, dan riwayat jajan anak',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Masuk sebagai Wali Santri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SegmentedButton<_LoginMode>(
                          segments: const [
                            ButtonSegment(
                              value: _LoginMode.nis,
                              label: Text('NIS Anak'),
                              icon: Icon(Icons.badge_outlined, size: 18),
                            ),
                            ButtonSegment(
                              value: _LoginMode.otp,
                              label: Text('Kode OTP'),
                              icon: Icon(Icons.sms_outlined, size: 18),
                            ),
                          ],
                          selected: {_mode},
                          onSelectionChanged: (selected) {
                            setState(() {
                              _mode = selected.first;
                              _errorMessage = null;
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    AppTheme.dangerColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.dangerColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const Text(
                          'Nomor HP Wali',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                            hintText: '08xxxxxxxxxx',
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_mode == _LoginMode.nis) ...[
                          const Text(
                            'NIS Anak',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _nisController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              prefixIcon:
                                  Icon(Icons.badge_outlined, size: 20),
                              hintText: 'Contoh: 2026-001',
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'Kode OTP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              prefixIcon:
                                  const Icon(Icons.password_rounded, size: 20),
                              hintText: '6 digit kode OTP',
                              suffixIcon: TextButton(
                                onPressed: _loading ? null : _sendOtp,
                                child: Text(
                                  _otpSent ? 'Kirim Ulang' : 'Kirim OTP',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _mode == _LoginMode.nis
                                      ? 'Buka Dashboard Ortu'
                                      : 'Verifikasi & Masuk',
                                ),
                        ),
                        if (_mode == _LoginMode.nis) ...[
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: () {
                              _phoneController.text = '081312000010';
                              _nisController.text = '2026-001';
                              setState(() => _errorMessage = null);
                            },
                            child: const Text(
                              'Gunakan Akun Demo Wali',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
