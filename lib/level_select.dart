import 'package:flutter/material.dart';
import 'slingshot.dart';

class LevelSelectPage extends StatelessWidget {
  const LevelSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Level")),
      body: ListView.builder(
        itemCount: 3, // 先假设有 3 关
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("Level ${index + 1}"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SlingshotGamePage(levelIndex: index + 1),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
