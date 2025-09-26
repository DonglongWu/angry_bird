import 'world.dart';
import 'level_builder.dart';
import 'pig.dart';
import 'bird.dart';
import 'menu.dart';
import 'package:flutter/material.dart';

class Cleanup {
  static void check(AngryWorld world, int currentLevel, BuildContext context) {
    final pigsAlive = world.children.whereType<Pig>().any((p) => !p.dead);
    final birdsAlive = world.children.whereType<Bird>().any((b) => b.alive);

    if (!pigsAlive) {
      // All pigs defeated → move to next level
      int nextLevel = currentLevel + 1;
      try {
        world.resetWorld();
        LevelBuilder.loadLevel(world, nextLevel);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Level $currentLevel cleared! Moving to Level $nextLevel")),
        );
      } catch (_) {
        // No more levels → back to main menu
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MenuPage()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Congratulations! You have completed all levels!")),
        );
      }
    } else if (!birdsAlive) {
      // No birds left but pigs still alive → game over
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Game Over! Try again.")),
      );

      world.resetWorld();
      LevelBuilder.loadLevel(world, currentLevel);
    }
  }
}
