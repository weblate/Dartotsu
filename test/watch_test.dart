import 'package:dartotsu/Screen/Detail/Watch/Components/StreamGroups.dart';
import 'package:dartotsu/Screen/Detail/Watch/Data/EpisodeMeta.dart';
import 'package:dartotsu/Screen/Detail/Watch/Data/EpisodeMetaService.dart';
import 'package:dartotsu/Screen/Detail/Watch/Data/EpisodeUnits.dart';
import 'package:dartotsu/Screen/Detail/Watch/Data/Providers/AniZip.dart';
import 'package:dartotsu/Screen/Detail/Watch/Data/TitleMatch.dart';
import 'package:dartotsu_extension_bridge/Models/Video.dart' as v;
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('title ratio ignores case, punctuation and word order', () {
    expect(titleRatio('Sousou no Frieren', 'sousou no frieren!'), 100);
    expect(titleRatio('Frieren Sousou no', 'Sousou no Frieren'), 100);
    expect(titleRatio('One Piece', 'Naruto'), lessThan(40));
  });

  test('episodes that start high are renumbered from one', () {
    final input = [
      for (var n = 14; n >= 12; n--) DEpisode(episodeNumber: '$n'),
    ];
    final out = normalizeEpisodes(input);
    expect([for (final e in out) e.episodeNumber], ['1', '2', '3']);
  });

  test('chapter numbers come from the title when the source has none', () {
    final out = prepareChapters([
      DEpisode(episodeNumber: '', name: 'Chapter 12.5'),
      DEpisode(episodeNumber: '', name: 'Vol.1 Chapter 12'),
    ], 'Title');
    expect([for (final e in out) e.episodeNumber], ['12', '12.5']);
  });

  test('chunks and the chunk holding the next unit', () {
    final units = [
      for (var i = 1; i <= 7; i++)
        WatchUnit(
          raw: DEpisode(episodeNumber: '$i'),
          number: '$i',
          value: i.toDouble(),
          title: '',
        ),
    ];
    final chunks = chunkUnits(units, 3);
    expect(chunks.length, 3);
    expect(chunkOf(chunks, 3), 1);
    expect(chunkOf(chunks, 7), 2);
  });

  test('metadata merge takes the first provider with a value', () {
    final merged = EpisodeMetaService.merge(
      order: const ['anizip', 'kitsu', 'tenrai'],
      {
        'anizip': {'1': EpisodeMeta(number: '1', title: 'A')},
        'kitsu': {
          '1': EpisodeMeta(number: '1', title: 'B', thumbnail: 't'),
          '2': EpisodeMeta(number: '2', title: 'C'),
        },
        'tenrai': {'1': EpisodeMeta(number: '1', filler: true)},
      },
    );
    expect(merged['1']!.title, 'A');
    expect(merged['1']!.thumbnail, 't');
    expect(merged['1']!.filler, true);
    expect(merged['2']!.title, 'C');
  });

  test('ani.zip episodes are keyed by absolute number and skip specials', () {
    final out = parseAniZipEpisodes({
      '500': {
        'episodeNumber': 19,
        'seasonNumber': 14,
        'absoluteEpisodeNumber': 500,
        'title': {'en': 'Freedom Taken Away!'},
      },
      '1000': {
        'episodeNumber': 109,
        'seasonNumber': 21,
        'absoluteEpisodeNumber': 1000,
        'title': {'en': 'Overwhelming Strength!'},
      },
      'S1': {
        'episodeNumber': 1,
        'seasonNumber': 0,
        'title': {'en': 'A special'},
      },
    });
    expect(out.keys.toSet(), {'500', '1000'});
    expect(out['1000']!.title, 'Overwhelming Strength!');
  });

  group('seasons by scanlator', () {
    List<DEpisode> twoSeasons() => [
      for (var n = 3; n >= 1; n--)
        DEpisode(episodeNumber: '$n', scanlator: 'Season 2'),
      for (var n = 3; n >= 1; n--)
        DEpisode(episodeNumber: '$n', scanlator: 'Season 1'),
    ];

    test('overlapping numbers keep each season separate', () {
      final out = normalizeAll(twoSeasons());
      expect(seasonNames(out), ['Season 1', 'Season 2']);
      expect(out.map((e) => '${e.scanlator}:${e.episodeNumber}'), [
        'Season 1:1',
        'Season 1:2',
        'Season 1:3',
        'Season 2:1',
        'Season 2:2',
        'Season 2:3',
      ]);
    });

    test('distinct numbers are not split', () {
      final out = normalizeAll([
        DEpisode(episodeNumber: '2', scanlator: 'Sub'),
        DEpisode(episodeNumber: '1', scanlator: 'Dub'),
      ]);
      expect(seasonNames(out), isEmpty);
    });

    test('seasoned units get distinct keys', () {
      final units = buildUnits(
        normalizeAll(twoSeasons()),
        const {},
        fallbackThumb: '',
        anime: true,
        seasoned: true,
      );
      expect(units.map((u) => u.key).toSet().length, units.length);
      expect(units.first.slot, units.first.key);
    });
  });

  group('stream groups', () {
    v.Video video(String title, [String quality = '']) =>
        v.Video(title, 'https://x/$title', quality);

    test('classifies sub, hard sub, soft sub, dub and raw', () {
      expect(streamKindOf(video('Server 1 - 1080p [Sub]')), StreamKind.sub);
      expect(streamKindOf(video('HardSub 720p')), StreamKind.hardSub);
      expect(streamKindOf(video('Hard Sub - 480p')), StreamKind.hardSub);
      expect(streamKindOf(video('SoftSub 1080p')), StreamKind.softSub);
      expect(streamKindOf(video('Dub 1080p')), StreamKind.dub);
      expect(streamKindOf(video('Raw 1080p')), StreamKind.raw);
      expect(streamKindOf(video('1080p')), StreamKind.other);
    });

    test('groups by kind in a fixed order and keeps indices', () {
      final groups = groupStreams([
        video('Dub 1080p'),
        video('Sub 1080p'),
        video('Hard Sub 720p'),
        video('Sub 720p'),
      ]);
      expect(groups!.map((g) => g.kind), [
        StreamKind.sub,
        StreamKind.hardSub,
        StreamKind.dub,
      ]);
      expect(groups.first.indices, [1, 3]);
    });

    test('a single kind or no kinds stays a flat list', () {
      expect(groupStreams([video('Sub 1080p'), video('Sub 720p')]), isNull);
      expect(groupStreams([video('1080p'), video('720p')]), isNull);
    });
  });
}
