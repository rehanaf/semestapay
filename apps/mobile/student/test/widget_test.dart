import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/main.dart';
import 'package:student_app/state/student_state.dart';

void main() {
  testWidgets('App renders Semestapay Mobile login screen initially',
      (WidgetTester tester) async {
    await tester.pumpWidget(SmPayMobileApp(state: StudentState()));

    expect(find.text('Semestapay Mobile'), findsOneWidget);
    expect(find.text('Masuk Sekarang'), findsOneWidget);
  });
}
