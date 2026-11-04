import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'state/parent_state.dart';
import 'theme/app_theme.dart';
import 'widgets/parent_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SmPayOrtuApp(state: ParentState()));
}

class SmPayOrtuApp extends StatelessWidget {
  final ParentState state;
  const SmPayOrtuApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmPay Ortu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: state.isAuthenticated
          ? ParentShell(state: state)
          : ParentLoginScreen(state: state),
    );
  }
}
