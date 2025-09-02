import 'package:flutter/material.dart';
import 'slingshot.dart';

class LevelSelectPage extends StatelessWidget {
  const LevelSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Level Select')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LevelTile(
            index: 1,
            title: 'Level 1 – Hut',
            subtitle: 'Basic physics, pigs inside',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SlingshotGamePage(levelIndex: 1),
              ));
            },
          ),
          _LevelTile(index: 2, title: 'Level 2 (Locked)', subtitle: 'Coming soon', locked: true, onTap: () {}),
          _LevelTile(index: 3, title: 'Level 3 (Locked)', subtitle: 'Coming soon', locked: true, onTap: () {}),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;
  final bool locked;
  final VoidCallback onTap;

  const _LevelTile({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text('$index')),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: locked ? const Icon(Icons.lock) : const Icon(Icons.play_arrow),
        enabled: !locked,
        onTap: locked ? null : onTap,
      ),
    );
  }
}
