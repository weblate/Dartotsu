import 'package:flutter_test/flutter_test.dart';

import 'package:dartotsu/Screen/Detail/Watch/Data/Providers/AniZip.dart';
import 'package:dartotsu/Screen/Player/Engine/AniSkip.dart';
import 'package:dartotsu/Screen/Player/Engine/IntroDb.dart';

void main() {
  test('TheIntroDB v4 endpoint', () {
    expect(IntroDb.theIntroDbUrl, 'https://api.theintrodb.org/v4/media');
  });

  test('parses TheIntroDB segments and drops empty ones', () {
    final stamps = parseTheIntroDb({
      'intro': [
        {'start_ms': null, 'end_ms': 124000},
      ],
      'recap': [
        {'start_ms': 0, 'end_ms': 0},
      ],
      'credits': [
        {'start_ms': 46881, 'end_ms': 124500},
      ],
      'preview': [
        {'start_ms': 1459000, 'end_ms': 1500000},
      ],
    });
    expect(stamps.map((s) => s.kind), [
      SkipKind.opening,
      SkipKind.ending,
      SkipKind.other,
    ]);
    expect(stamps[0].start, 0.0);
    expect(stamps[0].end, 124.0);
    expect(stamps[1].start, closeTo(46.881, 0.001));
    expect(stamps[2].end, 1500.0);
  });

  test('parses IntroDB App segments', () {
    final stamps = parseIntroDbApp({
      'intro': {'start_sec': 28.5, 'end_sec': 118.5},
      'outro': {'start_sec': 1382.0, 'end_sec': 1422.0},
      'recap': null,
    });
    expect(stamps.length, 2);
    expect(stamps.first.kind, SkipKind.opening);
    expect(stamps.last.start, 1382.0);
  });

  test('empty or invalid responses give nothing', () {
    expect(parseTheIntroDb(null), isEmpty);
    expect(parseTheIntroDb({}), isEmpty);
    expect(parseIntroDbApp(null), isEmpty);
    expect(parseIntroDbApp({}), isEmpty);
  });

  test('reads external ids from ani.zip mappings', () {
    final ids = parseAniZipIds({
      'mappings': {
        'thetvdb_id': 76885,
        'themoviedb_id': '30991',
        'imdb_id': 'tt0213338',
      },
    });
    expect(ids.tvdb, 76885);
    expect(ids.tmdb, 30991);
    expect(ids.imdb, 'tt0213338');
    expect(parseAniZipIds(null).tvdb, isNull);
  });
}
