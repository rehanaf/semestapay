import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

void main() {
  testWidgets('SemestaBalanceCard menampilkan saldo terformat', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SemestaBalanceCard(
            balance: 150000,
            ownerName: 'Ahmad Fauzi',
          ),
        ),
      ),
    );

    expect(find.text('Rp 150.000'), findsOneWidget);
    expect(find.text('Ahmad Fauzi'), findsOneWidget);
  });
}
