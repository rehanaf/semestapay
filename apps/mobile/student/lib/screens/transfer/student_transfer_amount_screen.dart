import 'package:flutter/material.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import 'transfer_screen.dart';
import 'transfer_success_screen.dart';

class StudentTransferAmountScreen extends StatefulWidget {
  final SemestaPayApiClient api;
  final StudentTransferRecipient recipient;
  final double balance;
  final Future<void> Function()? onTransferComplete;

  const StudentTransferAmountScreen({
    super.key,
    required this.api,
    required this.recipient,
    required this.balance,
    this.onTransferComplete,
  });

  @override
  State<StudentTransferAmountScreen> createState() =>
      _StudentTransferAmountScreenState();
}

class _StudentTransferAmountScreenState
    extends State<StudentTransferAmountScreen> {
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitTransfer(int amount) async {
    setState(() => _isLoading = true);
    try {
      final receipt = await widget.api.transferToStudent(
        recipientId: widget.recipient.id,
        amount: amount.toDouble(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      try {
        await widget.onTransferComplete?.call();
      } catch (_) {
        // The transfer is already committed; refresh failure must not hide its receipt.
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransferSuccessScreen(
            recipient: RecipientData(
              name: receipt.recipientName,
              bankName: 'Wallet Student',
              accountNumber: 'NIS ${receipt.recipientNis}',
              avatarColor: AppColors.primary,
              icon: Icons.person_rounded,
            ),
            amount: SemestaAmountFormatter.format(receipt.amount.round()),
            note: receipt.note ?? '',
            transactionId: receipt.transactionId,
            transactionAt: receipt.createdAt,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        AppToast.show(context, error.message, type: ToastType.error);
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          'Transfer gagal diproses. Periksa koneksi internet.',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipient = widget.recipient;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Nominal Transfer'), centerTitle: true),
      body: SafeArea(
        child: SemestaAmountEntry(
          header: SemestaRecipientSummaryCard(
            name: recipient.name,
            subtitle: recipient.nis,
            color: AppColors.primary,
            icon: Icons.person_rounded,
            onChange: () => Navigator.pop(context),
          ),
          amountLabel: 'Nominal Transfer',
          balanceLabel:
              'Saldo: Rp ${SemestaAmountFormatter.format(widget.balance.round())}',
          continueLabel: 'Kirim Uang',
          accentColor: AppColors.primary,
          minimumAmount: 1,
          quickActions: const [
            SemestaAmountQuickAction(label: '+10 rb', amount: 10000),
            SemestaAmountQuickAction(label: '+25 rb', amount: 25000),
            SemestaAmountQuickAction(label: '+50 rb', amount: 50000),
            SemestaAmountQuickAction(label: '+100 rb', amount: 100000),
            SemestaAmountQuickAction(
              label: 'Pas 50 rb',
              amount: 50000,
              setAmount: true,
            ),
          ],
          extraContent: _buildNoteInput(),
          extraContentFocusNode: _noteFocusNode,
          isLoading: _isLoading,
          onContinue: _submitTransfer,
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
