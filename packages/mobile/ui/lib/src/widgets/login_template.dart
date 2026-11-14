import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'widgets.dart';

class SemestaLoginDemoAccount {
  final String label;
  final String identifier;
  final IconData icon;
  final String? detail;

  const SemestaLoginDemoAccount({
    required this.label,
    required this.identifier,
    this.icon = Icons.person_rounded,
    this.detail,
  });
}

class SemestaLoginTemplate extends StatefulWidget {
  final bool merchant;
  final String title;
  final String description;
  final String formTitle;
  final String formSubtitle;
  final String identifierLabel;
  final String identifierHint;
  final String accountPickerLabel;
  final String submitLabel;
  final String forgotPasswordLabel;
  final String securityTitle;
  final String securitySubtitle;
  final List<SemestaLoginDemoAccount> demoAccounts;
  final String? initialIdentifier;
  final String initialPassword;
  final String demoPassword;
  final Future<void> Function(String identifier, String password) onLogin;
  final VoidCallback onForgotPassword;

  const SemestaLoginTemplate({
    super.key,
    this.merchant = false,
    required this.title,
    required this.description,
    required this.formTitle,
    required this.formSubtitle,
    required this.identifierLabel,
    required this.identifierHint,
    required this.accountPickerLabel,
    required this.submitLabel,
    required this.forgotPasswordLabel,
    required this.securityTitle,
    required this.securitySubtitle,
    required this.demoAccounts,
    this.initialIdentifier,
    this.initialPassword = '',
    this.demoPassword = 'password',
    required this.onLogin,
    required this.onForgotPassword,
  });

  @override
  State<SemestaLoginTemplate> createState() => _SemestaLoginTemplateState();
}

class _SemestaLoginTemplateState extends State<SemestaLoginTemplate>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _identifierController;
  late final TextEditingController _passwordController;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _obscurePassword = true;
  bool _rememberDevice = true;
  bool _isLoading = false;
  String? _errorMessage;

  Color get _primary =>
      widget.merchant ? AppColors.merchantPrimary : AppColors.primary;

  @override
  void initState() {
    super.initState();
    _identifierController =
        TextEditingController(text: widget.initialIdentifier ?? '');
    _passwordController = TextEditingController(text: widget.initialPassword);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await widget.onLogin(
        _identifierController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (_) {
      if (mounted) {
        setState(
            () => _errorMessage = 'Gagal masuk. Periksa akun dan koneksi.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectAccount(SemestaLoginDemoAccount account) {
    _identifierController.text = account.identifier;
    _passwordController.text = widget.demoPassword;
    setState(() => _errorMessage = null);
  }

  void _showAccountPicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            children: [
              Text(
                widget.accountPickerLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...widget.demoAccounts.map((account) {
                final selected =
                    _identifierController.text == account.identifier;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _primary.withValues(alpha: 0.1),
                    foregroundColor: _primary,
                    child: Icon(account.icon),
                  ),
                  title: Text(account.label),
                  subtitle: Text(account.detail ?? account.identifier),
                  trailing: selected
                      ? Icon(Icons.check_circle_rounded, color: _primary)
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    _selectAccount(account);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final background =
        widget.merchant ? AppColors.merchantBackground : AppColors.background;
    return ColoredBox(
      color: background,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 22),
                      Center(
                        child: SemestaLogo(
                          size: 58,
                          merchant: widget.merchant,
                          showShadow: true,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: AppTheme.font(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.description,
                        textAlign: TextAlign.center,
                        style: AppTheme.font(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildFormCard(),
                      const SizedBox(height: 18),
                      _buildDemoAccounts(),
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
      borderColor: widget.merchant ? _primary.withValues(alpha: 0.16) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.merchant
                      ? Icons.point_of_sale_rounded
                      : Icons.badge_rounded,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.formTitle,
                        style: AppTheme.font(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    Text(widget.formSubtitle,
                        style: AppTheme.font(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_errorMessage != null) ...[
            SemestaInfoBanner(message: _errorMessage!, isError: true),
            const SizedBox(height: 14),
          ],
          if (widget.demoAccounts.isNotEmpty) ...[
            InkWell(
              onTap: _showAccountPicker,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _primary,
                      child: Icon(
                        widget.merchant
                            ? Icons.storefront_rounded
                            : Icons.school_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.accountPickerLabel.toUpperCase(),
                              style: AppTheme.font(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              )),
                          Text(
                            _identifierController.text.isEmpty
                                ? 'Ketuk untuk memilih akun demo'
                                : _identifierController.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.font(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_drop_down_circle_outlined,
                        color: _primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          SemestaTextField(
            controller: _identifierController,
            label: widget.identifierLabel,
            hint: widget.identifierHint,
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Username / email wajib diisi.'
                : null,
          ),
          const SizedBox(height: 15),
          SemestaTextField(
            controller: _passwordController,
            label: 'Kata Sandi',
            hint: 'Masukkan kata sandi',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Kata sandi wajib diisi.'
                : null,
            suffixIcon: IconButton(
              tooltip: _obscurePassword
                  ? 'Tampilkan kata sandi'
                  : 'Sembunyikan kata sandi',
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
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _rememberDevice,
                  activeColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (value) =>
                      setState(() => _rememberDevice = value ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Ingat perangkat ini',
                    style: AppTheme.font(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    )),
              ),
              TextButton(
                onPressed: widget.onForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: _primary,
                ),
                child: Text(widget.forgotPasswordLabel,
                    style: AppTheme.font(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SemestaPrimaryButton(
            label: widget.submitLabel,
            icon: Icons.login_rounded,
            color: _primary,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildDemoAccounts() {
    return SemestaCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      color: widget.merchant ? AppColors.merchantLightGreen : null,
      borderColor: _primary.withValues(alpha: 0.18),
      boxShadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 17, color: _primary),
              const SizedBox(width: 6),
              Text('PILIH AKUN DEMO',
                  style: AppTheme.font(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                  )),
              const Spacer(),
              TextButton(
                onPressed: _showAccountPicker,
                child: Text('Semua (${widget.demoAccounts.length})'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.demoAccounts.map((account) {
              final selected = _identifierController.text == account.identifier;
              return ActionChip(
                avatar: Icon(
                  account.icon,
                  size: 16,
                  color: selected ? Colors.white : _primary,
                ),
                label: Text(account.label),
                labelStyle: AppTheme.font(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
                backgroundColor: selected ? _primary : AppColors.surface,
                side: BorderSide(color: _primary.withValues(alpha: 0.25)),
                onPressed: () => _selectAccount(account),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return SemestaCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 14,
      boxShadow: const [],
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.verified_user_outlined, size: 16, color: _primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.securityTitle,
                    style: AppTheme.font(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                Text(widget.securitySubtitle,
                    style: AppTheme.font(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
