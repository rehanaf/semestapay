import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import 'gallery_pages.dart';

class SemestaUiTestApp extends StatefulWidget {
  const SemestaUiTestApp({super.key});

  @override
  State<SemestaUiTestApp> createState() => _SemestaUiTestAppState();
}

class _SemestaUiTestAppState extends State<SemestaUiTestApp> {
  static const _pages = [
    _GalleryDestination('Overview', Icons.dashboard_rounded),
    _GalleryDestination('Theme & Brand', Icons.palette_rounded),
    _GalleryDestination('Cards & Status', Icons.layers_rounded),
    _GalleryDestination('Formulir & Aksi', Icons.touch_app_rounded),
    _GalleryDestination('Navigasi & Input', Icons.dialpad_rounded),
    _GalleryDestination('Toast', Icons.notifications_active_rounded),
    _GalleryDestination('Login template', Icons.login_rounded),
  ];

  int _currentPage = 0;
  bool _merchantTheme = false;

  Future<void> _openPageMenu(BuildContext context) async {
    final selectedPage = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shared UI components',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      final isSelected = index == _currentPage;
                      return ListTile(
                        leading: Icon(
                          page.icon,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        title: Text(page.title),
                        selected: isSelected,
                        selectedTileColor: AppColors.primaryLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () => Navigator.pop(context, index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selectedPage != null) {
      setState(() => _currentPage = selectedPage);
    }
  }

  Widget _buildCurrentPage() {
    return switch (_currentPage) {
      0 => const OverviewGalleryPage(),
      1 => ThemeGalleryPage(
        merchantTheme: _merchantTheme,
        onToggleTheme: () => setState(() => _merchantTheme = !_merchantTheme),
      ),
      2 => const ComponentsGalleryPage(),
      3 => const FormsGalleryPage(),
      4 => const NavigationGalleryPage(),
      5 => const ToastGalleryPage(),
      _ => const LoginTemplateGalleryPage(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Semesta UI Test',
      theme: _merchantTheme ? AppTheme.merchant : AppTheme.light,
      home: Scaffold(
        appBar: AppBar(
          title: Text(_pages[_currentPage].title),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: SemestaAvatar(name: 'SemestaPay', size: 34),
            ),
          ],
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(_currentPage),
              child: _buildCurrentPage(),
            ),
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () => _openPageMenu(context),
            tooltip: 'Buka navigasi halaman',
            child: const Icon(Icons.menu_rounded),
          ),
        ),
      ),
    );
  }
}

class _GalleryDestination {
  final String title;
  final IconData icon;

  const _GalleryDestination(this.title, this.icon);
}
