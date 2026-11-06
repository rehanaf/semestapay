import 'package:flutter/material.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import '../state/pos_state.dart';

class LoginScreen extends StatefulWidget {
  final PosState posState;
  const LoginScreen({super.key, required this.posState});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'kasir@cashless.dev');
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
    _emailController.dispose();
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
      final res = await widget.posState.api.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        deviceName: 'merchant-flutter-app',
      );

      widget.posState.setUser(res.user, res.token);

      if (mounted) {
        AppToast.show(
          context,
          'Selamat datang, ${res.user.name}!',
          type: ToastType.success,
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Gagal terhubung ke server API.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fillDemo(String email) {
    _emailController.text = email;
    _passwordController.text = 'password';
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.merchantBackground,
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
                        child: SemestaLogo(
                          size: 58,
                          merchant: true,
                          showShadow: true,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Semestapay Merchant',
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
                          'Masuk ke dashboard toko untuk memproses pembayaran, mengelola outlet, dan memantau omset.',
                          textAlign: TextAlign.center,
                          style: AppTheme.font(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
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
      borderColor: AppColors.merchantPrimary.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.merchantPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  color: AppColors.merchantPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masuk ke Kasir',
                      style: AppTheme.font(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Gunakan akun merchant terdaftar',
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
            controller: _emailController,
            label: 'Username / Email Merchant',
            hint: 'kasir@kantin.id atau username',
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Username / Email wajib diisi.' : null,
          ),
          const SizedBox(height: 15),
          SemestaTextField(
            controller: _passwordController,
            label: 'Kata Sandi',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
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
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
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
                  activeColor: AppColors.merchantPrimary,
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
                  'Hubungi admin merchant untuk reset kata sandi.',
                  type: ToastType.info,
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Lupa sandi?',
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.merchantPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SemestaPrimaryButton(
            label: 'Masuk ke Merchant',
            icon: Icons.login_rounded,
            color: AppColors.merchantPrimary,
            isLoading: _isLoading,
            onPressed: _handleLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCard() {
    return SemestaCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      color: AppColors.merchantLightGreen,
      borderColor: AppColors.merchantPrimary.withValues(alpha: 0.18),
      boxShadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 17,
                color: AppColors.merchantPrimaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                'AKUN DEMO',
                style: AppTheme.font(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.merchantPrimaryDark,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _demoChip(
                'Kasir',
                Icons.point_of_sale_rounded,
                () => _fillDemo('kasir@cashless.dev'),
              ),
              _demoChip(
                'Merchant',
                Icons.storefront_rounded,
                () => _fillDemo('merchant@cashless.dev'),
              ),
              _demoChip(
                'Admin',
                Icons.admin_panel_settings_rounded,
                () => _fillDemo('admin@cashless.dev'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _demoChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: AppColors.merchantPrimary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.merchantPrimary),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTheme.font(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.merchantPrimaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 14,
                color: AppColors.merchantPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'Transaksi aman & terenkripsi 256-bit',
                style: AppTheme.font(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Semestapay Merchant v2.4.0 • Didukung SemestaPay',
            style: AppTheme.font(
              fontSize: 10,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
