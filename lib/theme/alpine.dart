import 'package:flutter/material.dart';
import 'mountain_themes.dart';

/// Shared Alpine visual language: chunky physical-material widgets,
/// bold readable type, frosty depth. No neon, no AI-dashboard looks.
class Alpine {
  static TextStyle display(double size, {required MountainThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: theme.hudText,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      );

  static TextStyle title(double size, {required MountainThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: theme.hudText,
      );

  static TextStyle body(double size,
          {required MountainThemeDef theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme.hudText,
      );

  static TextStyle label(double size,
          {required MountainThemeDef theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: color ?? theme.hudText.withValues(alpha: 0.85),
      );

  /// Chunky beveled physical button.
  static Widget button({
    required MountainThemeDef theme,
    required String label,
    String? emoji,
    bool primary = false,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    final base = primary ? theme.accent : theme.hud;
    final edge = primary ? theme.accentDark : Colors.black.withValues(alpha: 0.45);
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: edge, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                offset: const Offset(0, 5),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                offset: const Offset(0, 2),
                blurRadius: 0,
                spreadRadius: -1,
              ),
            ],
          ),
          child: Text(
            '${emoji != null ? '$emoji ' : ''}$label',
            style: TextStyle(
              color: primary ? Colors.white : theme.hudText,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  /// Frosted glass panel with wooden edge — HUD cards, dialogs.
  static Widget panel({
    required MountainThemeDef theme,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.hud.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.hudText.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Full-screen mountain backdrop used behind menus (static, painterly).
class AlpineBackdrop extends StatelessWidget {
  final MountainThemeDef theme;
  final Widget child;
  const AlpineBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.skyTop, theme.skyBottom, theme.snowLight],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: child,
    );
  }
}
