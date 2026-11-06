import 'package:flutter/material.dart';
import 'package:semestapay_mobile_ui/semestapay_mobile_ui.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'state/pos_state.dart';

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
      title: 'SemestaPAY Merchant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.merchant,
      home: ListenableBuilder(
        listenable: posState,
        builder: (context, _) {
          return posState.isAuthenticated
              ? MerchantHomeScreen(posState: posState)
              : LoginScreen(posState: posState);
        },
      ),
    );
  }
}
