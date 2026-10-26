import 'package:dartotsu/Api/Services/Simkl/Mutations.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> ep(String type, Object? season, Object? episode) => {
  'type': type,
  'season': season,
  'episode': episode,
};

void main() {
  test('only aired regular episodes count, in season order', () {
    final list = parseSimklTvEpisodes([
      ep('episode', 2, 1),
      ep('episode', 1, 2),
      ep('special', null, 1),
      ep('episode', 0, 1),
      ep('episode', 1, 1),
      ep('episode', null, 3),
      'junk',
    ]);
    expect(list, [(1, 1), (1, 2), (2, 1)]);
  });

  test('not a list means no episodes', () {
    expect(parseSimklTvEpisodes(null), isEmpty);
    expect(parseSimklTvEpisodes({'a': 1}), isEmpty);
  });

  test('episodes are grouped under their season', () {
    final entry = simklShowEpisodes(19625, [(1, 1), (1, 2), (2, 1)]);
    expect(entry['ids'], {'simkl': 19625});
    expect(entry['seasons'], [
      {
        'number': 1,
        'episodes': [
          {'number': 1},
          {'number': 2},
        ],
      },
      {
        'number': 2,
        'episodes': [
          {'number': 1},
        ],
      },
    ]);
  });
}
