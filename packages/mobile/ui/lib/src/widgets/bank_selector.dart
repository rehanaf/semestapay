import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SemestaBankOption {
  final String code;
  final String name;
  final Color color;
  final String? abbreviation;
  final IconData icon;

  const SemestaBankOption({
    required this.code,
    required this.name,
    required this.color,
    this.abbreviation,
    this.icon = Icons.account_balance_rounded,
  });
}

class SemestaBankSelector extends StatefulWidget {
  final List<SemestaBankOption> banks;
  final ValueChanged<SemestaBankOption> onSelected;
  final String title;
  final String searchHint;
  final String? selectedCode;
  final bool collapseOnSelection;

  const SemestaBankSelector({
    super.key,
    required this.banks,
    required this.onSelected,
    this.title = 'Pilih bank',
    this.searchHint = 'Cari nama bank...',
    this.selectedCode,
    this.collapseOnSelection = false,
  });

  @override
  State<SemestaBankSelector> createState() => _SemestaBankSelectorState();
}

class _SemestaBankSelectorState extends State<SemestaBankSelector> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isExpanded = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final banks = widget.banks.where((bank) {
      return query.isEmpty ||
          bank.name.toLowerCase().contains(query) ||
          bank.code.toLowerCase().contains(query) ||
          (bank.abbreviation?.toLowerCase().contains(query) ?? false);
    }).toList();
    final selectedBank = widget.banks.cast<SemestaBankOption?>().firstWhere(
          (bank) => bank?.code == widget.selectedCode,
          orElse: () => null,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.collapseOnSelection &&
            widget.selectedCode != null &&
            !_isExpanded &&
            selectedBank != null)
          _buildSelectedBank(selectedBank)
        else ...[
          SizedBox(
            height: 46,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: AppTheme.font(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle:
                    AppTheme.font(fontSize: 13, color: AppColors.textLight),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.title,
            style: AppTheme.font(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          if (banks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Bank tidak ditemukan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            Container(
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
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: banks.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 68,
                  endIndent: 16,
                  color: AppColors.divider,
                ),
                itemBuilder: (context, index) {
                  final bank = banks[index];
                  final selected = bank.code == widget.selectedCode;
                  return InkWell(
                    onTap: () {
                      widget.onSelected(bank);
                      if (widget.collapseOnSelection) {
                        setState(() => _isExpanded = false);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: bank.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: bank.abbreviation == null
                                ? Icon(bank.icon, color: bank.color, size: 22)
                                : Text(
                                    bank.abbreviation!,
                                    maxLines: 1,
                                    style: AppTheme.font(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: bank.color,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              bank.name,
                              style: AppTheme.font(
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.chevron_right_rounded,
                            size: 20,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textLight,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSelectedBank(SemestaBankOption bank) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppTheme.font(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bank.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: bank.abbreviation == null
                    ? Icon(bank.icon, color: bank.color, size: 22)
                    : Text(
                        bank.abbreviation!,
                        style: AppTheme.font(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: bank.color,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  bank.name,
                  style: AppTheme.font(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _isExpanded = true),
                icon: const Icon(Icons.swap_horiz_rounded, size: 17),
                label: const Text('Ubah'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
