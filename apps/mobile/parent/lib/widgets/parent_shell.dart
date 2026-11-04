import 'package:flutter/material.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import '../screens/login_screen.dart';
import '../state/parent_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ParentShell extends StatefulWidget {
  final ParentState state;
  const ParentShell({super.key, required this.state});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _index = 0;

  void showTab(int index) {
    setState(() => _index = index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.state.refreshChild().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ParentHomeScreen(state: widget.state),
      ParentHistoryScreen(state: widget.state),
      ParentBillsScreen(state: widget.state),
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

class ParentHomeScreen extends StatelessWidget {
  final ParentState state;
  const ParentHomeScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final child = state.selectedChild;
        final wallet = state.wallet;

        if (child == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('SmPay Ortu')),
            body: const EmptyState(
              icon: Icons.family_restroom_outlined,
              title: 'Belum Ada Data Anak',
              subtitle: 'Hubungkan akun wali ke data santri di pesantren.',
            ),
          );
        }

        final balance = wallet?.balance ?? child.balance;
        final recent = state.mutations.take(5).toList();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SmPay Ortu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Wali: ${state.user?.name ?? '-'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              if (state.children.length > 1)
                PopupMenuButton<ParentChild>(
                  icon: const Icon(Icons.swap_horiz_rounded),
                  onSelected: (value) => state.selectChild(value),
                  itemBuilder: (context) => state.children
                      .map(
                        (c) => PopupMenuItem<ParentChild>(
                          value: c,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                ),
              IconButton(
                tooltip: 'Keluar',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () {
                  state.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => ParentLoginScreen(state: state),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: state.refreshChild,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                ChildCard(state: state, child: child, balance: balance),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Tagihan Belum Lunas',
                        value: state.formatCurrency(state.outstandingBills),
                        icon: Icons.receipt_long_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        label: 'Total Mutasi',
                        value: '${state.mutations.length} trans.',
                        icon: Icons.swap_vert_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Aktivitas Terakhir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final shell = context
                            .findAncestorStateOfType<_ParentShellState>();
                        shell?.showTab(1);
                      },
                      child: const Text('Lihat Semua →'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (recent.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum Ada Transaksi',
                    subtitle: 'Riwayat jajan anak akan tampil di sini.',
                  )
                else
                  ...recent.map(
                    (mutation) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MutationTile(state: state, mutation: mutation),
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

class ParentHistoryScreen extends StatelessWidget {
  final ParentState state;
  const ParentHistoryScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Riwayat Transaksi Anak'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => state.refreshChild(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: state.refreshChild,
            child: state.mutations.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 160),
                      EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Belum Ada Transaksi',
                        subtitle: 'Belum ada mutasi pada tabungan anak.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.mutations.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) => MutationTile(
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

class ParentBillsScreen extends StatelessWidget {
  final ParentState state;
  const ParentBillsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final bills = state.bills;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tagihan Anak'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => state.refreshChild(),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: state.refreshChild,
            child: bills.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 160),
                      EmptyState(
                        icon: Icons.request_quote_outlined,
                        title: 'Tidak Ada Tagihan',
                        subtitle: 'Semua tagihan anak saat ini sudah terpantau.',
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
                                      bill.description ??
                                          bill.type.toUpperCase(),
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
      },
    );
  }
}
