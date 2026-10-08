import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const SnowSlalomApp());

class SnowSlalomApp extends StatelessWidget {
  const SnowSlalomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.playfulPop,
      title: 'Snow Slalom',
      tagline: 'Carve through slalom gates down the mountain',
      emoji: '⛷️',
      slug: 'snowslalom',
      howToPlay:
          '• 3 runs down the mountain. Thread every gate!\n• Drag left/right to steer. Drag UP to tuck for speed, DOWN to brake.\n• Missing a gate costs +5 seconds.\n• Lowest total time wins. Beat your best!',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => SnowSlalomScreen(players: players, callbacks: cb),
    );
  }
}
