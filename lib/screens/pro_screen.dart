import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/alpine.dart';
import '../theme/mountain_themes.dart';

/// Snow Slalom PRO: Free-vs-Pro comparison, real purchase, restore, tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
class ProScreen extends StatefulWidget {
  final SlalomAudio audio;
  final SlalomSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  MountainThemeDef get _t => widget.settings.theme;

  @override
  void initState() {
    super.initState();
    widget.store.lastThanks.addListener(_onThanks);
  }

  
  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Alpine.body(15, theme: _t)),
        backgroundColor: _t.hud,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
    return AlpineBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: t.hudText),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Snow Slalom PRO',
              style: Alpine.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 22, vertical: 14),
              child: Column(
                children: [
                                    _TipsCard(
                    theme: t,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PRO unlocks apply on this device. '
                    'Use Restore below after reinstalling.',
                    style: Alpine.body(11, theme: t,
                        color: t.hudText
                            .withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final MountainThemeDef theme;
  final StoreService store;
  final SlalomAudio audio;

  const _TipsCard(
      {required this.theme, required this.store, required this.audio});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store.lastThanks,
      builder: (_, _) => Alpine.panel(
        theme: theme,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('TIP JAR ☕',
                style: Alpine.label(13, theme: theme)),
            const SizedBox(height: 6),
            Text(
              'Snow Slalom is made by one indie developer. Tips keep the lifts running!',
              style: Alpine.body(13, theme: theme,
                  color: theme.hudText
                      .withValues(alpha: 0.8)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (!store.storeReady)
              Text(
                'Tips will appear here once the store products are set up.',
                style: Alpine.body(13, theme: theme,
                    color: theme.hudText
                        .withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              )
            else
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                children: [
                  _tipBtn(store.coffeeProduct, '☕'),
                  _tipBtn(store.chocolateProduct, '🍫'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _tipBtn(ProductDetails? product, String emoji) {
    if (product == null) return const SizedBox.shrink();
    return Alpine.button(
      theme: theme,
      label: product.price,
      emoji: emoji,
      onTap: () {
        audio.click();
        store.buyTip(product);
      },
    );
  }
}
