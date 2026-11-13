import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import '../state/student_state.dart';

class StudentLoginScreen extends StatefulWidget {
  final StudentState state;
  const StudentLoginScreen({super.key, required this.state});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(text: 'ajeng@cendana.sch.id');
  final _passwordController = TextEditingController(text: 'password');

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  String? _errorMessage;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.state.login(
        _identifierController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        AppToast.show(
          context,
          'Selamat datang kembali, ${widget.state.student?.name ?? 'Santri'}!',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _messageFromError(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _messageFromError(Object error) {
    final text = error.toString();
    if (text.contains('message: ')) {
      return text.split('message: ').last.replaceAll('}', '').trim();
    }
    return 'Gagal masuk. Periksa username/password dan koneksi internet.';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 22),
                      const Center(
                        child: SemestaLogo(size: 58, showShadow: true),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Semestapay Mobile',
                        textAlign: TextAlign.center,
                        style: AppTheme.font(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Masuk ke dompet digital santri untuk melihat saldo, tagihan, dan riwayat transaksi.',
                          textAlign: TextAlign.center,
                          style: AppTheme.font(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildFormCard(),
                      const SizedBox(height: 18),
                      _buildDemoCard(),
                      const SizedBox(height: 20),
                      _buildSecurityFooter(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return SemestaCard(
      padding: const EdgeInsets.all(20),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.badge_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masuk Akun Santri',
                      style: AppTheme.font(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Gunakan username atau NIS dan kata sandi',
                      style: AppTheme.font(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_errorMessage != null) ...[
            SemestaInfoBanner(message: _errorMessage!, isError: true),
            const SizedBox(height: 16),
          ],
          SemestaTextField(
            controller: _identifierController,
            label: 'Username / Email / NIS',
            hint: 'Contoh: 2026-001 atau username',
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Username / NIS wajib diisi.' : null,
          ),
          const SizedBox(height: 15),
          SemestaTextField(
            controller: _passwordController,
            label: 'Kata Sandi',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Kata sandi wajib diisi.' : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Catatan: PIN 6 digit hanya digunakan saat transaksi kasir / kas keluar.',
              style: AppTheme.font(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _rememberMe,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Ingat perangkat ini',
                style: AppTheme.font(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => AppToast.show(
                  context,
                  'Hubungi wali kelas atau admin pesantren untuk reset kata sandi.',
                  type: ToastType.info,
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Lupa Kata Sandi?',
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SemestaPrimaryButton(
            label: 'Masuk Sekarang',
            onPressed: _isLoading ? null : _handleLogin,
            isLoading: _isLoading,
            icon: Icons.login_rounded,
          ),
        ],
      ),
    );
  }

  void _fillDemo(String email) {
    _identifierController.text = email;
    _passwordController.text = 'password';
    setState(() => _errorMessage = null);
  }

  Widget _buildDemoCard() {
    const students = [
      ('Ajeng', 'ajeng@cendana.sch.id'),
      ('Citra', 'citra@cendana.sch.id'),
      ('Zikri', 'zikri@cendana.sch.id'),
      ('Aiko', 'aiko@cendana.sch.id'),
      ('Ralin', 'ralin@cendana.sch.id'),
      ('Alya', 'alya@cendana.sch.id'),
      ('Zaenal', 'zaenal@cendana.sch.id'),
      ('Zaenab', 'zaenab@cendana.sch.id'),
      ('Gege', 'gege@cendana.sch.id'),
      ('Reinhard', 'reinhard@cendana.sch.id'),
      ('Hafidz', 'hafidz@cendana.sch.id'),
      ('Althaf', 'althaf@cendana.sch.id'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 17, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'AKUN DEMO — CENDANA SMART LEARNING',
                style: AppTheme.font(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: students.map((s) {
              return GestureDetector(
                onTap: () => _fillDemo(s.$2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        s.$1,
                        style: AppTheme.font(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Koneksi Aman & Terenkripsi',
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'PIN dan transaksi terlindungi standar perbankan sekolah',
                  style: AppTheme.font(
                    fontSize: 11,
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
}
