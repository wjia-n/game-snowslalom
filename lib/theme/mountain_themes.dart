import 'package:flutter/material.dart';

/// Mountain + skier art catalog for Snow Slalom.
///
/// Every theme stays inside a snowy-mountain physical-material world: real
/// snow with depth and shading, wooden gate poles, fabric flags, pines.
/// Variety comes from time of day, weather, and snow/sky palettes — never
/// neon, never cyberpunk.
class MountainThemeDef {
  final String id;
  final String name;
  final Color skyTop;
  final Color skyBottom;
  final Color peakFar; // distant mountain silhouettes
  final Color peakNear;
  final Color snowLight;
  final Color snowShadow;
  final Color groove; // track grooves carved in the snow
  final Color treeDark;
  final Color treeSnow;
  final Color gateRed;
  final Color gateBlue;
  final Color pole; // wooden gate poles
  final Color hud; // HUD panel
  final Color hudText;
  final Color accent; // UI accent (buttons, highlights)
  final Color accentDark;
  final bool night; // stars / moon mode

  const MountainThemeDef({
    required this.id,
    required this.name,
    required this.skyTop,
    required this.skyBottom,
    required this.peakFar,
    required this.peakNear,
    required this.snowLight,
    required this.snowShadow,
    required this.groove,
    required this.treeDark,
    required this.treeSnow,
    required this.gateRed,
    required this.gateBlue,
    required this.pole,
    required this.hud,
    required this.hudText,
    required this.accent,
    required this.accentDark,
    this.night = false,
  });
}

class MountainThemes {
  /// First 4 are the FREE starter mountains. The rest are PRO.
  static const List<String> freeThemeIds = [
    'powder',
    'dawn',
    'sunset',
    'storm',
  ];

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';

  static const List<MountainThemeDef> all = [
    MountainThemeDef(
      id: 'powder',
      name: 'Powder Day',
      skyTop: Color(0xFF7FB8E8),
      skyBottom: Color(0xFFDFF0FB),
      peakFar: Color(0xFF9CC3E5),
      peakNear: Color(0xFF6E9CCB),
      snowLight: Color(0xFFFFFFFF),
      snowShadow: Color(0xFFC9DCEE),
      groove: Color(0xFFD9E9F7),
      treeDark: Color(0xFF2E5D3A),
      treeSnow: Color(0xFFF2F8FC),
      gateRed: Color(0xFFD63A2F),
      gateBlue: Color(0xFF1F6FD6),
      pole: Color(0xFF7A5230),
      hud: Color(0xFF123A5E),
      hudText: Color(0xFFFFFFFF),
      accent: Color(0xFFD63A2F),
      accentDark: Color(0xFF8F241D),
    ),
    MountainThemeDef(
      id: 'dawn',
      name: 'Alpine Dawn',
      skyTop: Color(0xFF5E7FC4),
      skyBottom: Color(0xFFF6D9C4),
      peakFar: Color(0xFF8FA0D8),
      peakNear: Color(0xFF5F6FAE),
      snowLight: Color(0xFFFFF4EA),
      snowShadow: Color(0xFFE3CFC2),
      groove: Color(0xFFF0DCD2),
      treeDark: Color(0xFF3A5A44),
      treeSnow: Color(0xFFFFF7F0),
      gateRed: Color(0xFFC92F3B),
      gateBlue: Color(0xFF2743A8),
      pole: Color(0xFF6E4A2C),
      hud: Color(0xFF2B2A55),
      hudText: Color(0xFFFFFFFF),
      accent: Color(0xFFE88B3A),
      accentDark: Color(0xFFA85E1E),
    ),
    MountainThemeDef(
      id: 'sunset',
      name: 'Sunset Ridge',
      skyTop: Color(0xFF3D4E8F),
      skyBottom: Color(0xFFF2A56B),
      peakFar: Color(0xFF7A6A9E),
      peakNear: Color(0xFF52457A),
      snowLight: Color(0xFFFFEDE0),
      snowShadow: Color(0xFFD9B8AE),
      groove: Color(0xFFEFD3C4),
      treeDark: Color(0xFF2F4A38),
      treeSnow: Color(0xFFFFF0E2),
      gateRed: Color(0xFFE0442E),
      gateBlue: Color(0xFF1E5FBF),
      pole: Color(0xFF6E4A2C),
      hud: Color(0xFF35284E),
      hudText: Color(0xFFFFFFFF),
      accent: Color(0xFFF2A53B),
      accentDark: Color(0xFFA8641C),
    ),
    MountainThemeDef(
      id: 'storm',
      name: 'Storm Clouds',
      skyTop: Color(0xFF5A6B7E),
      skyBottom: Color(0xFFB9C6D2),
      peakFar: Color(0xFF8B99A8),
      peakNear: Color(0xFF5E6D7D),
      snowLight: Color(0xFFF4F7FA),
      snowShadow: Color(0xFFC2CDD6),
      groove: Color(0xFFDCE4EA),
      treeDark: Color(0xFF2A4434),
      treeSnow: Color(0xFFF6FAFD),
      gateRed: Color(0xFFC22F2A),
      gateBlue: Color(0xFF1C5FBE),
      pole: Color(0xFF5E4026),
      hud: Color(0xFF2E3A47),
      hudText: Color(0xFFFFFFFF),
      accent: Color(0xFF3FA7D6),
      accentDark: Color(0xFF23709A),
    ),
    MountainThemeDef(
      id: 'moonlit',
      name: 'Moonlit Run',
      skyTop: Color(0xFF0D1B33),
      skyBottom: Color(0xFF2C4A73),
      peakFar: Color(0xFF3B547E),
      peakNear: Color(0xFF243A5E),
      snowLight: Color(0xFFDCE8F5),
      snowShadow: Color(0xFF8FA6C4),
      groove: Color(0xFFB9CCE2),
      treeDark: Color(0xFF16302A),
      treeSnow: Color(0xFFE4EEF8),
      gateRed: Color(0xFFE05A4A),
      gateBlue: Color(0xFF4A9BE0),
      pole: Color(0xFF8A6240),
      hud: Color(0xFF0E1E36),
      hudText: Color(0xFFEAF3FC),
      accent: Color(0xFFF2D06B),
      accentDark: Color(0xFF9A7B28),
      night: true,
    ),
    MountainThemeDef(
      id: 'aurora',
      name: 'Northern Lights',
      skyTop: Color(0xFF0A2038),
      skyBottom: Color(0xFF1E5A5A),
      peakFar: Color(0xFF2E5A6E),
      peakNear: Color(0xFF1C3E52),
      snowLight: Color(0xFFE2F2EC),
      snowShadow: Color(0xFF9DC2B8),
      groove: Color(0xFFC2DDD4),
      treeDark: Color(0xFF14332C),
      treeSnow: Color(0xFFEDF7F2),
      gateRed: Color(0xFFE05A4A),
      gateBlue: Color(0xFF4AD6C0),
      pole: Color(0xFF8A6240),
      hud: Color(0xFF0B2231),
      hudText: Color(0xFFEAF7F2),
      accent: Color(0xFF58D6A8),
      accentDark: Color(0xFF2A8A66),
      night: true,
    ),
    MountainThemeDef(
      id: 'glacier',
      name: 'Glacier Ice',
      skyTop: Color(0xFF5FB8D6),
      skyBottom: Color(0xFFDFF6FB),
      peakFar: Color(0xFFA8D8E8),
      peakNear: Color(0xFF6FB8D2),
      snowLight: Color(0xFFF2FCFF),
      snowShadow: Color(0xFFBFE3EE),
      groove: Color(0xFFD9F0F6),
      treeDark: Color(0xFF2E6E7E),
      treeSnow: Color(0xFFF6FDFF),
      gateRed: Color(0xFFD63A2F),
      gateBlue: Color(0xFF0F8FD6),
      pole: Color(0xFF7A5230),
      hud: Color(0xFF0F4A5E),
      hudText: Color(0xFFFFFFFF),
      accent: Color(0xFF0F8FD6),
      accentDark: Color(0xFF0A5F8F),
    ),
    MountainThemeDef(
      id: 'spring',
      name: 'Spring Slush',
      skyTop: Color(0xFF6FB8F0),
      skyBottom: Color(0xFFF2E8C9),
      peakFar: Color(0xFFA9C98E),
      peakNear: Color(0xFF7BA468),
      snowLight: Color(0xFFFFFDF4),
      snowShadow: Color(0xFFE2DCC2),
      groove: Color(0xFFF0EAD2),
      treeDark: Color(0xFF3F6E3A),
      treeSnow: Color(0xFFFFFEF6),
      gateRed: Color(0xFFE0442E),
      gateBlue: Color(0xFF2E8FD6),
      pole: Color(0xFF7A5230),
      hud: Color(0xFF2E5E3A),
      hudText: Color(0xFFFFFFFF),
      accent: Color(0xFF7BC043),
      accentDark: Color(0xFF4E7E26),
    ),
    MountainThemeDef(
      id: 'blizzard',
      name: 'Whiteout Blizzard',
      skyTop: Color(0xFF9AA8B8),
      skyBottom: Color(0xFFE8EEF2),
      peakFar: Color(0xFFC2CDD6),
      peakNear: Color(0xFF93A1B0),
      snowLight: Color(0xFFFFFFFF),
      snowShadow: Color(0xFFD4DCE2),
      groove: Color(0xFFE8EEF2),
      treeDark: Color(0xFF4A5E66),
      treeSnow: Color(0xFFFFFFFF),
      gateRed: Color(0xFFB52A24),
      gateBlue: Color(0xFF174A9E),
      pole: Color(0xFF4E3822),
      hud: Color(0xFF3A4650),
      hudText: Color(0xFFFFFFFF),
      accent: Color(0xFFB52A24),
      accentDark: Color(0xFF7A1B17),
    ),
    MountainThemeDef(
      id: 'golden',
      name: 'Golden Hour',
      skyTop: Color(0xFF7A9BD6),
      skyBottom: Color(0xFFF7C873),
      peakFar: Color(0xFFB09AD0),
      peakNear: Color(0xFF7E6AA0),
      snowLight: Color(0xFFFFF6E4),
      snowShadow: Color(0xFFE8CFA4),
      groove: Color(0xFFF5E2C2),
      treeDark: Color(0xFF3F5534),
      treeSnow: Color(0xFFFFF8E8),
      gateRed: Color(0xFFD63A2F),
      gateBlue: Color(0xFF1F5FD6),
      pole: Color(0xFF7A5230),
      hud: Color(0xFF4A3A28),
      hudText: Color(0xFFFFFFFF),
      accent: Color(0xFFF2B53B),
      accentDark: Color(0xFFA8761C),
    ),
    MountainThemeDef(
      id: 'frostbite',
      name: 'Frostbite Blue',
      skyTop: Color(0xFF2E5A8E),
      skyBottom: Color(0xFFA8D4E8),
      peakFar: Color(0xFF7AA8C8),
      peakNear: Color(0xFF4E7EAA),
      snowLight: Color(0xFFEFF8FC),
      snowShadow: Color(0xFFAECFDE),
      groove: Color(0xFFD4E8F0),
      treeDark: Color(0xFF1E4E5E),
      treeSnow: Color(0xFFF2FAFD),
      gateRed: Color(0xFFE0442E),
      gateBlue: Color(0xFF0F6FD6),
      pole: Color(0xFF5E4026),
      hud: Color(0xFF123A5E),
      hudText: Color(0xFFFFFFFF),
      accent: Color(0xFF4AD6F0),
      accentDark: Color(0xFF1E8AA8),
    ),
    MountainThemeDef(
      id: 'candycane',
      name: 'Candy Cane Peak',
      skyTop: Color(0xFF8FB8E0),
      skyBottom: Color(0xFFF2DDE4),
      peakFar: Color(0xFFB89AC8),
      peakNear: Color(0xFF8A6EA0),
      snowLight: Color(0xFFFFF8FA),
      snowShadow: Color(0xFFEACFD8),
      groove: Color(0xFFF5E2E8),
      treeDark: Color(0xFF3E5E44),
      treeSnow: Color(0xFFFFF2F5),
      gateRed: Color(0xFFE0445A),
      gateBlue: Color(0xFF2E7FD6),
      pole: Color(0xFF8A4A3A),
      hud: Color(0xFF5E2E44),
      hudText: Color(0xFFFFFFFF),
      accent: Color(0xFFE0445A),
      accentDark: Color(0xFF96293C),
    ),
  ];

  static MountainThemeDef byId(String id, {MountainThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

/// Skier outfit styles. First 4 free, the rest PRO. Custom creator is PRO.
class SkierStyle {
  final String id;
  final String name;
  final Color suit; // jacket
  final Color pants;
  final Color helmet;
  final Color skis;

  const SkierStyle({
    required this.id,
    required this.name,
    required this.suit,
    required this.pants,
    required this.helmet,
    required this.skis,
  });
}

class SkierStyles {
  static const List<String> freeStyleIds = [
    'racer',
    'navy',
    'forest',
    'sunshine',
  ];

  static bool isProStyle(String id) =>
      !freeStyleIds.contains(id) && id != 'custom';

  static const List<SkierStyle> all = [
    SkierStyle(
      id: 'racer',
      name: 'Red Racer',
      suit: Color(0xFFD63A2F),
      pants: Color(0xFF8F241D),
      helmet: Color(0xFFD63A2F),
      skis: Color(0xFF2B2B33),
    ),
    SkierStyle(
      id: 'navy',
      name: 'Midnight Navy',
      suit: Color(0xFF1E3A6E),
      pants: Color(0xFF12264A),
      helmet: Color(0xFFF2F5FA),
      skis: Color(0xFF1E3A6E),
    ),
    SkierStyle(
      id: 'forest',
      name: 'Forest Green',
      suit: Color(0xFF2E7D4F),
      pants: Color(0xFF1C4E31),
      helmet: Color(0xFFF2F5FA),
      skis: Color(0xFF2B2B33),
    ),
    SkierStyle(
      id: 'sunshine',
      name: 'Sunshine Yellow',
      suit: Color(0xFFF2B53B),
      pants: Color(0xFF2B2B33),
      helmet: Color(0xFF2B2B33),
      skis: Color(0xFFF2B53B),
    ),
    SkierStyle(
      id: 'blaze',
      name: 'Blaze Orange',
      suit: Color(0xFFE8762E),
      pants: Color(0xFF2B2B33),
      helmet: Color(0xFFE8762E),
      skis: Color(0xFF2B2B33),
    ),
    SkierStyle(
      id: 'royal',
      name: 'Royal Purple',
      suit: Color(0xFF7B4FB5),
      pants: Color(0xFF4A2E73),
      helmet: Color(0xFFF2F5FA),
      skis: Color(0xFF4A2E73),
    ),
    SkierStyle(
      id: 'glacier',
      name: 'Glacier White',
      suit: Color(0xFFF2F7FA),
      pants: Color(0xFF4AD6F0),
      helmet: Color(0xFF4AD6F0),
      skis: Color(0xFF2B2B33),
    ),
    SkierStyle(
      id: 'bubblegum',
      name: 'Bubblegum Pink',
      suit: Color(0xFFE86A9A),
      pants: Color(0xFF2B2B33),
      helmet: Color(0xFFE86A9A),
      skis: Color(0xFFF2F5FA),
    ),
    SkierStyle(
      id: 'carbon',
      name: 'Carbon Black',
      suit: Color(0xFF2B2B33),
      pants: Color(0xFF14141A),
      helmet: Color(0xFFD63A2F),
      skis: Color(0xFFD63A2F),
    ),
    SkierStyle(
      id: 'retro',
      name: 'Retro 80s',
      suit: Color(0xFF2E7FD6),
      pants: Color(0xFFE0445A),
      helmet: Color(0xFFF2B53B),
      skis: Color(0xFFF2F5FA),
    ),
  ];

  static SkierStyle byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return all.first;
  }
}

/// Difficulty tiers: speed + gate complexity scale together (RULES.md §3).
class SlalomDifficulty {
  final String id;
  final String name;
  final String tagline;
  final double speed; // world units per second
  final int gates;
  final double wander; // how far gates wander from center
  final double gateGap; // vertical spacing between gates
  final int trees;

  const SlalomDifficulty({
    required this.id,
    required this.name,
    required this.tagline,
    required this.speed,
    required this.gates,
    required this.wander,
    required this.gateGap,
    required this.trees,
  });

  static const List<SlalomDifficulty> all = [
    SlalomDifficulty(
      id: 'bunny',
      name: 'Bunny Slope',
      tagline: 'Gentle gates, easy cruising',
      speed: 0.34,
      gates: 14,
      wander: 0.45,
      gateGap: 0.62,
      trees: 8,
    ),
    SlalomDifficulty(
      id: 'blue',
      name: 'Blue Run',
      tagline: 'Faster, trickier gates',
      speed: 0.46,
      gates: 18,
      wander: 0.65,
      gateGap: 0.55,
      trees: 12,
    ),
    SlalomDifficulty(
      id: 'diamond',
      name: 'Black Diamond',
      tagline: 'Blazing speed, brutal gates',
      speed: 0.60,
      gates: 24,
      wander: 0.85,
      gateGap: 0.48,
      trees: 16,
    ),
  ];

  /// Black Diamond is a Pro feature.
  static bool isProDifficulty(int index) => index >= 2;
}

/// Race modes (RULES.md §2).
class SlalomMode {
  final String id;
  final String name;
  final String tagline;
  final String howScored;

  const SlalomMode({
    required this.id,
    required this.name,
    required this.tagline,
    required this.howScored,
  });

  static const List<SlalomMode> all = [
    SlalomMode(
      id: 'timetrial',
      name: 'Time Trial',
      tagline: '3 runs — lowest total time wins',
      howScored: 'Sum of 3 run times. Missed gate: +5s.',
    ),
    SlalomMode(
      id: 'scoreattack',
      name: 'Score Attack',
      tagline: '1 run — rack up style points',
      howScored: '100 pts per gate × streak bonus. Miss: −50.',
    ),
    SlalomMode(
      id: 'passplay',
      name: 'Pass & Play',
      tagline: '2–4 skiers, one phone, best time wins',
      howScored: 'Each skier runs once. Lowest time wins.',
    ),
  ];

  /// Score Attack is a Pro feature.
  static bool isProMode(String id) => id == 'scoreattack';
}
