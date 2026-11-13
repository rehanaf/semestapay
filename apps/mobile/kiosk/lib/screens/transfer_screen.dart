import 'package:flutter/material.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import '../state/kiosk_state.dart';

class RecipientData {
  final String name;
  final String bankName;
  final String accountNumber;
  final Color avatarColor;
  final IconData icon;
  final int? studentId;

  const RecipientData({
    required this.name,
    required this.bankName,
    required this.accountNumber,
    required this.avatarColor,
    required this.icon,
    this.studentId,
  });
}

class NumberInputHelper {
  static String format(String digits) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static int countDigitsBefore(String text, int offset) {
    int count = 0;
    final clamped = offset.clamp(0, text.length);
    for (int i = 0; i < clamped; i++) {
      if (text[i] != '.') count++;
    }
    return count;
  }

  static int offsetForDigitCount(String formatted, int digitCount) {
    if (digitCount <= 0) return 0;
    int digitsSeen = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (formatted[i] != '.') {
        digitsSeen++;
        if (digitsSeen == digitCount) return i + 1;
      }
    }
    return formatted.length;
  }
}

class KioskTransferScreen extends StatefulWidget {
  final KioskState state;

  const KioskTransferScreen({super.key, required this.state});

  @override
  State<KioskTransferScreen> createState() => _KioskTransferScreenState();
}

class _KioskTransferScreenState extends State<KioskTransferScreen>
    with SingleTickerProviderStateMixin {
  String _rawDigits = '';
  int _cursorIndex = 0;

  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();

  bool _loadingPeers = false;
  bool _submitting = false;
  String? _peerError;

  List<RecipientData> _recipients = [];
  RecipientData? _selectedRecipient;

  late final AnimationController _cursorAnimController;

  @override
  void initState() {
    super.initState();
    _cursorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _loadPeers();
  }

  @override
  void dispose() {
    _cursorAnimController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _resetCursorBlink() {
    _cursorAnimController.reset();
    _cursorAnimController.repeat(reverse: true);
  }

  int get _numericAmount => int.tryParse(_rawDigits) ?? 0;
  String get _formattedAmount => NumberInputHelper.format(_rawDigits);

  Future<void> _loadPeers() async {
    setState(() {
      _loadingPeers = true;
      _peerError = null;
    });

    try {
      final mockPeers = [
        const RecipientData(
          studentId: 2,
          name: 'Ajeng',
          bankName: 'Cendana A',
          accountNumber: 'NIS CSL-2026-001',
          avatarColor: Color(0xFF10B981),
          icon: Icons.person_rounded,
        ),
        const RecipientData(
          studentId: 3,
          name: 'Citra',
          bankName: 'Cendana B',
          accountNumber: 'NIS CSL-2026-002',
          avatarColor: Color(0xFF3B82F6),
          icon: Icons.person_rounded,
        ),
        const RecipientData(
          studentId: 4,
          name: 'Zikri',
          bankName: 'Cendana A',
          accountNumber: 'NIS CSL-2026-003',
          avatarColor: Color(0xFF8B5CF6),
          icon: Icons.person_rounded,
        ),
        const RecipientData(
          studentId: 5,
          name: 'Aiko',
          bankName: 'Cendana B',
          accountNumber: 'NIS CSL-2026-004',
          avatarColor: Color(0xFFEC4899),
          icon: Icons.person_rounded,
        ),
        const RecipientData(
          studentId: 6,
          name: 'Ralin',
          bankName: 'Cendana A',
          accountNumber: 'NIS CSL-2026-005',
          avatarColor: Color(0xFFF59E0B),
          icon: Icons.person_rounded,
        ),
      ];

      if (!mounted) return;

      setState(() {
        _recipients = mockPeers;
        if (_selectedRecipient == null && _recipients.isNotEmpty) {
          _selectedRecipient = _recipients.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _peerError = 'Gagal memuat daftar teman. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingPeers = false);
      }
    }
  }

  void _onKeyPressed(String key) {
    if (_noteFocusNode.hasFocus) _noteFocusNode.unfocus();

    if (_rawDigits.isEmpty && (key == '0' || key == '000')) return;
    if (_rawDigits.length + key.length > 12) return;

    final clampedCursor = _cursorIndex.clamp(0, _rawDigits.length);
    final before = _rawDigits.substring(0, clampedCursor);
    final after = _rawDigits.substring(clampedCursor);

    _rawDigits = before + key + after;
    _cursorIndex = clampedCursor + key.length;

    _resetCursorBlink();
    setState(() {});
  }

  void _onBackspacePressed() {
    if (_noteFocusNode.hasFocus) _noteFocusNode.unfocus();

    if (_rawDigits.isEmpty || _cursorIndex <= 0) return;

    final clampedCursor = _cursorIndex.clamp(0, _rawDigits.length);
    final before = _rawDigits.substring(0, clampedCursor - 1);
    final after = _rawDigits.substring(clampedCursor);

    _rawDigits = before + after;
    _cursorIndex = clampedCursor - 1;

    _resetCursorBlink();
    setState(() {});
  }

  void _setDirectAmount(int amount) {
    if (_noteFocusNode.hasFocus) _noteFocusNode.unfocus();

    _rawDigits = amount.toString();
    _cursorIndex = _rawDigits.length;

    _resetCursorBlink();
    setState(() {});
  }

  void _showRecipientSelector() {
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Tujuan Transfer',
                style: AppTheme.font(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Transfer saldo ke sesama siswa Cendana Smart Learning',
                style: AppTheme.font(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              if (_loadingPeers)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_peerError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Text(
                        _peerError!,
                        textAlign: TextAlign.center,
                        style: AppTheme.font(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadPeers,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              else if (_recipients.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Belum ada teman yang bisa dipilih.'),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView(
                    shrinkWrap: true,
                    children: _recipients.map((recipient) {
                      final isSelected = recipient == _selectedRecipient;
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: recipient.avatarColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(recipient.icon,
                              color: recipient.avatarColor, size: 22),
                        ),
                        title: Text(
                          recipient.name,
                          style: AppTheme.font(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${recipient.bankName} • ${recipient.accountNumber}',
                          style: AppTheme.font(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.primary, size: 22)
                            : null,
                        onTap: () {
                          setState(() => _selectedRecipient = recipient);
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTheme.font(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submitTransfer() async {
    final selected = _selectedRecipient;
    if (selected == null) {
      _showError('Pilih penerima transfer terlebih dahulu');
      return;
    }
    if (_numericAmount <= 0) {
      _showError('Masukkan nominal transfer terlebih dahulu');
      return;
    }
    if (_numericAmount > widget.state.balance) {
      _showError('Saldo dompet tidak mencukupi');
      return;
    }

    setState(() => _submitting = true);

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final txId = 'TRF-${DateTime.now().millisecondsSinceEpoch}';
      final after = (widget.state.balance - _numericAmount).clamp(0, double.infinity).toDouble();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _KioskTransferSuccessScreen(
            recipient: selected,
            amount: _formattedAmount,
            note: _noteController.text.trim(),
            transactionId: txId,
            balanceAfter: widget.state.formatCurrency(after),
            state: widget.state,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e is ApiException ? e.message : 'Transfer gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transfer Saldo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Recipient Selector Card ("Pilih Tujuan")
                    Text(
                      'Kirim Ke',
                      style: AppTheme.font(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SemestaCard(
                      onTap: _showRecipientSelector,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (_selectedRecipient?.avatarColor ??
                                      AppColors.primary)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _selectedRecipient?.icon ?? Icons.person_rounded,
                              color: _selectedRecipient?.avatarColor ??
                                  AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedRecipient?.name ??
                                      'Pilih Penerima Transfer',
                                  style: AppTheme.font(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedRecipient != null
                                      ? '${_selectedRecipient!.bankName} • ${_selectedRecipient!.accountNumber}'
                                      : 'Ketuk untuk memilih teman sekolah',
                                  style: AppTheme.font(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Amount Input
                    Text(
                      'Nominal Transfer',
                      style: AppTheme.font(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SemestaCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'Rp ',
                                style: AppTheme.font(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _rawDigits.isEmpty ? '0' : _formattedAmount,
                                  style: AppTheme.font(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Saldo: ${widget.state.formatCurrency(widget.state.balance)}',
                                style: AppTheme.font(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (_rawDigits.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _rawDigits = '';
                                      _cursorIndex = 0;
                                    });
                                  },
                                  child: Text(
                                    'Reset',
                                    style: AppTheme.font(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick amount chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _quickChip('+10RB', 10000),
                          const SizedBox(width: 8),
                          _quickChip('+20RB', 20000),
                          const SizedBox(width: 8),
                          _quickChip('+50RB', 50000),
                          const SizedBox(width: 8),
                          _quickChip('+100RB', 100000),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Note input
                    TextField(
                      controller: _noteController,
                      focusNode: _noteFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Catatan Transfer (Opsional)',
                        hintText: 'Contoh: Bayar buku / Jajan',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Numpad & Submit Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SemestaKeypad(
                    onKey: _onKeyPressed,
                    onBackspace: _onBackspacePressed,
                    actionLabel: _submitting ? 'Mengirim...' : 'Kirim',
                    onAction: _submitting ? null : _submitTransfer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String label, int amount) {
    return InkWell(
      onTap: () {
        final current = _numericAmount;
        _setDirectAmount(current + amount);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          label,
          style: AppTheme.font(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _KioskTransferSuccessScreen extends StatelessWidget {
  final RecipientData recipient;
  final String amount;
  final String note;
  final String transactionId;
  final String balanceAfter;
  final KioskState state;

  const _KioskTransferSuccessScreen({
    required this.recipient,
    required this.amount,
    required this.note,
    required this.transactionId,
    required this.balanceAfter,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SemestaCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Transfer Berhasil',
                    style: AppTheme.font(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp $amount',
                    style: AppTheme.font(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _row('Penerima', recipient.name),
                        const SizedBox(height: 8),
                        _row('Rekening / NIS', recipient.accountNumber),
                        const SizedBox(height: 8),
                        _row('ID Transaksi', transactionId),
                        const SizedBox(height: 8),
                        _row('Sisa Saldo', balanceAfter),
                        if (note.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _row('Catatan', note),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SemestaPrimaryButton(
                    label: 'Selesai',
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.font(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTheme.font(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
