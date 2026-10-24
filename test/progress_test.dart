import 'package:dartotsu/Core/Services/Api/Progress.dart';
import 'package:dartotsu/Core/Services/Model/Manga.dart';
import 'package:dartotsu/Core/Services/Model/Media.dart';
import 'package:flutter_test/flutter_test.dart';

Media manga(String status, int? chapters) => Media(
  id: 'm',
  name: 'Series',
  nameRomaji: 'Series',
  status: status,
  manga: Manga(totalChapters: chapters),
  shareLink: '',
);

void main() {
  group('reachesEnd', () {
    test('a finished series completes at its last chapter', () {
      expect(reachesEnd(manga('FINISHED', 100), 100), isTrue);
      expect(reachesEnd(manga('FINISHED', 100), 99), isFalse);
    });

    test('an ongoing series never completes from its latest chapter', () {
      expect(reachesEnd(manga('RELEASING', 100), 100), isFalse);
      expect(reachesEnd(manga('HIATUS', 100), 100), isFalse);
      expect(reachesEnd(manga('NOT_YET_RELEASED', 12), 12), isFalse);
    });

    test('an unknown total never completes', () {
      expect(reachesEnd(manga('FINISHED', null), 50), isFalse);
      expect(reachesEnd(manga('FINISHED', 0), 50), isFalse);
    });
  });

  group('applyProgress', () {
    test('reading the latest chapter of an ongoing series keeps it current', () {
      final media = manga('RELEASING', 100)..userStatus = 'CURRENT';
      applyProgress(media, 100);
      expect(media.userStatus, 'CURRENT');
      expect(media.userCompletedAt?.year, isNull);
    });

    test('finishing a finished series completes it', () {
      final media = manga('FINISHED', 100)..userStatus = 'CURRENT';
      applyProgress(media, 100);
      expect(media.userStatus, 'COMPLETED');
    });
  });
}
