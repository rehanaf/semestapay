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
  final _emailController = TextEditingController(text: 'neneng@cendana.sch.id');
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
          // Selector Akun Merchant
          InkWell(
            onTap: _showMerchantPicker,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.merchantPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.merchantPrimary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.merchantPrimary,
                    child: Icon(
                      _selectedMerchant?.icon ?? Icons.storefront_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PILIH AKUN KASIR / MERCHANT',
                          style: AppTheme.font(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.merchantPrimaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedMerchant != null
                              ? '${_selectedMerchant!.role} (${_selectedMerchant!.name})'
                              : 'Ketuk untuk memilih akun kasir',
                          style: AppTheme.font(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down_circle_outlined,
                    color: AppColors.merchantPrimary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SemestaTextField(
            controller: _emailController,
            label: 'Username / Email Merchant',
            hint: 'kasir@kantin.id atau username',
            prefixIcon: Icons.person_outline_rounded,
            suffixIcon: IconButton(
              icon: const Icon(Icons.badge_outlined, color: AppColors.merchantPrimary, size: 20),
              tooltip: 'Pilih Akun',
              onPressed: _showMerchantPicker,
            ),
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

  static const _merchantAccounts = [
    (
      role: 'Kasir Kantin',
      name: 'Miss Neneng',
      email: 'neneng@cendana.sch.id',
      desc: 'Batas belanja Rp 20.000/siswa',
      icon: Icons.restaurant_rounded,
    ),
    (
      role: 'Kasir Kopsis',
      name: 'Ustadz Fuji',
      email: 'fuji@cendana.sch.id',
      desc: 'Koperasi Siswa — Tanpa batas',
      icon: Icons.shopping_basket_rounded,
    ),
    (
      role: 'Superadmin',
      name: 'Admin Cendana',
      email: 'admin@cendana.sch.id',
      desc: 'Akses penuh manajemen sistem',
      icon: Icons.admin_panel_settings_rounded,
    ),
  ];

  ({IconData icon, String desc, String email, String name, String role})? get _selectedMerchant {
    final current = _emailController.text.trim();
    for (final m in _merchantAccounts) {
      if (m.email == current) return m;
    }
    return null;
  }

  void _showMerchantPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.merchantPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.merchantPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Akun Merchant',
                          style: AppTheme.font(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Cendana Smart Learning',
                          style: AppTheme.font(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _merchantAccounts.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final m = _merchantAccounts[index];
                  final isSelected = _emailController.text == m.email;
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: isSelected
                          ? AppColors.merchantPrimary
                          : AppColors.merchantPrimary.withValues(alpha: 0.12),
                      child: Icon(
                        m.icon,
                        size: 20,
                        color: isSelected ? Colors.white : AppColors.merchantPrimary,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          m.role,
                          style: AppTheme.font(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${m.name})',
                          style: AppTheme.font(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.email,
                          style: AppTheme.font(fontSize: 11, color: AppColors.merchantPrimaryDark),
                        ),
                        Text(
                          m.desc,
                          style: AppTheme.font(fontSize: 10, color: AppColors.textLight),
                        ),
                      ],
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.merchantPrimary, size: 20)
                        : const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
                    onTap: () {
                      Navigator.pop(ctx);
                      _fillDemo(m.email);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    'PILIH AKUN DEMO',
                    style: AppTheme.font(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.merchantPrimaryDark,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _showMerchantPicker,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Detail',
                        style: AppTheme.font(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.merchantPrimaryDark,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.merchantPrimaryDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _merchantAccounts.map((m) {
              final isSelected = _emailController.text == m.email;
              return GestureDetector(
                onTap: () => _fillDemo(m.email),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.merchantPrimary : AppColors.surface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.merchantPrimary
                          : AppColors.merchantPrimary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        m.icon,
                        size: 13,
                        color: isSelected ? Colors.white : AppColors.merchantPrimary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        m.role,
                        style: AppTheme.font(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.merchantPrimaryDark,
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
