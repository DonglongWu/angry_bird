import 'package:flutter/material.dart';
import 'menu.dart';

void main() => runApp(const AngryBirdApp());

class AngryBirdApp extends StatelessWidget {
  const AngryBirdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111318),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
      ),
      home: const MenuPage(),
    );
  }
}
