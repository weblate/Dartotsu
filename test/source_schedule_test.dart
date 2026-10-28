import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:dartotsu/Core/Services/Model/Manga.dart';
import 'package:dartotsu/Core/Services/Model/Media.dart';
import 'package:dartotsu/Core/SourceAlerts/SourceSchedule.dart';
import 'package:dartotsu/Core/SourceAlerts/SourceSub.dart';
import 'package:flutter_test/flutter_test.dart';

const hour = 3600000;
const day = 24 * hour;
final now = DateTime(2026, 10, 26, 12).millisecondsSinceEpoch;

SourceSub sub({
  int? progress,
  int local = 0,
  String? status,
  double last = 5,
  int next = 0,
  List<int>? releases,
  int released = 0,
  int? airingAt,
}) => SourceSub(
  serviceId: 'anilist',
  mediaId: '1',
  serviceName: 'AniList',
  anime: true,
  type: 'anime',
  media: {'id': '1'},
  title: 'Show',
  managerId: 'm',
  managerName: 'Manager',
  sourceId: 's',
  sourceName: 'Source',
  targetUrl: 'https://x/1',
  progress: progress,
  localProgress: local,
  listStatus: status,
  lastValue: last,
  nextCheckAt: next,
  releases: releases,
  lastReleaseAt: released,
  airingAt: airingAt,
);

List<int> weekly(int count, {int end = 0}) => [
  for (var i = count - 1; i >= 0; i--) (end == 0 ? now : end) - i * 7 * day,
];

void main() {
  group('releaseInterval', () {
    test('weekly releases give about a week', () {
      expect(releaseInterval(weekly(5)), 7 * day);
    });
    test('needs two release times', () {
      expect(releaseInterval([now]), isNull);
      expect(releaseInterval(const []), isNull);
    });
    test('drops batch uploads under an hour apart', () {
      expect(releaseInterval([now, now + 1000, now + 2000]), isNull);
    });
    test('ignores a hiatus gap', () {
      final stamps = [...weekly(4, end: now - 60 * day), now];
      expect(releaseInterval(stamps), 7 * day);
    });
    test('is clamped', () {
      expect(releaseInterval([now, now + hour + 1]), 3 * hour);
      expect(releaseInterval([now, now + 90 * day]), 30 * day);
    });
  });

  group('quietPeriod', () {
    test('a weekly show stays quiet for six days', () {
      expect(quietPeriod(7 * day), 6 * day);
    });
    test('a daily show has no quiet period', () {
      expect(quietPeriod(day), 0);
      expect(quietPeriod(day ~/ 2), 0);
    });
    test('long gaps use fifteen percent', () {
      expect(quietPeriod(30 * day), 30 * day - (4.5 * day).round());
    });
  });

  group('computeNextCheck', () {
    test('waits out the quiet period after a release', () {
      final s = sub(releases: weekly(4), released: now - 2 * day);
      expect(computeNextCheck(s, now), now - 2 * day + 6 * day);
    });
    test('retries in six hours when due and nothing is out', () {
      final s = sub(releases: weekly(4), released: now - 6 * day - hour);
      expect(computeNextCheck(s, now), now + 6 * hour);
    });
    test('backs off when the release is late', () {
      final s = sub(releases: weekly(4), released: now - 12 * day);
      expect(computeNextCheck(s, now), now + 12 * hour);
      final later = sub(releases: weekly(4), released: now - 30 * day);
      expect(computeNextCheck(later, now), now + day);
      final dormant = sub(releases: weekly(4), released: now - 90 * day);
      expect(computeNextCheck(dormant, now), now + 7 * day);
    });
    test('an upcoming airing time wins', () {
      final s = sub(
        releases: weekly(4),
        released: now - 6 * day,
        airingAt: now + 3 * hour,
      );
      expect(computeNextCheck(s, now), now + 3 * hour + 30 * 60000);
    });
    test('a stale airing time is ignored', () {
      final s = sub(releases: const [], airingAt: now - day);
      expect(computeNextCheck(s, now), now + 6 * hour);
    });
    test('no data means six hours', () {
      expect(computeNextCheck(sub(), now), now + 6 * hour);
    });
  });

  group('failureBackoff', () {
    test('doubles from an hour up to a day', () {
      expect(failureBackoff(1), hour);
      expect(failureBackoff(2), 2 * hour);
      expect(failureBackoff(3), 4 * hour);
      expect(failureBackoff(6), day);
      expect(failureBackoff(40), day);
    });
  });

  group('skipReason', () {
    const rules = SkipRules();
    test('completed titles are skipped and can come back', () {
      final s = sub(progress: 5, status: 'COMPLETED');
      expect(skipReason(s, now, rules), SkipReason.completed);
      s.listStatus = 'CURRENT';
      expect(skipReason(s, now, rules), isNull);
    });
    test('unstarted only when episodes already exist', () {
      expect(skipReason(sub(progress: 0), now, rules), SkipReason.unstarted);
      expect(skipReason(sub(progress: 0, last: 0), now, rules), isNull);
    });
    test('unseen at the boundary', () {
      expect(skipReason(sub(progress: 4), now, rules), SkipReason.unseen);
      expect(skipReason(sub(progress: 5), now, rules), isNull);
      expect(skipReason(sub(progress: 6), now, rules), isNull);
    });
    test('local progress counts as seen', () {
      expect(skipReason(sub(progress: 2, local: 5), now, rules), isNull);
    });
    test('unknown progress is never skipped by progress rules', () {
      expect(skipReason(sub(), now, rules), isNull);
    });
    test('the release window skips until it is due', () {
      final s = sub(progress: 5, next: now + hour);
      expect(skipReason(s, now, rules), SkipReason.window);
      expect(skipReason(s, now, rules, ignoreWindow: true), isNull);
      s.nextCheckAt = now;
      expect(skipReason(s, now, rules), isNull);
    });
    test('each rule can be turned off', () {
      final off = const SkipRules(unstarted: false, unseen: false);
      expect(skipReason(sub(progress: 0), now, off), isNull);
      expect(skipReason(sub(progress: 1), now, off), isNull);
      expect(
        skipReason(sub(progress: 5, status: 'COMPLETED'), now, off),
        SkipReason.completed,
      );
    });
  });

  group('latestOf', () {
    DEpisode ep(String n, {String? date, String? season}) =>
        DEpisode(episodeNumber: n, dateUpload: date, scanlator: season);

    test('finds the highest number and keeps distinct values', () {
      final latest = latestOf([ep('3'), ep('1'), ep('2'), ep('3')])!;
      expect(latest.max, 3);
      expect(latest.values, [1, 2, 3]);
    });
    test('half chapters count', () {
      expect(latestOf([ep('10'), ep('10.5')])!.max, 10.5);
    });
    test('ignores entries without a number', () {
      expect(latestOf([ep('x'), ep('2')])!.max, 2);
      expect(latestOf([ep('x')]), isNull);
    });
    test('collects dates of the newest units', () {
      final a = DateTime(2026, 10, 1).millisecondsSinceEpoch.toString();
      final b = DateTime(2026, 10, 8).millisecondsSinceEpoch.toString();
      final latest = latestOf([ep('1', date: a), ep('2', date: b), ep('3')])!;
      expect(latest.stamps, [int.parse(a), int.parse(b)]);
    });
    test('only the picked season counts', () {
      final list = [
        ep('1', season: 'Season 1'),
        ep('2', season: 'Season 1'),
        ep('1', season: 'Season 2'),
      ];
      expect(latestOf(list, season: 'Season 2')!.max, 1);
      expect(latestOf(list, season: 'Season 1')!.max, 2);
    });
  });

  group('mergeReleases', () {
    test('keeps the newest eight, sorted and distinct', () {
      final merged = mergeReleases(
        [for (var i = 0; i < 6; i++) now - i * day],
        [for (var i = 6; i < 12; i++) now - i * day, now],
        now,
      );
      expect(merged.length, 8);
      expect(merged.last, now);
      expect(merged, [...merged]..sort());
    });
    test('drops future and nonsense stamps', () {
      expect(mergeReleases(const [], [now + 5 * day, 0, 1000], now), isEmpty);
    });
  });

  test('unitLabel', () {
    expect(unitLabel(12), '12');
    expect(unitLabel(12.5), '12.5');
  });

  test('a subscription survives a json round trip', () {
    final s = sub(
      progress: 3,
      local: 4,
      status: 'CURRENT',
      next: 99,
      releases: [1, 2],
      released: 7,
      airingAt: 55,
    )..muted = true;
    final back = SourceSub.fromJson(s.toJson())!;
    expect(back.toJson(), s.toJson());
    expect(back.key, 'anilist/1');
    expect(back.seen, 4);
  });

  test('reachedTotal needs a known total', () {
    expect(reachedTotal(12, 12), isTrue);
    expect(reachedTotal(11, 12), isFalse);
    expect(reachedTotal(99, null), isFalse);
    expect(reachedTotal(99, 0), isFalse);
  });

  test('a total only counts once the title is finished', () {
    Media chapters(String? status) => Media(
      id: '1',
      shareLink: '',
      status: status,
      manga: Manga(totalChapters: 40),
    );
    expect(finalTotal(chapters('FINISHED')), 40);
    expect(finalTotal(chapters('RELEASING')), isNull);
    expect(finalTotal(chapters(null)), isNull);
  });

  group('subReleases', () {
    test('a release from today is listed with its episode', () {
      final s = sub(
        releases: [now - 14 * day, now - 7 * day, now - 3 * hour],
        released: now - 3 * hour,
        last: 5,
      );
      final past = subReleases(s, now).where((r) => !r.expected).toList();
      expect(past.map((r) => r.episode).toList(), [5]);
    });

    test('a weekly rhythm expects the next one a week after the last', () {
      final s = sub(
        releases: [now - 17 * day, now - 10 * day, now - 3 * day],
        released: now - 3 * day,
        last: 5,
      );
      final out = subReleases(s, now);
      expect(out.where((r) => !r.expected), isEmpty);
      final next = out.single;
      expect(next.expected, isTrue);
      expect(next.episode, 6);
      expect(next.at, now + 4 * day);
    });

    test('a published airing time wins over the median gap', () {
      final s = sub(
        releases: [now - 14 * day, now - 7 * day],
        released: now - 7 * day,
        airingAt: now + 2 * day,
        last: 3,
      );
      final next = subReleases(s, now).where((r) => r.expected).single;
      expect(next.at, now + 2 * day);
      expect(next.episode, 4);
    });

    test('daily releases project several days ahead', () {
      final s = sub(
        releases: [
          now - 3 * day + 3 * hour,
          now - 2 * day + 3 * hour,
          now - day + 3 * hour,
        ],
        released: now - day + 3 * hour,
        last: 9,
      );
      final next = subReleases(s, now).where((r) => r.expected).toList();
      expect(next.length, greaterThan(2));
      expect(next.map((r) => r.episode).toList().take(2), [10, 11]);
    });

    test('nothing is predicted without a rhythm or airing time', () {
      final s = sub(releases: [now - 30 * day], released: now - 30 * day);
      expect(subReleases(s, now), isEmpty);
    });
  });
}
