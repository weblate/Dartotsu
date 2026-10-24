import 'package:dartotsu/Api/Services/MangaUpdates/Data/Mapper.dart';
import 'package:dartotsu/Api/Services/MangaUpdates/MangaUpdatesService.dart';
import 'package:dartotsu/Api/Services/MangaUpdates/Queries.dart';
import 'package:dartotsu/Core/Services/MediaService.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _series({List<String> genres = const ['Action']}) => {
  'series_id': 51239621230,
  'title': 'Berserk',
  'url': 'https://www.mangaupdates.com/series/njeqwry/berserk',
  'description': 'Guts, the Black Swordsman',
  'image': {
    'url': {
      'original': 'https://cdn.mangaupdates.com/image/i501230.png',
      'thumb': 'https://cdn.mangaupdates.com/image/thumb/i501230.png',
    },
  },
  'type': 'Manga',
  'year': '1989',
  'bayesian_rating': 8.98,
  'rating_votes': 3731,
  'latest_chapter': 386,
  'status': '43 Volumes (Ongoing)',
  'completed': false,
  'genres': [
    for (final g in genres) {'genre': g},
  ],
  'authors': [
    {'name': 'MIURA Kentaro', 'author_id': 1, 'type': 'Author'},
    {'name': 'MORI Kouji', 'author_id': 2, 'type': 'Artist'},
  ],
  'related_series': [
    {
      'related_series_id': 13692341141,
      'related_series_name': 'Challenging the Manga Dojos',
      'relation_type': 'Spin-Off',
    },
  ],
};

void main() {
  group('series mapping', () {
    test('maps the fields the detail page uses', () {
      final media = mapMangaUpdatesSeries(_series());
      expect(media.id, '51239621230');
      expect(media.name, 'Berserk');
      expect(media.cover, 'https://cdn.mangaupdates.com/image/i501230.png');
      expect(media.meanScore, 90);
      expect(media.status, 'RELEASING');
      expect(media.format, 'MANGA');
      expect(media.manga?.totalChapters, 386);
      expect(media.isAdult, isFalse);
      expect(media.relations?.single.relation, 'Spin-Off');
      final extras = mangaUpdatesExtras[media]!;
      expect(extras.authors, ['MIURA Kentaro']);
      expect(extras.artists, ['MORI Kouji']);
    });

    test('adult genres mark the series as adult', () {
      expect(
        mapMangaUpdatesSeries(_series(genres: ['Drama', 'Hentai'])).isAdult,
        isTrue,
      );
    });

    test('share links use the base 36 slug', () {
      expect(mangaUpdatesShareLink(51239621230), endsWith('/series/njeqwry'));
    });
  });

  group('list entries', () {
    test('map the list type, chapter and rating', () {
      final media = mapMangaUpdatesSeries(_series());
      applyMangaUpdatesEntry(
        media,
        {
          'list_id': 4,
          'list_type': 'hold',
          'status': {'chapter': 120},
        },
        metadata: {'user_rating': 8.5},
      );
      expect(media.userStatus, 'PAUSED');
      expect(media.userProgress, 120);
      expect(media.userScore, 85);
    });
  });

  group('service', () {
    final service = MangaUpdatesService();

    test('opens series links by their base 36 slug', () {
      final link = service.parseUri(
        Uri.parse('https://www.mangaupdates.com/series/njeqwry/berserk'),
      );
      expect(link?.kind, AppLinkKind.manga);
      expect(link?.value, '51239621230');
    });

    test('clean ids accept prefixed values', () {
      expect(MangaUpdatesQueries.cleanId('manga/42'), 42);
      expect(MangaUpdatesQueries.cleanId('x'), isNull);
    });
  });
}
