import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/mountain_themes.dart';

/// Persisted settings + stats for Snow Slalom. Survives app restarts.
///
/// Stores: audio toggles, renameable player profile(s), theme / skier-style
/// choices (incl. custom skier colors), mode + difficulty setup, Pro unlock
/// state, and lifetime bests.
///
/// Player names are stored as ONE JSON string
/// ('snowslalom_player_names_json'). Android's SharedPreferences stores
/// StringLists as an unordered StringSet, so a StringList would scramble
/// name order on every restart. NEVER use setStringList here.
class SlalomSettings extends ChangeNotifier {
  static const _kMusic = 'snowslalom_music_on';
  static const _kSfx = 'snowslalom_sfx_on';
  static const _kVolume = 'snowslalom_volume';
  static const _kMode = 'snowslalom_mode';
  static const _kDifficulty = 'snowslalom_difficulty';
  static const _kRunners = 'snowslalom_runners';
  static const _kNames = 'snowslalom_player_names'; // legacy unordered key
  static const _kNamesJson = 'snowslalom_player_names_json'; // order-safe
  static const _kTheme = 'snowslalom_theme_id';
  static const _kSkier = 'snowslalom_skier_id';
  static const _kSkierPrefix = 'snowslalom_custom_skier_';
  static const _kBestTime = 'snowslalom_best_time_'; // per difficulty id
  static const _kBestScore = 'snowslalom_best_score_'; // per difficulty id
  static const _kWins = 'snowslalom_wins';
  static const _kGames = 'snowslalom_games_played';
  static const _kIsPro = 'snowslalom_is_pro';

  static const defaultNames = ['Skier 1', 'Skier 2', 'Skier 3', 'Skier 4'];

  /// Encode the 4 runner names as one JSON string (order-preserving).
  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  /// Decode persisted names; falls back to defaults on missing/corrupt data.
  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == 4) {
        return [for (int i = 0; i < 4; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String mode = 'timetrial';
  int difficulty = 0; // 0 bunny, 1 blue, 2 black diamond (Pro)
  int runners = 2; // pass & play runner count
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'powder';
  String skierStyleId = 'racer';
  bool isPro = true; // everything unlocked — no Pro version
  int wins = 0;
  int gamesPlayed = 0;

  /// Best Time-Trial totals per difficulty id (0 = none yet).
  final Map<String, double> bestTimes = {};
  /// Best Score-Attack scores per difficulty id (0 = none yet).
  final Map<String, int> bestScores = {};

  /// Custom skier colors (ARGB ints). Defaults mirror Red Racer.
  Map<String, int> customSkier = Map.of(_defaultCustomSkier);

  static const Map<String, int> _defaultCustomSkier = {
    'suit': 0xFFD63A2F,
    'pants': 0xFF8F241D,
    'helmet': 0xFFD63A2F,
    'skis': 0xFF2B2B33,
  };

  SkierStyle get customSkierStyle => SkierStyle(
        id: 'custom',
        name: 'My Creation',
        suit: Color(customSkier['suit']!),
        pants: Color(customSkier['pants']!),
        helmet: Color(customSkier['helmet']!),
        skis: Color(customSkier['skis']!),
      );

  SlalomDifficulty get diff => SlalomDifficulty.all[difficulty.clamp(0, 2)];

  SharedPreferences? _prefs;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _prefs = p;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    mode = p.getString(_kMode) ?? 'timetrial';
    if (!SlalomMode.all.any((m) => m.id == mode)) mode = 'timetrial';
    difficulty = (p.getInt(_kDifficulty) ?? 0).clamp(0, 2);
    runners = (p.getInt(_kRunners) ?? 2).clamp(2, 4);
    // Prefer the order-safe JSON key; fall back to the legacy StringList
    // key once (one-time migration — it may already be scrambled).
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kNames);
      playerNames = (legacy != null && legacy.length == 4)
          ? [for (int i = 0; i < 4; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    themeId = p.getString(_kTheme) ?? 'powder';
    skierStyleId = p.getString(_kSkier) ?? 'racer';
    isPro = true; // everything unlocked
    wins = p.getInt(_kWins) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    for (final d in SlalomDifficulty.all) {
      bestTimes[d.id] = p.getDouble('$_kBestTime${d.id}') ?? 0;
      bestScores[d.id] = p.getInt('$_kBestScore${d.id}') ?? 0;
    }
    for (final k in _defaultCustomSkier.keys) {
      customSkier[k] = p.getInt('$_kSkierPrefix$k') ?? _defaultCustomSkier[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kMode, mode);
    await p.setInt(_kDifficulty, difficulty);
    await p.setInt(_kRunners, runners);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNames); // drop the legacy unordered key for good
    await p.setString(_kTheme, themeId);
    await p.setString(_kSkier, skierStyleId);
    await p.setBool(_kIsPro, isPro);
    await p.setInt(_kWins, wins);
    await p.setInt(_kGames, gamesPlayed);
    for (final d in SlalomDifficulty.all) {
      final t = bestTimes[d.id] ?? 0;
      if (t > 0) await p.setDouble('$_kBestTime${d.id}', t);
      final s = bestScores[d.id] ?? 0;
      if (s > 0) await p.setInt('$_kBestScore${d.id}', s);
    }
    for (final e in customSkier.entries) {
      await p.setInt('$_kSkierPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp Pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || MountainThemes.isProTheme(themeId)) {
      themeId = 'powder';
      changed = true;
    }
    if (skierStyleId == 'custom' || SkierStyles.isProStyle(skierStyleId)) {
      skierStyleId = 'racer';
      changed = true;
    }
    if (SlalomDifficulty.isProDifficulty(difficulty)) {
      difficulty = 1;
      changed = true;
    }
    if (SlalomMode.isProMode(mode)) {
      mode = 'timetrial';
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomSkierColor(String key, int argb) async {
    if (!isPro) return; // custom skier creator is a Pro feature
    if (!_defaultCustomSkier.containsKey(key)) return;
    customSkier[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomSkier() async {
    customSkier = Map.of(_defaultCustomSkier);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  /// Clear lifetime stats + bests (Pro state is kept).
  Future<void> resetStats() async {
    wins = 0;
    gamesPlayed = 0;
    bestTimes.clear();
    bestScores.clear();
    final p = _prefs;
    if (p != null) {
      for (final d in SlalomDifficulty.all) {
        await p.remove('$_kBestTime${d.id}');
        await p.remove('$_kBestScore${d.id}');
      }
    }
    notifyListeners();
    await _save();
  }

  Future<void> setMode(String id) async {
    if (!SlalomMode.all.any((m) => m.id == id)) return;
    if (!isPro && SlalomMode.isProMode(id)) return;
    mode = id;
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int i) async {
    i = i.clamp(0, 2);
    if (!isPro && SlalomDifficulty.isProDifficulty(i)) return;
    difficulty = i;
    notifyListeners();
    await _save();
  }

  Future<void> setRunners(int n) async {
    runners = n.clamp(2, 4);
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index > 3) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || MountainThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setSkierStyle(String id) async {
    if (!isPro && (id == 'custom' || SkierStyles.isProStyle(id))) return;
    skierStyleId = id;
    notifyListeners();
    await _save();
  }

  SkierStyle get skierStyle => skierStyleId == 'custom'
      ? customSkierStyle
      : SkierStyles.byId(skierStyleId);

  MountainThemeDef get theme =>
      MountainThemes.byId(themeId, custom: _customTheme);

  /// Custom mountain theme is not offered for this game; custom slot is
  /// the skier creator. Keep a null-safe fallback.
  MountainThemeDef? get _customTheme => null;

  /// Record a finished Time-Trial / Pass&Play race. Returns true on new best.
  Future<bool> recordTime(String difficultyId, double total) async {
    gamesPlayed++;
    final prev = bestTimes[difficultyId] ?? 0;
    final isBest = prev == 0 || total < prev;
    if (isBest) bestTimes[difficultyId] = total;
    notifyListeners();
    await _save();
    return isBest;
  }

  /// Record a finished Score-Attack run. Returns true on new best.
  Future<bool> recordScore(String difficultyId, int score) async {
    gamesPlayed++;
    final prev = bestScores[difficultyId] ?? 0;
    final isBest = score > prev;
    if (isBest) bestScores[difficultyId] = score;
    notifyListeners();
    await _save();
    return isBest;
  }

  Future<void> recordWin() async {
    wins++;
    notifyListeners();
    await _save();
  }
}
