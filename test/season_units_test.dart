import 'package:dartotsu/Screen/Detail/Watch/Data/EpisodeUnits.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

DEpisode ep(int number, String season) => DEpisode(
  episodeNumber: '$number',
  scanlator: season,
  name: '$season episode $number',
);

List<DEpisode> show() => [
  for (final n in [3, 2, 1]) ep(n, 'Season 1'),
  for (final n in [2, 1]) ep(n, 'Season 2'),
  ep(1, 'Specials'),
];

void main() {
  test('episode 1 of two seasons stays two whole episodes', () {
    final normalized = normalizeAll(show());
    final numbers = normalized.map((e) => e.episodeNumber).toList();
    expect(numbers.where((n) => n.contains('.')), isEmpty);
    expect(seasonNames(normalized), ['Season 1', 'Season 2', 'Specials']);
  });

  test('seasons count on from the one before when progress is absolute', () {
    final normalized = normalizeAll(show());
    final names = seasonNames(normalized);
    final offsets = seasonOffsets(normalized, names);
    expect(offsets, {'Season 1': 0, 'Season 2': 3, 'Specials': 5});

    final second = buildUnits(
      [
        for (final e in normalized)
          if (seasonOf(e) == 'Season 2') e,
      ],
      const {},
      fallbackThumb: '',
      anime: true,
      seasoned: true,
      seasonOffsets: offsets,
    );
    expect(second.map((u) => u.number).toSet(), {'1', '2'});
    expect(second.map((u) => u.value).toSet(), {4.0, 5.0});
    expect(second.every((u) => u.isWatched(4) == (u.value <= 4)), isTrue);
  });

  test('without offsets each season keeps its own numbering', () {
    final normalized = normalizeAll(show());
    final first = buildUnits(
      [
        for (final e in normalized)
          if (seasonOf(e) == 'Season 2') e,
      ],
      const {},
      fallbackThumb: '',
      anime: true,
      seasoned: true,
    );
    expect(first.map((u) => u.value).toSet(), {1.0, 2.0});
  });
}
