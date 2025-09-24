
import 'package:flutter/material.dart';
import 'views/main_menu_view.dart';

void main() {
  runApp(const MiniIPSCMatchApp());
}

class MiniIPSCMatchApp extends StatelessWidget {
  const MiniIPSCMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini IPSC Match',
      home: MainMenuView(),
    );
  }
}
