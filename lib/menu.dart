import 'package:flutter/material.dart';
import 'slingshot.dart';     // 如果你的 SlingshotGamePage 不在这里，请改成实际文件
import 'level_select.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1114), // 深色背景，和游戏画面统一
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_esports, size: 72, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    'Angry Birds (Demo)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Physics Puzzle Prototype',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  _MenuButton(
                    label: 'Start',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SlingshotGamePage(levelIndex: 1),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _MenuButton(
                    label: 'Level Select',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LevelSelectPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _MenuButton(
                    label: 'Settings (coming soon)',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings is not implemented yet')),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('v0.1 – Level 1 only', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _MenuButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF263238),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
