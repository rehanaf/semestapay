import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top Up Screen — Virtual Account Statis / Open Amount Santri
// ─────────────────────────────────────────────────────────────────────────────

class TopUpScreen extends StatefulWidget {
  final SemestaPayApiClient api;

  const TopUpScreen({super.key, required this.api});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  VirtualAccountInfo? _va;
  String _selectedMethod = 'BC';

  static const _methods = [
    _PaymentMethodOption(code: 'BC', name: 'BCA Virtual Account', icon: 'BCA'),
    _PaymentMethodOption(code: 'M2', name: 'Mandiri Virtual Account', icon: 'MDR'),
    _PaymentMethodOption(code: 'I1', name: 'BNI Virtual Account', icon: 'BNI'),
    _PaymentMethodOption(code: 'BR', name: 'BRI Virtual Account', icon: 'BRI'),
    _PaymentMethodOption(code: 'B1', name: 'CIMB Niaga VA', icon: 'CIMB'),
    _PaymentMethodOption(code: 'BT', name: 'Permata Bank VA', icon: 'PMT'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchVa();
  }

  Future<void> _fetchVa({String? paymentMethod, bool forceNew = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final method = paymentMethod ?? _selectedMethod;
      final va = await widget.api.getOrCreateTopupVa(
        amount: 10000,
        paymentMethod: method,
        forceNew: forceNew,
      );

      if (!mounted) return;
      setState(() {
        _va = va;
        _selectedMethod = va.paymentMethod.isNotEmpty ? va.paymentMethod : method;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat Virtual Account. Periksa koneksi internet.';
        _isLoading = false;
      });
    }
  }

  void _onMethodSelected(String code) {
    if (_selectedMethod == code && _va != null) return;
    setState(() => _selectedMethod = code);
    _fetchVa(paymentMethod: code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Top Up Saldo Santri',
          style: AppTheme.font(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Buat / Muat ulang VA',
            onPressed: _isLoading ? null : () => _fetchVa(forceNew: true),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _va == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _va == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 54, color: AppColors.error),
              const SizedBox(height: 14),
              Text(
                'Terjadi Kendala',
                style: AppTheme.font(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTheme.font(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => _fetchVa(),
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text(
                  'Coba Lagi',
                  style: AppTheme.font(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final va = _va!;
    final accountName = va.accountName?.isNotEmpty == true
        ? va.accountName!
        : (va.studentName?.isNotEmpty == true
            ? 'SEMESTA ${va.studentName!.toUpperCase()}'
            : 'SEMESTA SANTRI');

    return RefreshIndicator(
      onRefresh: () => _fetchVa(forceNew: true),
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        children: [
          // ── Kartu Utama VA Statis ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56FF), Color(0xFF0B33A8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A56FF).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                'VIRTUAL ACCOUNT RESMI',
                                style: AppTheme.font(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      va.bankName.isNotEmpty ? va.bankName : 'Virtual Account',
                      style: AppTheme.font(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Nomor Virtual Account',
                  style: AppTheme.font(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        va.accountNumber.isNotEmpty ? va.accountNumber : '-',
                        style: AppTheme.font(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: va.accountNumber));
                        AppToast.show(context, 'Nomor VA disalin!', type: ToastType.success);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF1A56FF)),
                            const SizedBox(width: 6),
                            Text(
                              'Salin',
                              style: AppTheme.font(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A56FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nama Rekening Tujuan',
                          style: AppTheme.font(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          accountName,
                          style: AppTheme.font(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Open Amount',
                        style: AppTheme.font(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00E676),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Informasi Open Amount ──────────────────────────────────────────
          _InfoBox(
            icon: Icons.info_outline_rounded,
            title: 'Top Up Otomatis Masuk ke Saldo',
            text:
                'Transfer ke nomor Virtual Account di atas melalui m-banking, ATM, atau simulator. Saldo santri akan otomatis bertambah secara instan. Setelah pembayaran selesai, sistem otomatis menyediakan nomor VA baru untuk top-up berikutnya.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: Color(0xFFD0D7DE)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _isLoading ? null : () => _fetchVa(forceNew: true),
            icon: const Icon(Icons.autorenew_rounded, size: 18),
            label: Text(
              'Buat Tagihan / VA Baru',
              style: AppTheme.font(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),

          // ── Pilihan Bank Virtual Account ───────────────────────────────────
          _SectionCard(
            title: 'PILIH SALURAN BANK',
            child: Column(
              children: _methods.map((m) {
                final isSelected = _selectedMethod == m.code;
                return _MethodTile(
                  method: m,
                  isSelected: isSelected,
                  onTap: () => _onMethodSelected(m.code),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Panduan Pembayaran ─────────────────────────────────────────────
          _SectionCard(
            title: 'PANDUAN PEMBAYARAN',
            child: _PaymentInstructions(bankCode: _selectedMethod),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentMethodOption {
  final String code;
  final String name;
  final String icon;
  const _PaymentMethodOption({
    required this.code,
    required this.name,
    required this.icon,
  });
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.font(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final _PaymentMethodOption method;
  final bool isSelected;
  final VoidCallback onTap;
  const _MethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E9F2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : const Color(0xFFF0F3FA),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                method.icon,
                style: AppTheme.font(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method.name,
                style: AppTheme.font(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
            else
              const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFFCBD5E1), size: 18),
          ],
        ),
      ),
    );
  }
}

class _PaymentInstructions extends StatelessWidget {
  final String bankCode;
  const _PaymentInstructions({required this.bankCode});

  static const _instructions = <String, List<String>>{
    'BC': [
      'Buka aplikasi BCA Mobile / KlikBCA / ATM BCA.',
      'Pilih menu Transfer → BCA Virtual Account.',
      'Masukkan nomor Virtual Account BCA santri di atas.',
      'Masukkan nominal transfer sesuai kebutuhan Anda (bebas nominal).',
      'Periksa konfirmasi nama rekening "SEMESTA [NAMA SANTRI]".',
      'Masukkan PIN Anda dan selesaikan transaksi. Saldo masuk otomatis!',
    ],
    'M2': [
      'Buka Livin\' by Mandiri atau ATM Mandiri.',
      'Pilih menu Pembayaran / Bayar → Multi Payment / Virtual Account.',
      'Pilih penyedia jasa / masukkan kode perusahaan Duitku SemestaPay.',
      'Masukkan nomor Virtual Account Mandiri santri di atas.',
      'Masukkan nominal transfer yang diinginkan.',
      'Periksa nama santri, lalu konfirmasi dengan PIN Anda.',
    ],
    'I1': [
      'Buka BNI Mobile Banking atau ATM BNI.',
      'Pilih menu Transfer → Virtual Account Billing.',
      'Input nomor Virtual Account BNI santri.',
      'Masukkan nominal tagihan/pengisian saldo yang diinginkan.',
      'Pastikan nama tujuan sudah sesuai, lalu masukkan password transaksi.',
    ],
    'BR': [
      'Buka aplikasi BRImo atau ATM BRI.',
      'Pilih menu Pembayaran → BRIVA (BRI Virtual Account).',
      'Masukkan nomor BRIVA santri di atas.',
      'Masukkan nominal transfer yang ingin diisikan ke saldo santri.',
      'Cek nama tujuan, konfirmasi dan masukkan PIN BRImo.',
    ],
  };

  static const _fallback = [
    'Buka aplikasi mobile banking atau kunjungi ATM terdekat.',
    'Pilih menu Transfer / Pembayaran → Virtual Account.',
    'Masukkan nomor Virtual Account yang tertera di atas.',
    'Masukkan nominal transfer berapapun yang ingin diisi ke saldo.',
    'Pastikan nama tujuan santri sesuai, lalu selesaikan pembayaran.',
    'Saldo dompet santri akan otomatis bertambah secara instan.',
  ];

  @override
  Widget build(BuildContext context) {
    final steps = _instructions[bankCode] ?? _fallback;
    return Column(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key + 1;
        final step = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$i',
                  style: AppTheme.font(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step,
                  style: AppTheme.font(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _InfoBox({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1D4ED8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.font(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: AppTheme.font(
                    fontSize: 12,
                    color: const Color(0xFF334155),
                    height: 1.4,
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
