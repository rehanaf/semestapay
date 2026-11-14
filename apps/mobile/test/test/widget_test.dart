// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import 'package:semestapay_ui_test/gallery_app.dart';

void main() {
  testWidgets('hamburger menu switches between shared UI pages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SemestaUiTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(SemestaBalanceCard), findsOneWidget);
    expect(find.text('Top Up'), findsOneWidget);
    await tester.tap(find.byTooltip('Sembunyikan saldo'));
    await tester.pumpAndSettle();
    expect(find.text('Rp ••••••••'), findsOneWidget);
    await tester.tap(find.byTooltip('Tampilkan saldo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Merchant').first);
    await tester.pumpAndSettle();
    expect(find.text('Kas Masuk'), findsOneWidget);
    await tester.tap(find.text('Student').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Buka navigasi halaman'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Formulir & Aksi').last);
    await tester.pumpAndSettle();

    expect(find.byType(SemestaTextField), findsOneWidget);
    expect(find.text('Primary action'), findsOneWidget);

    await tester.tap(find.byTooltip('Buka navigasi halaman'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Navigasi & Input').last);
    await tester.pumpAndSettle();
    expect(find.byType(SemestaKeypad), findsOneWidget);

    await tester.tap(find.byTooltip('Buka navigasi halaman'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cards & Status').last);
    await tester.pumpAndSettle();
    expect(find.byType(SemestaEmptyState), findsOneWidget);

    await tester.tap(find.byTooltip('Buka navigasi halaman'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Theme & Brand').last);
    await tester.pumpAndSettle();
    expect(find.text('Color tokens'), findsOneWidget);

    await tester.tap(find.byTooltip('Buka navigasi halaman'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toast').last);
    await tester.pumpAndSettle();
    expect(find.text('Success toast'), findsOneWidget);

    await tester.tap(find.byTooltip('Buka navigasi halaman'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login template').last);
    await tester.pumpAndSettle();
    expect(find.byType(SemestaLoginTemplate), findsOneWidget);
    expect(find.text('Masuk Akun Santri'), findsOneWidget);
    await tester.tap(find.text('Merchant').last);
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke Kasir'), findsOneWidget);
    expect(find.text('Masuk ke Merchant'), findsOneWidget);
  });
}
