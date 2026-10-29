import 'PlayerEngine.dart';

const _alternates = {
  'eng': ['en', 'english'],
  'spa': ['es', 'spanish', 'esp', 'latino'],
  'por': ['pt', 'portuguese'],
  'pob': ['pt-br', 'ptbr', 'brazilian'],
  'fre': ['fr', 'fra', 'french'],
  'ger': ['de', 'deu', 'german'],
  'ita': ['it', 'italian'],
  'rus': ['ru', 'russian'],
  'ara': ['ar', 'arabic'],
  'ind': ['id', 'indonesian'],
  'jpn': ['ja', 'jp', 'japanese'],
  'kor': ['ko', 'korean'],
  'chi': ['zh', 'zho', 'chinese'],
  'tur': ['tr', 'turkish'],
  'vie': ['vi', 'vietnamese'],
  'tha': ['th', 'thai'],
  'pol': ['pl', 'polish'],
  'dut': ['nl', 'nld', 'dutch'],
  'hin': ['hi', 'hindi'],
};

List<String> languageList(String text) => [
  for (final part in text.split(RegExp(r'[,;\n]')))
    if (part.trim().isNotEmpty) part.trim(),
];

Set<String> languageKeys(String name) {
  final wanted = name.trim().toLowerCase();
  final keys = {wanted};
  for (final entry in _alternates.entries) {
    final all = {entry.key, ...entry.value};
    if (all.contains(wanted) ||
        entry.value.last.startsWith(wanted) && wanted.length >= 3) {
      keys.addAll(all);
    }
  }
  return keys;
}

final _rawPattern = RegExp(r'[\\|()\[\]{}^$*+?]');
final _slashed = RegExp(r'^/(.+)/i?$');

RegExp? languagePattern(String entry) {
  final raw = entry.trim();
  if (raw.isEmpty) return null;
  try {
    final slashed = _slashed.firstMatch(raw);
    if (slashed != null) return RegExp(slashed[1]!, caseSensitive: false);
    if (_rawPattern.hasMatch(raw)) return RegExp(raw, caseSensitive: false);
    final keys = languageKeys(raw).map(RegExp.escape).join('|');
    return RegExp('(?:^|[^a-z])(?:$keys)(?:[^a-z]|\$)', caseSensitive: false);
  } catch (_) {
    return null;
  }
}

bool languageMatches(RegExp pattern, {String? language, String? title}) =>
    pattern.hasMatch(language ?? '') || pattern.hasMatch(title ?? '');

bool _matches(PlayerTrack track, RegExp pattern) =>
    languageMatches(pattern, language: track.language, title: track.title);

final _signs = RegExp(r'sign|song|forced', caseSensitive: false);

bool _forcedOrSigns(PlayerTrack track) => _signs.hasMatch(track.title ?? '');

bool labelIsSigns(String label) => _signs.hasMatch(label);

PlayerTrack? pickTrack(
  List<PlayerTrack> tracks,
  List<String> priority, {
  bool avoidSigns = false,
}) {
  for (final language in priority) {
    final pattern = languagePattern(language);
    if (pattern == null) continue;
    final found = tracks.where((t) => _matches(t, pattern)).toList();
    if (found.isEmpty) continue;
    if (avoidSigns) {
      final full = found.where((t) => !_forcedOrSigns(t));
      if (full.isNotEmpty) return full.first;
    }
    return found.first;
  }
  return null;
}
