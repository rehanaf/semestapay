import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'state/student_state.dart';
import 'theme/app_theme.dart';

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
      title: 'SmPay Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: state.isAuthenticated
          ? StudentShell(state: state)
          : StudentLoginScreen(state: state),
    );
  }
}
