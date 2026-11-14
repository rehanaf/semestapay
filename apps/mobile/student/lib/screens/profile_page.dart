import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import '../state/student_state.dart';

class ProfilePage extends StatefulWidget {
  final StudentState state;
  final VoidCallback? onBackToHome;
  final VoidCallback? onLogout;

  const ProfilePage({
    super.key,
    required this.state,
    this.onBackToHome,
    this.onLogout,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _biometricEnabled = true;
  bool _notificationEnabled = true;
  bool _cardLocked = false;
  bool _isUploadingAvatar = false;
  int? _dailyLimitOverride;
  int get _dailyLimit =>
      _dailyLimitOverride ?? (widget.state.student?.dailyLimit ?? 50000).round();

  String get _studentId =>
      widget.state.student?.cardUid ?? widget.state.student?.nis ?? '-';
  String get _nisn => widget.state.student?.nis ?? '-';
  String get _studentName => widget.state.student?.name ?? 'Santri';
  String get _className => widget.state.student?.className ?? 'Santri';
  String get _initials {
    final parts = _studentName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'S';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  void _copyId() {
    Clipboard.setData(ClipboardData(text: _studentId.replaceAll(' ', '')));
    AppToast.show(
      context,
      'ID Semestapay berhasil disalin',
      type: ToastType.success,
    );
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) {
        if (mounted) {
          AppToast.show(
            context,
            'Gagal membaca file gambar.',
            type: ToastType.error,
          );
        }
        return;
      }

      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          AppToast.show(
            context,
            'Ukuran foto maksimal 5 MB.',
            type: ToastType.warning,
          );
        }
        return;
      }

      setState(() => _isUploadingAvatar = true);

      final ext = pickedFile.name.split('.').last.toLowerCase();
      final mimeType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      final base64String = 'data:$mimeType;base64,${base64Encode(bytes)}';

      await widget.state.updateAvatar(base64String);

      if (mounted) {
        AppToast.show(
          context,
          'Foto profil berhasil diperbarui',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          'Gagal mengunggah foto profil: ${e.toString().replaceAll("Exception: ", "")}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showEditProfileDialog() {
    final student = widget.state.student;
    final nameCtrl = TextEditingController(text: student?.name ?? '');
    final usernameCtrl =
        TextEditingController(text: student?.username ?? student?.nis ?? '');
    final emailCtrl = TextEditingController(text: student?.email ?? '');
    final phoneCtrl = TextEditingController(text: student?.phoneParent ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'Ubah Data Profil',
                style: AppTheme.font(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemestaTextField(
                  controller: nameCtrl,
                  label: 'Nama Lengkap Santri',
                  hint: 'Nama lengkap',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                SemestaTextField(
                  controller: usernameCtrl,
                  label: 'Username',
                  hint: 'Username akun',
                  prefixIcon: Icons.alternate_email_rounded,
                ),
                const SizedBox(height: 12),
                SemestaTextField(
                  controller: emailCtrl,
                  label: 'Email',
                  hint: 'santri@pesantren.id',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                SemestaTextField(
                  controller: phoneCtrl,
                  label: 'Nomor WhatsApp / Wali',
                  hint: '08123456789',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
              child: Text(
                'Batal',
                style: AppTheme.font(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        await widget.state.updateProfile(
                          name: nameCtrl.text.trim(),
                          username: usernameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                        );
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (mounted) {
                          AppToast.show(
                            context,
                            'Data profil berhasil disimpan',
                            type: ToastType.success,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setDialogState(() => isSaving = false);
                          AppToast.show(
                            context,
                            'Gagal menyimpan profil: ${e.toString().replaceAll("Exception: ", "")}',
                            type: ToastType.error,
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Simpan',
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLimitDialog() {
    int tempLimit = _dailyLimit;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final options = [25000, 50000, 75000, 100000];
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: AppColors.surface,
              title: Text(
                'Atur Limit Jajan Harian',
                style: AppTheme.font(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih batas maksimal pengeluaran kartu siswa per hari:',
                    style: AppTheme.font(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ...options.map((opt) {
                    final isSel = tempLimit == opt;
                    return InkWell(
                      onTap: () => setDialogState(() => tempLimit = opt),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rp ${_formatCurrency(opt)} / hari',
                              style: AppTheme.font(
                                fontSize: 13,
                                fontWeight:
                                    isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (isSel)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.primary, size: 18),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Batal',
                    style: AppTheme.font(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() => _dailyLimitOverride = tempLimit);
                    Navigator.pop(ctx);
                    AppToast.show(
                      context,
                      'Limit harian diperbarui: Rp ${_formatCurrency(tempLimit)}',
                      type: ToastType.success,
                    );
                  },
                  child: Text(
                    'Simpan',
                    style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: widget.onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.chevron_left_rounded,
                    size: 28, color: AppColors.textPrimary),
                onPressed: widget.onBackToHome,
              )
            : null,
        title: Text(
          'Profil Saya',
          style: AppTheme.font(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded,
                size: 22, color: AppColors.textPrimary),
            tooltip: 'Pusat Bantuan',
            onPressed: () {
              AppToast.show(
                context,
                'Hubungi CS Semestapay via WhatsApp: 0812-3456-7890',
                type: ToastType.info,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Kartu Header Siswa ──────────────────────────────
              _buildStudentHeaderCard(),
              const SizedBox(height: 16),

              // ── 2. Kartu Digital Pelajar (NFC) ─────────────────────
              _buildDigitalCardPreview(),
              const SizedBox(height: 20),

              // ── 3. Pengaturan Kartu Siswa ──────────────────────────
              _buildSectionTitle('Kartu Siswa (NFC / RFID)'),
              const SizedBox(height: 8),
              _buildCardSettings(),
              const SizedBox(height: 20),

              // ── 4. Akun & Keamanan ─────────────────────────────────
              _buildSectionTitle('Akun & Keamanan'),
              const SizedBox(height: 8),
              _buildSecuritySettings(),
              const SizedBox(height: 20),

              // ── 5. Preferensi & Bantuan ────────────────────────────
              _buildSectionTitle('Preferensi & Lainnya'),
              const SizedBox(height: 8),
              _buildPreferencesSettings(),
              const SizedBox(height: 24),

              // ── 6. Tombol Logout ───────────────────────────────────
              _buildLogoutButton(),
              const SizedBox(height: 16),

              // App Version
              Center(
                child: Text(
                  'Semestapay Mobile v1.2.0 • Build 2026.11\nSistem Pembayaran Cashless Siswa',
                  textAlign: TextAlign.center,
                  style: AppTheme.font(
                    fontSize: 11,
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header Siswa ──────────────────────────────────────────────────────────

  Widget _buildStudentHeaderCard() {
    final hasAvatar = widget.state.student?.avatarUrl != null &&
        widget.state.student!.avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: hasAvatar
                          ? ClipOval(
                              child: Image.network(
                                widget.state.student!.avatarUrl!,
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(
                                    _initials,
                                    style: AppTheme.font(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                _initials,
                                style: AppTheme.font(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    if (_isUploadingAvatar)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Nama & Sekolah
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _studentName,
                            style: AppTheme.font(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded,
                            size: 18, color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _className,
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIS: $_nisn',
                      style: AppTheme.font(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                  icon: const Icon(Icons.photo_camera_outlined,
                      size: 16, color: AppColors.primary),
                  label: Text(
                    'Ganti Foto',
                    style: AppTheme.font(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.textPrimary),
                  label: Text(
                    'Ubah Profil',
                    style: AppTheme.font(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // ID Semestapay
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID Semestapay Pelajar',
                    style: AppTheme.font(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _studentId,
                    style: AppTheme.font(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _copyId,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Salin ID',
                        style: AppTheme.font(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Kartu Digital Pelajar Visual ──────────────────────────────────────────

  Widget _buildDigitalCardPreview() {
    return Container(
      width: double.infinity,
      height: 160,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2A5E), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E2A5E).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Pattern dekorasi
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Konten kartu
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'KARTU SISWA DIGITAL',
                        style: AppTheme.font(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.wifi_rounded,
                          color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _cardLocked ? 'KARTU TERKUNCI' : 'NFC AKTIF',
                        style: AppTheme.font(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Nomor Kartu
              Text(
                '•••• •••• •••• ${_studentId.length >= 4 ? _studentId.substring(_studentId.length - 4) : _studentId}',
                style: AppTheme.font(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),

              // Detail bawah
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NAMA SISWA',
                        style: AppTheme.font(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        _studentName.toUpperCase(),
                        style: AppTheme.font(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'BERLAKU S/D',
                        style: AppTheme.font(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '06/28',
                        style: AppTheme.font(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Settings Group 1: Kartu Siswa ─────────────────────────────────────────

  Widget _buildCardSettings() {
    return _buildSettingsContainer([
      _buildTile(
        icon: Icons.payments_rounded,
        iconColor: AppColors.primary,
        title: 'Limit Jajan Harian',
        subtitle: 'Rp ${_formatCurrency(_dailyLimit)} per hari',
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 22, color: AppColors.textSecondary),
        onTap: _showLimitDialog,
      ),
      const Divider(height: 1, color: AppColors.divider),
      _buildTile(
        icon: Icons.lock_clock_rounded,
        iconColor: const Color(0xFFE67E22),
        title: 'Kunci Kartu Sementara',
        subtitle: _cardLocked
            ? 'Kartu sedang dinonaktifkan'
            : 'Kartu aktif untuk transaksi NFC',
        trailing: Switch(
          value: _cardLocked,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
          onChanged: (val) {
            setState(() => _cardLocked = val);
            AppToast.show(
              context,
              val
                  ? 'Kartu fisik berhasil dinonaktifkan sementara'
                  : 'Kartu fisik aktif kembali',
              type: val ? ToastType.warning : ToastType.success,
            );
          },
        ),
      ),
      const Divider(height: 1, color: AppColors.divider),
      _buildTile(
        icon: Icons.pin_rounded,
        iconColor: AppColors.accent,
        title: 'Ubah PIN Kartu Pelajar',
        subtitle: '6 digit PIN untuk otorisasi di kasir/kantin',
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 22, color: AppColors.textSecondary),
        onTap: () {
          AppToast.show(
            context,
            'Fitur ubah PIN kartu dapat dilakukan melalui verifikasi SMS/Orang Tua',
            type: ToastType.info,
          );
        },
      ),
    ]);
  }

  // ─── Settings Group 2: Akun & Keamanan ───────────────────────────────────────

  Widget _buildSecuritySettings() {
    return _buildSettingsContainer([
      _buildTile(
        icon: Icons.badge_outlined,
        iconColor: AppColors.primary,
        title: 'Edit Data Profil',
        subtitle: 'Perbarui nama, username, email & kontak',
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 22, color: AppColors.textSecondary),
        onTap: _showEditProfileDialog,
      ),
      const Divider(height: 1, color: AppColors.divider),
      _buildTile(
        icon: Icons.fingerprint_rounded,
        iconColor: AppColors.primary,
        title: 'Login Biometrik / Face ID',
        subtitle: 'Masuk lebih cepat & aman',
        trailing: Switch(
          value: _biometricEnabled,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
          onChanged: (val) {
            setState(() => _biometricEnabled = val);
            AppToast.show(
              context,
              val
                  ? 'Login biometrik diaktifkan'
                  : 'Login biometrik dinonaktifkan',
              type: ToastType.info,
            );
          },
        ),
      ),
      const Divider(height: 1, color: AppColors.divider),
      _buildTile(
        icon: Icons.account_balance_rounded,
        iconColor: const Color(0xFF2E7D32),
        title: 'Rekening & Sumber Dana',
        subtitle: 'BCA (•••• 9012) • Terhubung',
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 22, color: AppColors.textSecondary),
        onTap: () {
          AppToast.show(
            context,
            'Rekening BCA utama terhubung untuk top-up otomatis',
            type: ToastType.info,
          );
        },
      ),
      const Divider(height: 1, color: AppColors.divider),
      _buildTile(
        icon: Icons.devices_rounded,
        iconColor: AppColors.textSecondary,
        title: 'Perangkat Terhubung',
        subtitle: '1 perangkat aktif',
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 22, color: AppColors.textSecondary),
        onTap: () {
          AppToast.show(
            context,
            'Sesi aktif saat ini: Android / Desktop Device',
            type: ToastType.info,
          );
        },
      ),
    ]);
  }

  // ─── Settings Group 3: Preferensi & Lainnya ────────────────────────────────

  Widget _buildPreferencesSettings() {
    return _buildSettingsContainer([
      _buildTile(
        icon: Icons.notifications_active_rounded,
        iconColor: const Color(0xFFFF9800),
        title: 'Notifikasi Transaksi',
        subtitle: 'Terima info pengeluaran & uang saku',
        trailing: Switch(
          value: _notificationEnabled,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
          onChanged: (val) {
            setState(() => _notificationEnabled = val);
          },
        ),
      ),
      const Divider(height: 1, color: AppColors.divider),
      _buildTile(
        icon: Icons.support_agent_rounded,
        iconColor: AppColors.primary,
        title: 'Pusat Bantuan & Pengaduan',
        subtitle: 'FAQ dan layanan aduan siswa',
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 22, color: AppColors.textSecondary),
        onTap: () {
          AppToast.show(
            context,
            'Layanan bantuan aktif Senin - Jumat (07.00 - 16.00 WIB)',
            type: ToastType.info,
          );
        },
      ),
      const Divider(height: 1, color: AppColors.divider),
      _buildTile(
        icon: Icons.description_rounded,
        iconColor: AppColors.textSecondary,
        title: 'Syarat & Ketentuan',
        subtitle: 'Aturan layanan & privasi data siswa',
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 22, color: AppColors.textSecondary),
        onTap: () {
          AppToast.show(
            context,
            'Semestapay tunduk pada regulasi perlindungan data pribadi',
            type: ToastType.info,
          );
        },
      ),
    ]);
  }

  // ─── Logout Button ──────────────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(
          'Keluar dari Akun',
          style: AppTheme.font(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
        onPressed: widget.onLogout,
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.font(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.font(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.font(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
