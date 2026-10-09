import 'package:flutter_test/flutter_test.dart';
import 'package:snowslalom/services/settings_service.dart';

/// Player-name persistence: ONE JSON string, never a StringList —
/// Android's SharedPreferences stores StringLists as an unordered
/// StringSet, which would scramble name order on every restart.
void main() {
  test('encode/decode round-trips 4 names in order', () {
    const names = ['Ace', 'Bea', 'Cy', 'Dee'];
    final raw = SlalomSettings.encodePlayerNames(names);
    expect(SlalomSettings.decodePlayerNames(raw), names);
  });

  test('names with commas, quotes and emoji survive JSON encoding', () {
    const names = ['O"Brien, Jr.', 'Zoë ⛷️', '  ', 'Max'];
    final raw = SlalomSettings.encodePlayerNames(names);
    final back = SlalomSettings.decodePlayerNames(raw);
    expect(back[0], 'O"Brien, Jr.');
    expect(back[1], 'Zoë ⛷️');
    // Blank names fall back to defaults, never empty strings.
    expect(back[2], isNotEmpty);
    expect(back[3], 'Max');
  });

  test('corrupt or missing data falls back to defaults', () {
    expect(SlalomSettings.decodePlayerNames(null),
        SlalomSettings.defaultNames);
    expect(SlalomSettings.decodePlayerNames('not json'),
        SlalomSettings.defaultNames);
    expect(SlalomSettings.decodePlayerNames('["only","two"]'),
        SlalomSettings.defaultNames);
  });
}
