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
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      widget.audio.win();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — the whole mountain is yours!',
              style: Alpine.body(15, theme: _t)),
          backgroundColor: _t.hud,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
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
    widget.store.proPurchased.removeListener(_onPro);
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
                  _ComparisonCard(theme: t, isPro: s.isPro),
                  const SizedBox(height: 16),
                  _BuyCard(
                    theme: t,
                    settings: s,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 16),
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

class _ComparisonCard extends StatelessWidget {
  final MountainThemeDef theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['Mountain themes', '4', '12 + aurora nights'],
      ['Skier styles', '4', '10 + custom creator'],
      ['Difficulties', 'Bunny + Blue', '+ Black Diamond'],
      ['Race modes', 'Time Trial, Pass & Play', '+ Score Attack'],
      ['Pass & Play skiers', '2–4', '2–4'],
    ];
    return Alpine.panel(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('FREE vs PRO',
                  style: Alpine.display(20, theme: theme)),
              const Spacer(),
              if (isPro)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('YOU ARE PRO ⭐',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(1.4),
              2: FlexColumnWidth(1.8),
            },
            children: [
              TableRow(
                children: [
                  _cell(theme, '', header: true),
                  _cell(theme, 'FREE', header: true),
                  _cell(theme, 'PRO', header: true),
                ],
              ),
              for (final r in rows)
                TableRow(
                  children: [
                    _cell(theme, r[0]),
                    _cell(theme, r[1], dim: true),
                    _cell(theme, r[2], pro: true),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(MountainThemeDef t, String text,
      {bool header = false, bool dim = false, bool pro = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          color: pro
              ? t.accent
              : t.hudText.withValues(alpha: dim ? 0.7 : 1),
          fontWeight: header
              ? FontWeight.w900
              : (pro ? FontWeight.w800 : FontWeight.w600),
          fontSize: header ? 13 : 12.5,
          letterSpacing: header ? 1.2 : 0,
        ),
      ),
    );
  }
}

class _BuyCard extends StatelessWidget {
  final MountainThemeDef theme;
  final SlalomSettings settings;
  final StoreService store;
  final SlalomAudio audio;

  const _BuyCard({
    required this.theme,
    required this.settings,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store.purchaseInProgress,
      builder: (_, _) => Alpine.panel(
        theme: theme,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('UNLOCK PRO FOREVER',
                style: Alpine.label(13, theme: theme)),
            const SizedBox(height: 8),
            if (!store.storeReady) ...[
              Text(
                store.error ??
                    'PRO purchases will appear here once the store products are set up.',
                style: Alpine.body(14, theme: theme,
                    color: theme.hudText
                        .withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
            ] else if (settings.isPro) ...[
              Text('PRO is active on this account. Enjoy! ⭐',
                  style: Alpine.body(15, theme: theme),
                  textAlign: TextAlign.center),
            ] else ...[
              Text(
                'One-time purchase — no subscription, yours forever.',
                style: Alpine.body(13, theme: theme,
                    color: theme.hudText
                        .withValues(alpha: 0.8)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Center(
                child: store.purchaseInProgress.value
                    ? const CircularProgressIndicator()
                    : Alpine.button(
                        theme: theme,
                        label:
                            'Unlock PRO${store.proProduct != null ? ' — ${store.proProduct!.price}' : ''}',
                        emoji: '⭐',
                        primary: true,
                        onTap: () {
                          audio.click();
                          store.buyPro();
                        },
                      ),
              ),
            ],
            if (store.purchaseError.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(store.purchaseError.value!,
                    style: const TextStyle(
                        color: Color(0xFFE0442E),
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center),
              ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {
                  audio.click();
                  store.restore();
                },
                child: Text('Restore purchases',
                    style: Alpine.body(14, theme: theme,
                        color: theme.accent)),
              ),
            ),
          ],
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
