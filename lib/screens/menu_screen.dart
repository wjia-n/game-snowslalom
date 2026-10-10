import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/slalom_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/alpine.dart';
import '../theme/mountain_themes.dart';
import 'custom_skier_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu: logo, PLAY, mode + difficulty setup, mountain theme picker,
/// skier picker, renameable profile, PRO, settings, share.
class MenuScreen extends StatefulWidget {
  final SlalomAudio audio;
  final SlalomSettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final StoreService _store = StoreService();

  SlalomSettings get _s => widget.settings;
  MountainThemeDef get _t => _s.theme;

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Alpine.body(15, theme: _t)),
        backgroundColor: _t.hud,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  
  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    super.dispose();
  }

  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {}
  }

  void _share() {
    widget.audio.click();
    Share.share(
      'Snow Slalom ⛷️ — carve through the gates and chase the best time! '
      'https://play.google.com/store/apps/details?id=com.gameswajiha.snowslalom',
    );
  }

  void _play() {
    widget.audio.gameStart();
    final names = _s.mode == 'passplay'
        ? [for (var i = 0; i < _s.runners; i++) _s.playerNames[i]]
        : [_s.playerNames[0]];
    final engine = SlalomEngine(
      diff: _s.diff,
      modeId: _s.mode,
      runnerNames: names,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SlalomGameScreen(
          audio: widget.audio,
          settings: _s,
          engine: engine,
        ),
      ),
    );
  }

  void _openPro() {
    widget.audio.click();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => ProScreen(
              audio: widget.audio,
              settings: _s,
              store: _store,
            ),
          ),
        )
        .then((_) => setState(() {}));
  }

  void _openSettings() {
    widget.audio.click();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => SettingsScreen(
              audio: widget.audio,
              settings: _s,
            ),
          ),
        )
        .then((_) => setState(() {}));
  }

  void _openCustomSkier() {
    widget.audio.click();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => CustomSkierScreen(
              audio: widget.audio,
              settings: _s,
            ),
          ),
        )
        .then((_) => setState(() {}));
  }

  void _rename(int index) {
    widget.audio.click();
    final ctrl = TextEditingController(text: _s.playerNames[index]);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Alpine.panel(
          theme: _t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Skier name',
                  style: Alpine.display(22, theme: _t)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLength: 14,
                style: Alpine.body(17, theme: _t),
                // Save on EVERY keystroke (JSON order-safe key); the Save
                // button below commits the final value on focus loss.
                onChanged: (v) => _s.setPlayerName(index, v),
                decoration: InputDecoration(
                  filled: true,
                  fillColor:
                      Colors.black.withValues(alpha: 0.25),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: Alpine.label(10, theme: _t),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                children: [
                  Alpine.button(
                    theme: _t,
                    label: 'Cancel',
                    onTap: () {
                      widget.audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                  Alpine.button(
                    theme: _t,
                    label: 'Save',
                    primary: true,
                    onTap: () {
                      widget.audio.click();
                      // Commit the final value (already persisted on every
                      // keystroke above) and close.
                      _s.setPlayerName(index, ctrl.text);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (_, _) {
        final t = _t;
        return Scaffold(
          body: AlpineBackdrop(
            theme: t,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(t),
                    const SizedBox(height: 14),
                    _modeCard(t),
                    const SizedBox(height: 12),
                    _difficultyCard(t),
                    if (_s.mode == 'passplay') ...[
                      const SizedBox(height: 12),
                      _runnersCard(t),
                    ],
                    const SizedBox(height: 12),
                    _themeCard(t),
                    const SizedBox(height: 12),
                    _skierCard(t),
                    const SizedBox(height: 18),
                    Center(
                      child: Alpine.button(
                        theme: t,
                        label: 'HIT THE SLOPES',
                        emoji: '⛷️',
                        primary: true,
                        onTap: _play,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _bestCard(t),
                    const SizedBox(height: 14),
                    _footerRow(t),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(MountainThemeDef t) {
    return Row(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.accent, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 5),
                blurRadius: 12,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child:
              Image.asset('assets/snowslalom_logo.png', fit: BoxFit.cover),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SNOW SLALOM',
                  style: Alpine.display(30, theme: t)),
              Text('Carve the mountain',
                  style: Alpine.label(12, theme: t)),
            ],
          ),
        ),
        if (!_s.isPro)
          GestureDetector(
            onTap: _openPro,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: t.accent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.accentDark, width: 2),
              ),
              child: const Text('PRO ⭐',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900)),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: t.hud.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: t.hudText.withValues(alpha: 0.4)),
            ),
            child: Text('PRO ✓',
                style: Alpine.label(13, theme: t)),
          ),
      ],
    );
  }

  Widget _sectionTitle(MountainThemeDef t, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Alpine.label(13, theme: t)),
      );

  Widget _modeCard(MountainThemeDef t) {
    return Alpine.panel(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(t, 'RACE MODE'),
          ...SlalomMode.all.map((m) {
            final locked = !_s.isPro && SlalomMode.isProMode(m.id);
            final selected = _s.mode == m.id;
            return _optionRow(
              t,
              title: '${m.name}${locked ? ' 🔒' : ''}',
              subtitle: '${m.tagline}\n${m.howScored}',
              selected: selected,
              onTap: () {
                if (locked) {
                  _openPro();
                  return;
                }
                widget.audio.click();
                _s.setMode(m.id);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _difficultyCard(MountainThemeDef t) {
    return Alpine.panel(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(t, 'DIFFICULTY'),
          Row(
            children: [
              for (var i = 0; i < SlalomDifficulty.all.length; i++)
                Expanded(child: _diffChip(t, i)),
            ],
          ),
          const SizedBox(height: 6),
          Text(_s.diff.tagline,
              style: Alpine.body(12, theme: t,
                  color: t.hudText.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _diffChip(MountainThemeDef t, int i) {
    final d = SlalomDifficulty.all[i];
    final locked = !_s.isPro && SlalomDifficulty.isProDifficulty(i);
    final selected = _s.difficulty == i;
    return GestureDetector(
      onTap: () {
        if (locked) {
          _openPro();
          return;
        }
        widget.audio.click();
        _s.setDifficulty(i);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? t.accent : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? t.accentDark
                : t.hudText.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(['🟢', '🔵', '⚫'][i],
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(d.name,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : t.hudText,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center),
            if (locked)
              const Text('🔒',
                  style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _runnersCard(MountainThemeDef t) {
    return Alpine.panel(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(t, 'SKIERS (PASS & PLAY)'),
          Row(
            children: [
              for (var n = 2; n <= 4; n++)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.audio.click();
                      _s.setRunners(n);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _s.runners == n
                            ? t.accent
                            : Colors.black
                                .withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _s.runners == n
                              ? t.accentDark
                              : t.hudText.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Text('$n',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _s.runners == n
                                ? Colors.white
                                : t.hudText,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          )),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _s.runners; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Skier ${i + 1}: ${_s.playerNames[i]}',
                        style: Alpine.body(15, theme: t),
                        overflow: TextOverflow.ellipsis),
                  ),
                  TextButton(
                    onPressed: () => _rename(i),
                    child: Text('✏️ Rename',
                        style: Alpine.body(13, theme: t,
                            color: t.accent)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _themeCard(MountainThemeDef t) {
    return Alpine.panel(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MOUNTAIN', style: Alpine.label(13, theme: t)),
              Text(t.name, style: Alpine.body(13, theme: t)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: MountainThemes.all.map((m) {
                final locked =
                    !_s.isPro && MountainThemes.isProTheme(m.id);
                final selected = _s.themeId == m.id;
                return GestureDetector(
                  onTap: () {
                    if (locked) {
                      _openPro();
                      return;
                    }
                    widget.audio.click();
                    _s.setTheme(m.id);
                  },
                  child: Container(
                    width: 84,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? t.accent
                            : t.hudText
                                .withValues(alpha: 0.25),
                        width: selected ? 3 : 1.5,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          m.skyTop,
                          m.skyBottom,
                          m.snowLight
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text('🏔️',
                              style: TextStyle(
                                  fontSize: 30,
                                  color: Colors.white.withValues(
                                      alpha: locked ? 0.4 : 1))),
                        ),
                        if (locked)
                          const Positioned(
                            right: 6,
                            top: 6,
                            child: Text('🔒',
                                style: TextStyle(fontSize: 14)),
                          ),
                        Positioned(
                          bottom: 4,
                          left: 0,
                          right: 0,
                          child: Text(m.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skierCard(MountainThemeDef t) {
    final customLocked = !_s.isPro;
    return Alpine.panel(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SKIER STYLE', style: Alpine.label(13, theme: t)),
              TextButton(
                onPressed:
                    customLocked ? _openPro : _openCustomSkier,
                child: Text(
                    customLocked
                        ? '🎨 Custom 🔒'
                        : '🎨 ${_s.skierStyleId == 'custom' ? 'My Creation ✓' : 'Custom creator'}',
                    style: Alpine.body(13, theme: t,
                        color: t.accent)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: SkierStyles.all.map((s) {
                final locked =
                    !_s.isPro && SkierStyles.isProStyle(s.id);
                final selected = _s.skierStyleId == s.id;
                return GestureDetector(
                  onTap: () {
                    if (locked) {
                      _openPro();
                      return;
                    }
                    widget.audio.click();
                    _s.setSkierStyle(s.id);
                  },
                  child: Container(
                    width: 76,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? t.accent
                            : t.hudText
                                .withValues(alpha: 0.25),
                        width: selected ? 3 : 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                            child: _skierDot(s,
                                dim: locked)),
                        if (locked)
                          const Positioned(
                            right: 5,
                            top: 5,
                            child: Text('🔒',
                                style: TextStyle(fontSize: 13)),
                          ),
                        Positioned(
                          bottom: 4,
                          left: 0,
                          right: 0,
                          child: Text(s.name,
                              textAlign: TextAlign.center,
                              style: Alpine.body(9, theme: t),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('Skier: ${_s.playerNames[0]}',
                    style: Alpine.body(15, theme: t),
                    overflow: TextOverflow.ellipsis),
              ),
              TextButton(
                onPressed: () => _rename(0),
                child: Text('✏️ Rename',
                    style:
                        Alpine.body(13, theme: t, color: t.accent)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skierDot(SkierStyle s, {bool dim = false}) {
    final o = dim ? 0.45 : 1.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: s.helmet.withValues(alpha: o),
            border: Border.all(
                color: Colors.white.withValues(alpha: o),
                width: 2),
          ),
        ),
        Container(
          width: 30,
          height: 22,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: s.suit.withValues(alpha: o),
          ),
        ),
        Container(
          width: 34,
          height: 5,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: s.skis.withValues(alpha: o),
          ),
        ),
      ],
    );
  }

  Widget _bestCard(MountainThemeDef t) {
    final bestT = _s.bestTimes[_s.diff.id] ?? 0;
    final bestS = _s.bestScores[_s.diff.id] ?? 0;
    return Alpine.panel(
      theme: t,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bestCell(t, '🏆', 'Best time',
              bestT == 0 ? '–' : '${bestT.toStringAsFixed(1)}s'),
          _bestCell(t, '⭐', 'Best score',
              bestS == 0 ? '–' : '$bestS pts'),
          _bestCell(t, '🎿', 'Races', '${_s.gamesPlayed}'),
        ],
      ),
    );
  }

  Widget _bestCell(
      MountainThemeDef t, String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        Text(label, style: Alpine.label(10, theme: t)),
        Text(value, style: Alpine.title(16, theme: t)),
      ],
    );
  }

  Widget _footerRow(MountainThemeDef t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _iconBtn(t, Icons.settings_rounded, 'Settings', _openSettings),
        const SizedBox(width: 18),
        _iconBtn(t, Icons.share_rounded, 'Share', _share),
        const SizedBox(width: 18),
        _iconBtn(t, Icons.star_rounded, 'Rate', () {
          widget.audio.click();
          _requestReview();
        }),
      ],
    );
  }

  Widget _iconBtn(MountainThemeDef t, IconData icon, String label,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.hud.withValues(alpha: 0.9),
              border: Border.all(
                  color: t.hudText.withValues(alpha: 0.35),
                  width: 2),
            ),
            child: Icon(icon, color: t.hudText, size: 26),
          ),
          const SizedBox(height: 4),
          Text(label, style: Alpine.label(10, theme: t)),
        ],
      ),
    );
  }

  Widget _optionRow(
    MountainThemeDef t, {
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? t.accent.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? t.accentDark
                : t.hudText.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : t.hudText,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      )),
                  Text(subtitle,
                      style: TextStyle(
                        color: (selected
                                ? Colors.white
                                : t.hudText)
                            .withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white),
          ],
        ),
      ),
    );
  }
}
