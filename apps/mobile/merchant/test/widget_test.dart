import 'package:flutter_test/flutter_test.dart';
import 'package:merchant_app/main.dart';
import 'package:merchant_app/state/pos_state.dart';

void main() {
  testWidgets('App renders login screen initially', (WidgetTester tester) async {
    final posState = PosState();
    await tester.pumpWidget(SmPayMerchantApp(posState: posState));
    expect(find.text('SmPay Merchant'), findsOneWidget);
    expect(find.text('Buka Terminal Kasir'), findsOneWidget);
  });
}
