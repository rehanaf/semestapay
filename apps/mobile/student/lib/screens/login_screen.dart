import 'package:flutter/material.dart';
import '../state/student_state.dart';
import '../theme/app_theme.dart';
import '../widgets/student_card.dart';

class StudentLoginScreen extends StatefulWidget {
  final StudentState state;
  const StudentLoginScreen({super.key, required this.state});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _nisController = TextEditingController(text: '2026-001');
  final _pinController = TextEditingController(text: '123456');
  bool _obscurePin = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nisController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final nis = _nisController.text.trim();
    final pin = _pinController.text.trim();

    if (nis.isEmpty || pin.isEmpty) {
      setState(() => _errorMessage = 'NIS dan PIN wajib diisi.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await widget.state.login(nis, pin);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StudentShell(state: widget.state),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _messageFromError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _messageFromError(Object error) {
    final text = error.toString();
    if (text.contains('message: ')) {
      return text.split('message: ').last.replaceAll('}', '').trim();
    }
    return 'Gagal masuk. Periksa NIS/PIN dan koneksi internet.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SmPay Mobile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dompet digital santri untuk cek saldo & riwayat jajan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 30),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Masuk dengan Kartu Santri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    AppTheme.dangerColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.dangerColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const Text(
                          'NIS Santri',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nisController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixIcon:
                                Icon(Icons.badge_outlined, size: 20),
                            hintText: 'Contoh: 2026-001',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'PIN Santri',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _pinController,
                          obscureText: _obscurePin,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon:
                                const Icon(Icons.lock_outline_rounded, size: 20),
                            hintText: '6 digit PIN',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePin
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePin = !_obscurePin,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loading ? null : _handleLogin,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Buka Dompet Santri'),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () {
                            _nisController.text = '2026-001';
                            _pinController.text = '123456';
                            setState(() => _errorMessage = null);
                          },
                          child: const Text(
                            'Gunakan Akun Demo (2026-001 / 123456)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StudentShell extends StatefulWidget {
  final StudentState state;
  const StudentShell({super.key, required this.state});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  void showTab(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      StudentHomeScreen(state: widget.state),
      StudentHistoryScreen(state: widget.state),
      StudentBillsScreen(state: widget.state),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.request_quote_outlined),
            selectedIcon: Icon(Icons.request_quote_rounded),
            label: 'Tagihan',
          ),
        ],
      ),
    );
  }
}

class StudentHomeScreen extends StatefulWidget {
  final StudentState state;
  const StudentHomeScreen({super.key, required this.state});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.state.refresh().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final student = widget.state.student;
        final dashboard = widget.state.dashboard;
        final recent = widget.state.mutations.take(5).toList();

        if (student == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SmPay Mobile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Halo, ${student.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Keluar',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () {
                  widget.state.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => StudentLoginScreen(state: widget.state),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: widget.state.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                StudentCard(state: widget.state, student: student),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Limit Harian',
                        value: widget.state
                            .formatCurrency(student.dailyLimit),
                        icon: Icons.speed_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        label: 'Sisa Limit Hari Ini',
                        value: widget.state.formatCurrency(
                          dashboard?.remainingDailyLimit ?? 0,
                        ),
                        icon: Icons.savings_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transaksi Terakhir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final shell = context
                            .findAncestorStateOfType<_StudentShellState>();
                        shell?.showTab(1);
                      },
                      child: const Text('Lihat Semua →'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (recent.isEmpty)
                  const _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum Ada Transaksi',
                    subtitle: 'Mutasi dompet santri akan tampil di sini.',
                  )
                else
                  ...recent.map(
                    (mutation) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MutationTile(
                        state: widget.state,
                        mutation: mutation,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StudentHistoryScreen extends StatelessWidget {
  final StudentState state;
  const StudentHistoryScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Riwayat Transaksi'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => state.refresh(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: state.refresh,
            child: state.mutations.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 160),
                      _EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Belum Ada Transaksi',
                        subtitle: 'Belum ada mutasi pada dompet santri.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.mutations.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) => _MutationTile(
                      state: state,
                      mutation: state.mutations[idx],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class StudentBillsScreen extends StatelessWidget {
  final StudentState state;
  const StudentBillsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final bills = state.dashboard?.bills ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan Santri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => state.refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: bills.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  _EmptyState(
                    icon: Icons.request_quote_outlined,
                    title: 'Tidak Ada Tagihan',
                    subtitle: 'Tagihan SPP atau pondok akan tampil di sini.',
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bills.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final bill = bills[idx];
                  final paid = bill.isPaid;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: (paid
                                    ? AppTheme.successColor
                                    : AppTheme.primaryColor)
                                .withValues(alpha: 0.12),
                            child: Icon(
                              paid
                                  ? Icons.check_circle_rounded
                                  : Icons.request_quote_outlined,
                              color: paid
                                  ? AppTheme.successColor
                                  : AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bill.description ?? bill.type.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${bill.period ?? '-'} • jatuh tempo ${bill.dueDate ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                state.formatCurrency(bill.remainingAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                paid ? 'LUNAS' : bill.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: paid
                                      ? AppTheme.successColor
                                      : AppTheme.dangerColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MutationTile extends StatelessWidget {
  final StudentState state;
  final dynamic mutation;

  const _MutationTile({required this.state, required this.mutation});

  @override
  Widget build(BuildContext context) {
    final bool isCredit = mutation.isCredit as bool;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (isCredit ? AppTheme.successColor : AppTheme.primaryColor)
                  .withValues(alpha: 0.12),
          child: Icon(
            isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: isCredit ? AppTheme.successColor : AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          mutation.merchant ??
              mutation.outlet ??
              (isCredit ? 'Top Up Saldo' : 'Pembayaran'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        subtitle: Text(
          state.formatDate(mutation.createdAt as String?),
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'}${state.formatCurrency(mutation.amount as double)}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: isCredit ? AppTheme.successColor : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
