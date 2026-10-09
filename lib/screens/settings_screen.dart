import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/alpine.dart';
import '../theme/mountain_themes.dart';

/// Settings: audio toggles + volume, skier renaming, stats reset.
class SettingsScreen extends StatelessWidget {
  final SlalomAudio audio;
  final SlalomSettings settings;

  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (_, _) {
        final t = settings.theme;
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
              title: Text('Settings',
                  style: Alpine.display(22, theme: t)),
              centerTitle: true,
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Alpine.panel(
                    theme: t,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('AUDIO',
                            style: Alpine.label(13, theme: t)),
                        const SizedBox(height: 8),
                        _switchRow(t, '🎵 Music', settings.musicOn,
                            (v) {
                          audio.click();
                          settings.setMusic(v);
                          audio.configure(
                              musicOn: v,
                              sfxOn: settings.sfxOn,
                              volume: settings.volume);
                          if (v) {
                            audio.startMenuMusic();
                          }
                        }),
                        _switchRow(t, '🔊 Sound effects',
                            settings.sfxOn, (v) {
                          settings.setSfx(v);
                          audio.configure(
                              musicOn: settings.musicOn,
                              sfxOn: v,
                              volume: settings.volume);
                          if (v) audio.click();
                        }),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('🔈 Volume',
                                style:
                                    Alpine.body(16, theme: t)),
                            Expanded(
                              child: Slider(
                                value: settings.volume,
                                activeColor: t.accent,
                                onChanged: (v) {
                                  settings.setVolume(v);
                                  audio.configure(
                                      musicOn: settings.musicOn,
                                      sfxOn: settings.sfxOn,
                                      volume: v);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Alpine.panel(
                    theme: t,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('SKIER NAMES',
                            style: Alpine.label(13, theme: t)),
                        const SizedBox(height: 8),
                        for (var i = 0;
                            i < 4;
                            i++)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      'Skier ${i + 1}: ${settings.playerNames[i]}',
                                      style: Alpine.body(
                                          15, theme: t),
                                      overflow:
                                          TextOverflow.ellipsis),
                                ),
                                TextButton(
                                  onPressed: () => _rename(
                                      context, t, i),
                                  child: Text('✏️ Rename',
                                      style: Alpine.body(13,
                                          theme: t,
                                          color: t.accent)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Alpine.panel(
                    theme: t,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('STATS',
                            style: Alpine.label(13, theme: t)),
                        const SizedBox(height: 8),
                        Text(
                            '🏆 Wins: ${settings.wins}   🎿 Races: ${settings.gamesPlayed}',
                            style:
                                Alpine.body(15, theme: t)),
                        const SizedBox(height: 10),
                        Center(
                          child: Alpine.button(
                            theme: t,
                            label: 'Reset stats',
                            emoji: '🗑️',
                            onTap: () {
                              audio.click();
                              _confirmReset(context, t);
                            },
                          ),
                        ),
                      ],
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

  Widget _switchRow(MountainThemeDef t, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Alpine.body(16, theme: t)),
        Switch(
          value: value,
          activeThumbColor: t.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _rename(
      BuildContext context, MountainThemeDef t, int index) {
    audio.click();
    final ctrl =
        TextEditingController(text: settings.playerNames[index]);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Alpine.panel(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Skier name',
                  style: Alpine.display(22, theme: t)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLength: 14,
                style: Alpine.body(17, theme: t),
                // Save on EVERY keystroke (JSON order-safe key); the Save
                // button below commits the final value on focus loss.
                onChanged: (v) => settings.setPlayerName(index, v),
                decoration: InputDecoration(
                  filled: true,
                  fillColor:
                      Colors.black.withValues(alpha: 0.25),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: Alpine.label(10, theme: t),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                children: [
                  Alpine.button(
                    theme: t,
                    label: 'Cancel',
                    onTap: () {
                      audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                  Alpine.button(
                    theme: t,
                    label: 'Save',
                    primary: true,
                    onTap: () {
                      audio.click();
                      settings.setPlayerName(index, ctrl.text);
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

  void _confirmReset(BuildContext context, MountainThemeDef t) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Alpine.panel(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reset all stats?',
                  style: Alpine.display(20, theme: t)),
              const SizedBox(height: 8),
              Text(
                  'Wins, races and best times will be cleared.',
                  style: Alpine.body(14, theme: t),
                  textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                children: [
                  Alpine.button(
                    theme: t,
                    label: 'Keep',
                    onTap: () {
                      audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                  Alpine.button(
                    theme: t,
                    label: 'Reset',
                    primary: true,
                    onTap: () {
                      audio.click();
                      settings.resetStats();
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
}
