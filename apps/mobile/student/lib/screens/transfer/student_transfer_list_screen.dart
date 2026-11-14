import 'dart:async';

import 'package:flutter/material.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import 'student_transfer_amount_screen.dart';

class StudentTransferListScreen extends StatefulWidget {
  final SemestaPayApiClient api;
  final double balance;
  final Future<void> Function()? onTransferComplete;

  const StudentTransferListScreen({
    super.key,
    required this.api,
    this.balance = 0,
    this.onTransferComplete,
  });

  @override
  State<StudentTransferListScreen> createState() =>
      _StudentTransferListScreenState();
}

class _StudentTransferListScreenState extends State<StudentTransferListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<int> _favoriteIds = {};
  Timer? _searchDebounce;
  List<StudentTransferRecipient> _recipients = [];
  int _selectedTab = 0;
  int _requestId = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_searchRecipients(''));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  List<StudentTransferRecipient> get _visibleRecipients => _selectedTab == 0
      ? _recipients
      : _recipients
            .where((recipient) => _favoriteIds.contains(recipient.id))
            .toList();

  Future<void> _searchRecipients(String query) async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final recipients = await widget.api.searchStudentTransferRecipients(
        query: query.trim(),
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _recipients = recipients;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _errorMessage =
            'Gagal memuat daftar student. Periksa koneksi internet.';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 250),
      () => _searchRecipients(query),
    );
  }

  void _toggleFavorite(StudentTransferRecipient recipient) {
    setState(() {
      if (!_favoriteIds.add(recipient.id)) {
        _favoriteIds.remove(recipient.id);
      }
    });
  }

  void _openTransfer(StudentTransferRecipient recipient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentTransferAmountScreen(
          api: widget.api,
          recipient: recipient,
          balance: widget.balance,
          onTransferComplete: widget.onTransferComplete,
        ),
      ),
    );
  }

  Future<void> _openRecipientPicker() async {
    final selected = await SemestaRecipientPicker.show(
      context: context,
      title: 'Pilih Student Tujuan',
      subtitle: 'Student aktif selain akun Anda',
      recipients: _recipients
          .map(
            (recipient) => SemestaRecipientOption(
              id: '${recipient.id}',
              name: recipient.name,
              subtitle:
                  '${recipient.nis} • ${recipient.className ?? 'Student'}',
              color: AppColors.primary,
            ),
          )
          .toList(),
      selectedId: '',
    );
    if (selected == null || !mounted) return;
    final id = int.tryParse(selected.id);
    final recipient = _recipients.where((item) => item.id == id).firstOrNull;
    if (recipient != null) _openTransfer(recipient);
  }

  @override
  Widget build(BuildContext context) {
    final recipients = _visibleRecipients;
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transfer ke Student',
          style: AppTheme.font(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      key: const Key('student-transfer-search'),
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      style: AppTheme.font(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau NIS student...',
                        hintStyle: AppTheme.font(
                          fontSize: 13,
                          color: AppColors.textLight,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(0, 'Semua'),
                        _buildTabButton(1, 'Favorit'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildRecipientList(recipients)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: _isLoading || _recipients.isEmpty
                ? null
                : _openRecipientPicker,
            icon: const Icon(Icons.person_search_rounded, color: Colors.white),
            label: Text(
              'Pilih Student',
              style: AppTheme.font(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientList(List<StudentTransferRecipient> recipients) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 42,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _searchRecipients(_searchController.text),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (recipients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_search_rounded,
                size: 48,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 12),
              Text(
                _selectedTab == 1
                    ? 'Belum Ada Favorit'
                    : 'Student Tidak Ditemukan',
                style: AppTheme.font(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      key: const PageStorageKey('student-transfer-list'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _selectedTab == 0 ? 'Student Aktif' : 'Student Favorit',
            style: AppTheme.font(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
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
            itemCount: recipients.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              color: AppColors.divider,
            ),
            itemBuilder: (context, index) {
              final recipient = recipients[index];
              final isFavorite = _favoriteIds.contains(recipient.id);
              return InkWell(
                onTap: () => _openTransfer(recipient),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipient.name,
                              style: AppTheme.font(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'NIS ${recipient.nis} • ${recipient.className ?? 'Student'}',
                              style: AppTheme.font(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: isFavorite
                            ? 'Hapus dari favorit'
                            : 'Tambah ke favorit',
                        icon: Icon(
                          isFavorite
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: isFavorite
                              ? const Color(0xFFFFB300)
                              : AppColors.textLight,
                          size: 24,
                        ),
                        onPressed: () => _toggleFavorite(recipient),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.font(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
