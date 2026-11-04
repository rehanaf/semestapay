import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'state/pos_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final posState = PosState();
  runApp(SmPayMerchantApp(posState: posState));
}

class SmPayMerchantApp extends StatelessWidget {
  final PosState posState;
  const SmPayMerchantApp({super.key, required this.posState});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmPay Merchant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: posState.isAuthenticated
          ? HomeScreen(posState: posState)
          : LoginScreen(posState: posState),
    );
  }
}
