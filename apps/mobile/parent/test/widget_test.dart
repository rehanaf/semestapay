import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/main.dart';
import 'package:parent_app/state/parent_state.dart';

void main() {
  testWidgets('App renders SmPay Ortu login screen initially',
      (WidgetTester tester) async {
    await tester.pumpWidget(SmPayOrtuApp(state: ParentState()));

    expect(find.text('SmPay Ortu'), findsOneWidget);
    expect(find.text('Buka Dashboard Ortu'), findsOneWidget);
  });
}
