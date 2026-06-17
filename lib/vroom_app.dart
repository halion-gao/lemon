import 'package:flutter/material.dart';
import 'screens/main_menu_page.dart';

class VroomApp extends StatelessWidget {
  const VroomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vroom 管理系統',
      home: MainMenuPage(),
    );
  }
}