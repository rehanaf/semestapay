import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import 'transfer_success_screen.dart';

class RecipientData {
  final String name;
  final String bankName;
  final String accountNumber;
  final Color avatarColor;
  final IconData icon;

  const RecipientData({
    required this.name,
    required this.bankName,
    required this.accountNumber,
    required this.avatarColor,
    required this.icon,
  });
}

class TransferScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onBackToHome;
  final RecipientData? initialRecipient;

  const TransferScreen({
    super.key,
    this.isTab = false,
    this.onBackToHome,
    this.initialRecipient,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  static const _balance = 24850000;

  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  final List<RecipientData> _recipients = const [
    RecipientData(
      name: 'Budi Santoso',
      bankName: 'Bank BCA',
      accountNumber: '8820 1928 331',
      avatarColor: Color(0xFF005696),
      icon: Icons.account_balance_rounded,
    ),
    RecipientData(
      name: 'Siti Rahma',
      bankName: 'Bank Mandiri',
      accountNumber: '1320 0981 223',
      avatarColor: Color(0xFF00387A),
      icon: Icons.account_balance_rounded,
    ),
    RecipientData(
      name: 'Ahmad Pratama',
      bankName: 'Bank BRI',
      accountNumber: '0021 9831 002',
      avatarColor: Color(0xFF00529C),
      icon: Icons.account_balance_rounded,
    ),
    RecipientData(
      name: 'Reyhan Official',
      bankName: 'Semestapay ID',
      accountNumber: '0812 3456 7890',
      avatarColor: AppColors.primary,
      icon: Icons.phone_android_rounded,
    ),
  ];

  late RecipientData _selectedRecipient;
  int _amount = 0;
  String _formattedAmount = '0';

  @override
  void initState() {
    super.initState();
    _selectedRecipient = widget.initialRecipient ?? _recipients[0];
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _showRecipientSelector() async {
    final selected = await SemestaRecipientPicker.show(
      context: context,
      recipients: _recipients
          .map(
            (recipient) => SemestaRecipientOption(
              id: recipient.name,
              name: recipient.name,
              subtitle: '${recipient.bankName} • ${recipient.accountNumber}',
              color: recipient.avatarColor,
              icon: recipient.icon,
            ),
          )
          .toList(),
      selectedId: _selectedRecipient.name,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedRecipient = _recipients.firstWhere(
        (recipient) => recipient.name == selected.id,
      );
    });
  }

  void _continueTransfer() {
    if (_amount > _balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo tidak mencukupi (Saldo: Rp ${SemestaAmountFormatter.format(_balance)})',
            style: AppTheme.font(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final note = _noteController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransferSuccessScreen(
          recipient: _selectedRecipient,
          amount: _formattedAmount,
          note: note,
          onBackToHome: widget.onBackToHome,
        ),
      ),
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
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Transfer',
          style: AppTheme.font(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: SemestaAmountEntry(
          header: SemestaRecipientSummaryCard(
            name: _selectedRecipient.name,
            subtitle:
                '${_selectedRecipient.bankName} • ${_selectedRecipient.accountNumber}',
            color: _selectedRecipient.avatarColor,
            icon: _selectedRecipient.icon,
            onChange: () => _showRecipientSelector(),
          ),
          amountLabel: 'Nominal Transfer',
          balanceLabel: 'Saldo: Rp ${SemestaAmountFormatter.format(_balance)}',
          continueLabel: 'Lanjutkan',
          accentColor: AppColors.primary,
          quickActions: [
            const SemestaAmountQuickAction(label: '+50 rb', amount: 50000),
            const SemestaAmountQuickAction(label: '+100 rb', amount: 100000),
            const SemestaAmountQuickAction(label: '+200 rb', amount: 200000),
            const SemestaAmountQuickAction(label: '+500 rb', amount: 500000),
            const SemestaAmountQuickAction(
              label: '1 jt',
              amount: 1000000,
              setAmount: true,
            ),
            const SemestaAmountQuickAction(
              label: 'Maksimal',
              amount: _balance,
              setAmount: true,
            ),
          ],
          extraContent: _buildNoteInput(),
          extraContentFocusNode: _noteFocusNode,
          onAmountChanged: (amount) {
            setState(() {
              _amount = amount;
              _formattedAmount = SemestaAmountFormatter.format(amount);
            });
          },
          onContinue: (_) => _continueTransfer(),
        ),
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _noteController,
        focusNode: _noteFocusNode,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        maxLength: 50,
        style: AppTheme.font(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          prefixIcon: const Icon(
            Icons.edit_note_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          hintText: 'Tulis catatan transfer (opsional)...',
          hintStyle: AppTheme.font(fontSize: 13, color: AppColors.textLight),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
