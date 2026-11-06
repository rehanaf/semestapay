import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'state/student_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SmPayMobileApp(state: StudentState()));
}

class SmPayMobileApp extends StatelessWidget {
  final StudentState state;
  const SmPayMobileApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SemestaPAY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return state.isAuthenticated
              ? StudentShell(state: state)
              : StudentLoginScreen(state: state);
        },
      ),
    );
  }
}
