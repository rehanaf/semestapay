import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';
import 'package:student_app/main.dart';
import 'package:student_app/screens/history_page.dart';
import 'package:student_app/screens/topup/topup_flow.dart';
import 'package:student_app/screens/topup/topup_virtual_account_screen.dart';
import 'package:student_app/screens/transfer/student_transfer_list_screen.dart';
import 'package:student_app/screens/transfer/transfer_screen.dart';
import 'package:student_app/state/student_state.dart';

void main() {
  testWidgets('App renders Semestapay Mobile login screen initially', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(SmPayMobileApp(state: StudentState()));

    expect(find.text('Semestapay Mobile'), findsOneWidget);
    expect(find.text('Masuk Sekarang'), findsOneWidget);
  });

  testWidgets('top up creates a dynamic VA after bank and amount selection', (
    WidgetTester tester,
  ) async {
    final api = _TopUpApiClient();
    await tester.pumpWidget(MaterialApp(home: TopUpScreen(api: api)));
    await tester.pumpAndSettle();

    expect(api.callCount, 0);
    expect(find.text('Fixed VA'), findsNothing);
    expect(find.text('Dynamic VA'), findsNothing);

    await tester.tap(find.text('BCA Virtual Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(SemestaKeypad), findsOneWidget);
    expect(find.text('Rekening Tujuan'), findsNothing);
    for (final digit in ['2', '5', '000']) {
      await tester.tap(
        find.descendant(
          of: find.byType(SemestaKeypad),
          matching: find.text(digit),
        ),
      );
      await tester.pump();
    }
    expect(find.text('25.000'), findsOneWidget);
    await tester.longPress(
      find.descendant(
        of: find.byType(SemestaKeypad),
        matching: find.byIcon(Icons.backspace_outlined),
      ),
    );
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('semesta-amount-display'))).data,
      '0',
    );
    for (final digit in ['2', '5', '000']) {
      await tester.tap(
        find.descendant(
          of: find.byType(SemestaKeypad),
          matching: find.text(digit),
        ),
      );
      await tester.pump();
    }
    await tester.tap(find.text('Buat Virtual Account').last);
    await tester.pumpAndSettle();

    expect(api.callCount, 1);
    expect(api.requestedAmount, 25000);
    expect(api.requestedPaymentMethod, 'BC');
    expect(api.requestedVaType, 'dynamic');
    expect(find.byType(VirtualAccountDetailScreen), findsOneWidget);
    expect(find.text('Virtual Account Siap Dibayar'), findsOneWidget);
    expect(find.text('7007014001444348'), findsOneWidget);
  });

  testWidgets('transfer uses package recipient picker and amount entry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TransferScreen()));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(SemestaAmountEntry), findsOneWidget);
    await tester.tap(find.text('Ganti'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Pilih Tujuan Transfer'), findsOneWidget);

    await tester.tap(find.text('Siti Rahma'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Siti Rahma'), findsOneWidget);

    for (final digit in ['2', '5', '000']) {
      await tester.tap(
        find.descendant(
          of: find.byType(SemestaKeypad),
          matching: find.text(digit),
        ),
      );
      await tester.pump();
    }
    await tester.tap(find.text('Lanjutkan').last);
    await tester.pumpAndSettle();

    expect(find.text('Bukti Transaksi'), findsOneWidget);
    expect(find.text('Siti Rahma'), findsNWidgets(2));
    expect(find.text('Rp 25.000'), findsNWidgets(2));
  });

  testWidgets(
    'student transfer searches recipients and posts a real transfer',
    (WidgetTester tester) async {
      final api = _StudentTransferApiClient();
      await tester.pumpWidget(
        MaterialApp(
          home: StudentTransferListScreen(
            api: api,
            balance: 100000,
            onTransferComplete: () async {
              api.refreshCalled = true;
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Alya Student'), findsOneWidget);
      expect(find.text('Siti Student'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('student-transfer-search')),
        'Siti',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(api.lastSearchQuery, 'Siti');
      expect(find.text('Siti Student'), findsOneWidget);
      expect(find.text('Alya Student'), findsNothing);

      await tester.tap(find.text('Siti Student'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(SemestaAmountEntry), findsOneWidget);

      for (final digit in ['2', '5', '000']) {
        await tester.tap(
          find.descendant(
            of: find.byType(SemestaKeypad),
            matching: find.text(digit),
          ),
        );
        await tester.pump();
      }
      await tester.tap(find.text('Kirim Uang').last);
      await tester.pumpAndSettle();

      expect(api.transferRecipientId, 20);
      expect(api.transferAmount, 25000);
      expect(api.refreshCalled, isTrue);
      expect(find.text('TRX-REAL-TRANSFER-1'), findsNWidgets(2));
      expect(find.text('Rp 25.000'), findsNWidgets(2));
    },
  );

  testWidgets('history opens the detail page for a created virtual account', (
    WidgetTester tester,
  ) async {
    final state = StudentState();
    await tester.pumpWidget(MaterialApp(home: HistoryPage(state: state)));
    await tester.pumpAndSettle();
    expect(find.text('Top Up via BCA Virtual Account'), findsNothing);

    state.addVirtualAccount(
      VirtualAccountInfo(
        id: '2',
        studentId: 1,
        studentName: 'Santri Tes',
        provider: 'duitku',
        paymentMethod: 'BC',
        bankName: 'BCA Virtual Account',
        accountNumber: '7007014001444348',
        merchantOrderId: 'DYNAMIC-HISTORY-2',
        amount: 25000,
        status: 'pending',
        expiresAt: '2026-11-14T00:00:00+00:00',
        createdAt: '2026-11-13T00:00:00+00:00',
        isNew: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Top Up via BCA Virtual Account'), findsOneWidget);
    await tester.tap(find.text('Top Up via BCA Virtual Account'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Virtual Account'), findsOneWidget);
    expect(find.text('7007014001444348'), findsOneWidget);
  });
}

class _TopUpApiClient extends SemestaPayApiClient {
  int callCount = 0;
  double? requestedAmount;
  String? requestedPaymentMethod;
  String? requestedVaType;

  @override
  Future<VirtualAccountInfo> getOrCreateTopupVa({
    double amount = 10000,
    String? paymentMethod,
    String vaType = 'fixed',
    bool forceNew = false,
  }) async {
    callCount++;
    requestedAmount = amount;
    requestedPaymentMethod = paymentMethod;
    requestedVaType = vaType;
    return VirtualAccountInfo(
      id: '1',
      studentId: 1,
      studentName: 'Santri Tes',
      provider: 'duitku',
      paymentMethod: 'BC',
      bankName: 'BCA Virtual Account',
      accountNumber: '7007014001444348',
      merchantOrderId: 'DYNAMIC-1-20261113000000-ABCD',
      amount: amount,
      status: 'pending',
      isStatic: false,
      isOpenAmount: false,
      expiresAt: '2026-11-14T00:00:00+00:00',
      isNew: false,
    );
  }
}

class _StudentTransferApiClient extends SemestaPayApiClient {
  String? lastSearchQuery;
  int? transferRecipientId;
  double? transferAmount;
  bool refreshCalled = false;

  @override
  Future<List<StudentTransferRecipient>> searchStudentTransferRecipients({
    String query = '',
    int limit = 30,
  }) async {
    lastSearchQuery = query;
    const students = [
      StudentTransferRecipient(
        id: 10,
        name: 'Alya Student',
        nis: 'STU-001',
        className: '7A',
      ),
      StudentTransferRecipient(
        id: 20,
        name: 'Siti Student',
        nis: 'STU-002',
        className: '7B',
      ),
    ];
    if (query.isEmpty) return students;
    final normalizedQuery = query.toLowerCase();
    return students
        .where(
          (student) =>
              student.name.toLowerCase().contains(normalizedQuery) ||
              student.nis.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  @override
  Future<StudentTransferReceipt> transferToStudent({
    required int recipientId,
    required double amount,
    String? note,
    String? idempotencyKey,
  }) async {
    transferRecipientId = recipientId;
    transferAmount = amount;
    return const StudentTransferReceipt(
      transactionId: 'TRX-REAL-TRANSFER-1',
      recipientTransactionId: 'TRX-REAL-TRANSFER-2',
      recipientId: 20,
      recipientName: 'Siti Student',
      recipientNis: 'STU-002',
      amount: 25000,
      balanceAfter: 75000,
      status: 'posted',
      note: null,
      createdAt: '2026-11-14T12:00:00+00:00',
    );
  }
}
