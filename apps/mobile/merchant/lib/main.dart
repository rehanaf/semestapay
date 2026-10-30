import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'state/pos_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final posState = PosState();
  runApp(SemestaPayMerchantApp(posState: posState));
}

class SemestaPayMerchantApp extends StatelessWidget {
  final PosState posState;
  const SemestaPayMerchantApp({super.key, required this.posState});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SemestaPay POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: posState.isAuthenticated
          ? HomeScreen(posState: posState)
          : LoginScreen(posState: posState),
    );
  }
}
