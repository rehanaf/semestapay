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
          // Selector Akun Santri
          InkWell(
            onTap: _showStudentPicker,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      _selectedStudent?.name[0] ?? 'S',
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PILIH AKUN SANTRI DEMO',
                          style: AppTheme.font(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedStudent != null
                              ? '${_selectedStudent!.name} (${_selectedStudent!.nis})'
                              : 'Ketuk untuk memilih dari 12 santri',
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
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SemestaTextField(
            controller: _identifierController,
            label: 'Username / Email / NIS',
            hint: 'Contoh: 2026-001 atau username',
            prefixIcon: Icons.person_outline_rounded,
            suffixIcon: IconButton(
              icon: const Icon(Icons.people_alt_outlined, color: AppColors.primary, size: 20),
              tooltip: 'Pilih Santri',
              onPressed: _showStudentPicker,
            ),
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

  ({String email, String gender, String name, String nis})? get _selectedStudent {
    final current = _identifierController.text.trim();
    for (final s in _studentAccounts) {
      if (s.email == current || s.nis == current || s.name.toLowerCase() == current.toLowerCase()) {
        return s;
      }
    }
    return null;
  }

  void _fillDemo(String email, {bool autoLogin = false}) {
    _identifierController.text = email;
    _passwordController.text = 'password';
    setState(() => _errorMessage = null);
    if (autoLogin) {
      _handleLogin();
    }
  }

  static const _studentAccounts = [
    (name: 'Ajeng', email: 'ajeng@cendana.sch.id', nis: 'CSL-2026-001', gender: 'P'),
    (name: 'Citra', email: 'citra@cendana.sch.id', nis: 'CSL-2026-002', gender: 'P'),
    (name: 'Zikri', email: 'zikri@cendana.sch.id', nis: 'CSL-2026-003', gender: 'L'),
    (name: 'Aiko', email: 'aiko@cendana.sch.id', nis: 'CSL-2026-004', gender: 'P'),
    (name: 'Ralin', email: 'ralin@cendana.sch.id', nis: 'CSL-2026-005', gender: 'P'),
    (name: 'Alya', email: 'alya@cendana.sch.id', nis: 'CSL-2026-006', gender: 'P'),
    (name: 'Zaenal', email: 'zaenal@cendana.sch.id', nis: 'CSL-2026-007', gender: 'L'),
    (name: 'Zaenab', email: 'zaenab@cendana.sch.id', nis: 'CSL-2026-008', gender: 'P'),
    (name: 'Gege', email: 'gege@cendana.sch.id', nis: 'CSL-2026-009', gender: 'L'),
    (name: 'Reinhard', email: 'reinhard@cendana.sch.id', nis: 'CSL-2026-010', gender: 'L'),
    (name: 'Hafidz', email: 'hafidz@cendana.sch.id', nis: 'CSL-2026-011', gender: 'L'),
    (name: 'Althaf', email: 'althaf@cendana.sch.id', nis: 'CSL-2026-012', gender: 'L'),
  ];

  void _showStudentPicker() {
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
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Akun Santri',
                          style: AppTheme.font(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Cendana Smart Learning (12 Santri)',
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
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _studentAccounts.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final s = _studentAccounts[index];
                    final isSelected = _identifierController.text == s.email ||
                        _identifierController.text == s.nis;
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          s.name[0],
                          style: AppTheme.font(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            s.name,
                            style: AppTheme.font(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.gender == 'L' ? 'Ikhwan' : 'Akhwat',
                              style: AppTheme.font(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${s.nis} • ${s.email}',
                        style: AppTheme.font(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                          : const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
                      onTap: () {
                        Navigator.pop(ctx);
                        _fillDemo(s.email);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemoCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 17, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'PILIH AKUN DEMO',
                    style: AppTheme.font(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _showStudentPicker,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Semua (12)',
                        style: AppTheme.font(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _studentAccounts.map((s) {
              final isSelected = _identifierController.text == s.email ||
                  _identifierController.text == s.nis;
              return GestureDetector(
                onTap: () => _fillDemo(s.email),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.25),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        s.gender == 'L' ? Icons.face_rounded : Icons.face_3_rounded,
                        size: 13,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.name,
                        style: AppTheme.font(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
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
