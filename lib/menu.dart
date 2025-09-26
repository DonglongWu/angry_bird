import 'package:flutter/material.dart';
import 'level_select.dart';
import 'slingshot.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Angry Birds Clone",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SlingshotGamePage(levelIndex: 1),
                  ),
                );
              },
              child: const Text("Start Game"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LevelSelectPage(),
                  ),
                );
              },
              child: const Text("Select Level"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                // 退出
                Navigator.pop(context);
              },
              child: const Text("Exit"),
            ),
          ],
        ),
      ),
    );
  }
}
