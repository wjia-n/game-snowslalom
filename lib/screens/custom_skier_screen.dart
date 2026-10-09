import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/alpine.dart';
import '../theme/mountain_themes.dart';

/// Custom skier creator (PRO): pick suit / pants / helmet / ski colors.
/// Preview updates live, everything persists.
class CustomSkierScreen extends StatelessWidget {
  final SlalomAudio audio;
  final SlalomSettings settings;

  const CustomSkierScreen(
      {super.key, required this.audio, required this.settings});

  static const _swatches = [
    0xFFD63A2F, 0xFFE8762E, 0xFFF2B53B, 0xFF7BC043, 0xFF2E7D4F,
    0xFF4AD6F0, 0xFF2E7FD6, 0xFF1E3A6E, 0xFF7B4FB5, 0xFFE86A9A,
    0xFFF2F7FA, 0xFF8A8A96, 0xFF2B2B33, 0xFF14141A,
  ];

  static const _parts = [
    ('suit', 'Jacket 🧥'),
    ('pants', 'Pants 👖'),
    ('helmet', 'Helmet 🪖'),
    ('skis', 'Skis 🎿'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) {
        final t = settings.theme;
        final custom = settings.customSkierStyle;
        final active = settings.skierStyleId == 'custom';
        return AlpineBackdrop(
          theme: t,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded,
                    color: t.hudText),
                onPressed: () {
                  audio.click();
                  Navigator.of(context).pop();
                },
              ),
              title: Text('Custom Skier',
                  style: Alpine.display(22, theme: t)),
              centerTitle: true,
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(child: _preview(t, custom)),
                  const SizedBox(height: 8),
                  Center(
                    child: Alpine.button(
                      theme: t,
                      label: active ? 'Using My Creation ✓' : 'Use My Creation',
                      emoji: '🎨',
                      primary: !active,
                      onTap: () {
                        audio.click();
                        settings.setSkierStyle('custom');
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final part in _parts)
                    Alpine.panel(
                      theme: t,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(part.$2.toUpperCase(),
                              style:
                                  Alpine.label(12, theme: t)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _swatches.map((hex) {
                              final selected =
                                  settings.customSkier[part.$1] ==
                                      hex;
                              return GestureDetector(
                                onTap: () {
                                  audio.click();
                                  settings.setCustomSkierColor(
                                      part.$1, hex);
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(hex),
                                    border: Border.all(
                                      color: selected
                                          ? t.accent
                                          : Colors.white
                                              .withValues(
                                                  alpha: 0.4),
                                      width:
                                          selected ? 4 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(
                                                alpha: 0.3),
                                        offset:
                                            const Offset(0, 3),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        audio.click();
                        settings.resetCustomSkier();
                      },
                      child: Text('Reset colors',
                          style: Alpine.body(14, theme: t,
                              color: t.accent)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _preview(MountainThemeDef t, SkierStyle s) {
    return Container(
      width: 150,
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.skyTop, t.skyBottom],
        ),
        border: Border.all(
            color: t.hudText.withValues(alpha: 0.3), width: 2),
      ),
      child: CustomPaint(
        painter: _SkierPreviewPainter(style: s),
      ),
    );
  }
}

class _SkierPreviewPainter extends CustomPainter {
  final SkierStyle style;
  _SkierPreviewPainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final s = 1.5;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + 6, cy + 30 * s),
          width: 70 * s,
          height: 14 * s),
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );
    final suit = Paint()..color = style.suit;
    final pants = Paint()..color = style.pants;
    final helmet = Paint()..color = style.helmet;
    final skiPaint = Paint()..color = style.skis;
    for (final off in [-10.0, 10.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx + off * s, cy + 28 * s),
                width: 8 * s,
                height: 62 * s),
            Radius.circular(4 * s)),
        skiPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx - 8 * s, cy + 4 * s),
              width: 13 * s,
              height: 28 * s),
          Radius.circular(6 * s)),
      pants,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx + 8 * s, cy + 4 * s),
              width: 13 * s,
              height: 28 * s),
          Radius.circular(6 * s)),
      pants,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, cy - 20 * s),
              width: 28 * s,
              height: 34 * s),
          Radius.circular(12 * s)),
      suit,
    );
    canvas.drawCircle(
        Offset(cx, cy - 46 * s), 12 * s, Paint()..color = const Color(0xFFF2C9A0));
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy - 48 * s), radius: 13 * s),
        3.14,
        3.14,
        false,
        helmet
          ..strokeWidth = 10 * s
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _SkierPreviewPainter old) =>
      old.style != style;
}
