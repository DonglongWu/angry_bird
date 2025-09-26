import 'package:flutter/material.dart';
import 'menu.dart';

void main() {
  runApp(const AngryBirdApp());
}

class AngryBirdApp extends StatelessWidget {
  const AngryBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Angry Birds Clone',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const MenuPage(), // 先进入主菜单
    );
  }
}
