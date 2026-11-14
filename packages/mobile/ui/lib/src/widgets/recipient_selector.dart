import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SemestaRecipientOption {
  final String id;
  final String name;
  final String subtitle;
  final Color color;
  final IconData icon;

  const SemestaRecipientOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.color,
    this.icon = Icons.account_balance_rounded,
  });
}

class SemestaRecipientSummaryCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onChange;

  const SemestaRecipientSummaryCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.onChange,
    this.icon = Icons.account_balance_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.font(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: Text(
              'Ganti',
              style: AppTheme.font(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SemestaRecipientPicker {
  const SemestaRecipientPicker._();

  static Future<SemestaRecipientOption?> show({
    required BuildContext context,
    required List<SemestaRecipientOption> recipients,
    required String selectedId,
    String title = 'Pilih Tujuan Transfer',
    String subtitle = 'Pilih rekening atau kontak tersimpan',
  }) {
    return showModalBottomSheet<SemestaRecipientOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecipientPickerSheet(
        recipients: recipients,
        selectedId: selectedId,
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}

class _RecipientPickerSheet extends StatelessWidget {
  final List<SemestaRecipientOption> recipients;
  final String selectedId;
  final String title;
  final String subtitle;

  const _RecipientPickerSheet({
    required this.recipients,
    required this.selectedId,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
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
              title,
              style: AppTheme.font(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.font(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: recipients.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final recipient = recipients[index];
                  final isSelected = recipient.id == selectedId;
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: recipient.color.withValues(
                          alpha: 0.15,
                        ),
                        child: Icon(recipient.icon, color: recipient.color),
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
                        recipient.subtitle,
                        style: AppTheme.font(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 22,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, recipient),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
