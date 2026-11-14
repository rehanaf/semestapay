import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

class OverviewGalleryPage extends StatefulWidget {
  const OverviewGalleryPage({super.key});

  @override
  State<OverviewGalleryPage> createState() => _OverviewGalleryPageState();
}

class _OverviewGalleryPageState extends State<OverviewGalleryPage> {
  bool _merchant = false;
  bool _balanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final actions = _merchant
        ? [
            SemestaBalanceAction(
              icon: Icons.add_circle_outline_rounded,
              label: 'Kas Masuk',
              onTap: () => _showPreviewToast(context, 'Kas Masuk'),
            ),
            SemestaBalanceAction(
              icon: Icons.payments_outlined,
              label: 'Kas Keluar',
              onTap: () => _showPreviewToast(context, 'Kas Keluar'),
            ),
            SemestaBalanceAction(
              icon: Icons.history_rounded,
              label: 'Riwayat',
              onTap: () => _showPreviewToast(context, 'Riwayat merchant'),
            ),
          ]
        : [
            SemestaBalanceAction(
              icon: Icons.add_rounded,
              label: 'Top Up',
              onTap: () => _showPreviewToast(context, 'Top Up'),
            ),
            SemestaBalanceAction(
              icon: Icons.arrow_upward_rounded,
              label: 'Kirim',
              onTap: () => _showPreviewToast(context, 'Kirim'),
            ),
            SemestaBalanceAction(
              icon: Icons.arrow_downward_rounded,
              label: 'Terima',
              onTap: () => _showPreviewToast(context, 'Terima'),
            ),
          ];
    return _GalleryScroll(
      children: [
        Row(
          children: [
            const SemestaLogo(size: 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SemestaPay UI',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 3),
                  const Text('Preview komponen dari package mobile/ui'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Student')),
            ButtonSegment(value: true, label: Text('Merchant')),
          ],
          selected: {_merchant},
          onSelectionChanged: (selection) {
            setState(() {
              _merchant = selection.first;
              _balanceVisible = true;
            });
          },
        ),
        const SizedBox(height: 12),
        SemestaBalanceCard(
          balance: _merchant ? 1285000 : 245000,
          label: _merchant ? 'Saldo Siap Tarik' : 'Saldo Tersedia',
          ownerName: _merchant ? 'Kasir Kantin' : 'Nadia Putri',
          subtitle: _merchant ? 'Pendapatan merchant' : 'Dompet santri',
          gradient: _merchant
              ? const LinearGradient(
                  colors: [
                    AppColors.merchantPrimary,
                    AppColors.merchantPrimaryDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          balanceVisible: _balanceVisible,
          onToggleBalanceVisibility: () =>
              setState(() => _balanceVisible = !_balanceVisible),
          onDetailsTap: () => _showPreviewToast(
            context,
            _merchant ? 'Detail saldo merchant' : 'Detail saldo student',
          ),
          actions: actions,
        ),
        const SizedBox(height: 24),
        SemestaSectionHeader(
          title: 'Transaksi terbaru',
          actionLabel: 'Lihat semua',
          onAction: () => _showPreviewToast(context, 'Riwayat transaksi'),
        ),
        const SizedBox(height: 8),
        const SemestaHistoryTile(
          title: 'Top up saldo',
          subtitle: 'Hari ini, 09:41',
          amount: 100000,
          isCredit: true,
          status: 'paid',
        ),
        const Divider(),
        const SemestaHistoryTile(
          title: 'Kantin sekolah',
          subtitle: 'Hari ini, 08:15',
          amount: 18000,
          status: 'success',
        ),
        const SizedBox(height: 16),
        SemestaPrimaryButton(
          label: 'Coba tombol utama',
          icon: Icons.touch_app_rounded,
          onPressed: () => _showPreviewToast(context, 'Tombol utama ditekan'),
        ),
      ],
    );
  }
}

class LoginTemplateGalleryPage extends StatefulWidget {
  const LoginTemplateGalleryPage({super.key});

  @override
  State<LoginTemplateGalleryPage> createState() =>
      _LoginTemplateGalleryPageState();
}

class _LoginTemplateGalleryPageState extends State<LoginTemplateGalleryPage> {
  bool _merchant = false;

  @override
  Widget build(BuildContext context) {
    const studentAccounts = [
      SemestaLoginDemoAccount(
        label: 'Ajeng',
        identifier: 'ajeng@cendana.sch.id',
        icon: Icons.school_rounded,
        detail: 'CSL-2026-001',
      ),
      SemestaLoginDemoAccount(
        label: 'Citra',
        identifier: 'citra@cendana.sch.id',
        icon: Icons.school_rounded,
        detail: 'CSL-2026-002',
      ),
    ];
    const merchantAccounts = [
      SemestaLoginDemoAccount(
        label: 'Kasir Kantin',
        identifier: 'neneng@cendana.sch.id',
        icon: Icons.restaurant_rounded,
        detail: 'Miss Neneng',
      ),
      SemestaLoginDemoAccount(
        label: 'Kasir Kopsis',
        identifier: 'fuji@cendana.sch.id',
        icon: Icons.shopping_basket_rounded,
        detail: 'Ustadz Fuji',
      ),
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Student')),
              ButtonSegment(value: true, label: Text('Merchant')),
            ],
            selected: {_merchant},
            onSelectionChanged: (selection) =>
                setState(() => _merchant = selection.first),
          ),
        ),
        Expanded(
          child: SemestaLoginTemplate(
            key: ValueKey(_merchant),
            merchant: _merchant,
            title: _merchant ? 'Semestapay Merchant' : 'Semestapay Mobile',
            description: _merchant
                ? 'Masuk ke dashboard toko untuk memproses pembayaran dan memantau omset.'
                : 'Masuk ke dompet digital santri untuk melihat saldo, tagihan, dan riwayat transaksi.',
            formTitle: _merchant ? 'Masuk ke Kasir' : 'Masuk Akun Santri',
            formSubtitle: _merchant
                ? 'Gunakan akun merchant terdaftar'
                : 'Gunakan username atau NIS dan kata sandi',
            identifierLabel: _merchant
                ? 'Username / Email Merchant'
                : 'Username / Email / NIS',
            identifierHint: _merchant
                ? 'kasir@kantin.id atau username'
                : 'Contoh: 2026-001 atau username',
            accountPickerLabel: _merchant
                ? 'Pilih akun kasir / merchant'
                : 'Pilih akun santri demo',
            submitLabel: _merchant ? 'Masuk ke Merchant' : 'Masuk Sekarang',
            forgotPasswordLabel: _merchant ? 'Lupa sandi?' : 'Lupa Kata Sandi?',
            securityTitle: 'Koneksi Aman & Terenkripsi',
            securitySubtitle: _merchant
                ? 'Transaksi aman dan terenkripsi 256-bit'
                : 'PIN dan transaksi terlindungi standar sekolah',
            demoAccounts: _merchant ? merchantAccounts : studentAccounts,
            initialIdentifier: _merchant
                ? 'neneng@cendana.sch.id'
                : 'ajeng@cendana.sch.id',
            initialPassword: 'password',
            onLogin: (identifier, _) async => _showPreviewToast(
              context,
              'Preview login: $identifier',
              type: ToastType.success,
            ),
            onForgotPassword: () => _showPreviewToast(
              context,
              _merchant
                  ? 'Hubungi admin merchant untuk reset kata sandi.'
                  : 'Hubungi wali kelas atau admin untuk reset kata sandi.',
            ),
          ),
        ),
      ],
    );
  }
}

class ThemeGalleryPage extends StatelessWidget {
  final bool merchantTheme;
  final VoidCallback onToggleTheme;

  const ThemeGalleryPage({
    super.key,
    required this.merchantTheme,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    const swatches = <(String, Color)>[
      ('Primary', AppColors.primary),
      ('Accent', AppColors.accent),
      ('Success', AppColors.success),
      ('Warning', AppColors.warning),
      ('Error', AppColors.error),
      ('Merchant', AppColors.merchantPrimary),
      ('Surface', AppColors.surface),
      ('Divider', AppColors.divider),
    ];

    return _GalleryScroll(
      children: [
        const SemestaSectionHeader(title: 'Brand marks'),
        const SizedBox(height: 14),
        Row(
          children: [
            const SemestaLogo(),
            const SizedBox(width: 18),
            const SemestaLogo(merchant: true),
            const SizedBox(width: 18),
            const SemestaAvatar(name: 'Nadia Putri'),
            const SizedBox(width: 18),
            const SemestaAvatar(name: 'Semesta', merchant: true),
          ],
        ),
        const SizedBox(height: 26),
        const SemestaSectionHeader(title: 'Color tokens'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: swatches.map((swatch) {
            return SizedBox(
              width: 92,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: swatch.$2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    swatch.$1,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 26),
        SemestaInfoBanner(
          message: merchantTheme
              ? 'Tema Merchant aktif: aksen hijau.'
              : 'Tema Student aktif: aksen biru.',
          icon: Icons.palette_outlined,
        ),
        const SizedBox(height: 12),
        SemestaOutlineButton(
          label: merchantTheme ? 'Pakai tema Student' : 'Pakai tema Merchant',
          icon: Icons.swap_horiz_rounded,
          onPressed: onToggleTheme,
        ),
      ],
    );
  }
}

class ComponentsGalleryPage extends StatelessWidget {
  const ComponentsGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _GalleryScroll(
      children: [
        const SemestaSectionHeader(title: 'Surface cards'),
        const SizedBox(height: 12),
        SemestaCard(
          borderColor: AppColors.primary.withValues(alpha: 0.2),
          child: Row(
            children: [
              const SemestaLogo(size: 42, showShadow: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SemestaCard',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text('Surface, border, padding, dan tap handler.'),
                  ],
                ),
              ),
              SemestaIconButton(
                icon: Icons.arrow_forward_rounded,
                onTap: () => _showPreviewToast(context, 'SemestaCard ditekan'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SemestaSectionHeader(title: 'Badges'),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SemestaBadge(label: 'Aktif', icon: Icons.check_circle_rounded),
            SemestaBadge(
              label: 'Menunggu',
              color: Color(0xFFB45309),
              background: Color(0xFFFEF3C7),
              icon: Icons.schedule_rounded,
            ),
            SemestaBadge(
              label: 'Ditolak',
              color: AppColors.error,
              background: Color(0xFFFFE8E8),
              icon: Icons.close_rounded,
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SemestaSectionHeader(title: 'Info states'),
        const SizedBox(height: 12),
        const SemestaInfoBanner(message: 'Saldo berhasil diperbarui.'),
        const SizedBox(height: 10),
        const SemestaInfoBanner(
          message: 'Pembayaran belum dapat diproses.',
          isError: true,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: SemestaEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Belum ada transaksi',
            subtitle: 'Riwayat akan muncul setelah transaksi pertama.',
            action: SemestaOutlineButton(
              label: 'Muat ulang',
              onPressed: () => _showPreviewToast(context, 'Memuat ulang'),
            ),
          ),
        ),
      ],
    );
  }
}

class FormsGalleryPage extends StatefulWidget {
  const FormsGalleryPage({super.key});

  @override
  State<FormsGalleryPage> createState() => _FormsGalleryPageState();
}

class _FormsGalleryPageState extends State<FormsGalleryPage> {
  final _nameController = TextEditingController(text: 'Nadia Putri');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GalleryScroll(
      children: [
        const SemestaSectionHeader(title: 'Text field'),
        const SizedBox(height: 14),
        SemestaTextField(
          controller: _nameController,
          label: 'Nama lengkap',
          hint: 'Masukkan nama',
          prefixIcon: Icons.person_outline_rounded,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 18),
        const SemestaSectionHeader(title: 'Buttons'),
        const SizedBox(height: 12),
        SemestaPrimaryButton(
          label: _isLoading ? 'Memproses' : 'Primary action',
          icon: Icons.check_rounded,
          isLoading: _isLoading,
          onPressed: () {
            setState(() => _isLoading = true);
            Future<void>.delayed(const Duration(milliseconds: 900), () {
              if (!context.mounted) return;
              setState(() => _isLoading = false);
              _showPreviewToast(context, 'Aksi selesai');
            });
          },
        ),
        const SizedBox(height: 10),
        SemestaOutlineButton(
          label: 'Outline action',
          icon: Icons.open_in_new_rounded,
          onPressed: () => _showPreviewToast(context, 'Outline action'),
        ),
        const SizedBox(height: 16),
        const SemestaSectionHeader(title: 'Icon buttons'),
        const SizedBox(height: 10),
        Row(
          children: [
            SemestaIconButton(
              icon: Icons.notifications_none_rounded,
              badge: 3,
              onTap: () => _showPreviewToast(context, 'Notifikasi'),
            ),
            const SizedBox(width: 10),
            SemestaIconButton(
              icon: Icons.favorite_border_rounded,
              color: AppColors.error,
              size: 44,
              onTap: () => _showPreviewToast(context, 'Favorit'),
            ),
          ],
        ),
      ],
    );
  }
}

class NavigationGalleryPage extends StatefulWidget {
  const NavigationGalleryPage({super.key});

  @override
  State<NavigationGalleryPage> createState() => _NavigationGalleryPageState();
}

class _NavigationGalleryPageState extends State<NavigationGalleryPage> {
  int _selectedTab = 0;
  String _keypadValue = '0';

  void _appendKey(String value) {
    setState(() {
      _keypadValue = _keypadValue == '0' ? value : '$_keypadValue$value';
    });
  }

  void _removeKey() {
    setState(() {
      _keypadValue = _keypadValue.length <= 1
          ? '0'
          : _keypadValue.substring(0, _keypadValue.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GalleryScroll(
      children: [
        const SemestaSectionHeader(title: 'Bottom navigation'),
        const SizedBox(height: 12),
        SemestaCard(
          padding: EdgeInsets.zero,
          child: SemestaBottomNavBar(
            currentIndex: _selectedTab,
            onTap: (index) => setState(() => _selectedTab = index),
            items: const [
              SemestaNavItemData(icon: Icons.home_rounded, label: 'Home'),
              SemestaNavItemData(
                icon: Icons.receipt_long_rounded,
                label: 'Aktivitas',
              ),
              SemestaNavItemData(icon: Icons.person_rounded, label: 'Profil'),
              SemestaNavItemData(
                icon: Icons.settings_rounded,
                label: 'Setelan',
              ),
            ],
            centerButton: FloatingActionButton.small(
              heroTag: 'preview-nav-center',
              onPressed: () => _showPreviewToast(context, 'Tombol tengah'),
              child: const Icon(Icons.add_rounded),
            ),
            centerLabel: 'Bayar',
          ),
        ),
        const SizedBox(height: 24),
        const SemestaSectionHeader(title: 'Sheet handle'),
        const SemestaSheetHandle(),
        const SizedBox(height: 8),
        const SemestaSectionHeader(title: 'Numeric keypad'),
        const SizedBox(height: 10),
        SemestaCard(
          child: Column(
            children: [
              Text(
                _keypadValue,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              SemestaKeypad(
                onKey: _appendKey,
                onBackspace: _removeKey,
                actionLabel: 'Reset',
                onAction: () => setState(() => _keypadValue = '0'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ToastGalleryPage extends StatelessWidget {
  const ToastGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _GalleryScroll(
      children: [
        const SemestaInfoBanner(
          message: 'Pilih jenis toast untuk melihat notifikasi di atas layar.',
          icon: Icons.notifications_active_outlined,
        ),
        const SizedBox(height: 20),
        SemestaPrimaryButton(
          label: 'Success toast',
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
          onPressed: () => _showPreviewToast(
            context,
            'Perubahan berhasil disimpan.',
            type: ToastType.success,
          ),
        ),
        const SizedBox(height: 10),
        SemestaPrimaryButton(
          label: 'Error toast',
          icon: Icons.error_outline_rounded,
          color: AppColors.error,
          onPressed: () => _showPreviewToast(
            context,
            'Pembayaran tidak dapat diproses.',
            type: ToastType.error,
          ),
        ),
        const SizedBox(height: 10),
        SemestaPrimaryButton(
          label: 'Warning toast',
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
          onPressed: () => _showPreviewToast(
            context,
            'Sesi akan berakhir dalam 2 menit.',
            type: ToastType.warning,
          ),
        ),
        const SizedBox(height: 10),
        SemestaOutlineButton(
          label: 'Info toast',
          icon: Icons.info_outline_rounded,
          onPressed: () => _showPreviewToast(
            context,
            'Data terbaru sudah dimuat.',
            type: ToastType.info,
            position: ToastPosition.bottom,
          ),
        ),
      ],
    );
  }
}

class _GalleryScroll extends StatelessWidget {
  final List<Widget> children;

  const _GalleryScroll({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('gallery-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

void _showPreviewToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
  ToastPosition position = ToastPosition.top,
}) {
  AppToast.show(context, message, type: type, position: position);
}
