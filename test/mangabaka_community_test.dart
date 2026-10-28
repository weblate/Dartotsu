import 'package:dartotsu/Api/Services/MangaBaka/Data/Community.dart';
import 'package:dartotsu/Api/Services/MangaBaka/Data/Mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the v2 series shape (string covers, no title key) still maps', () {
    final media = mapMangaBakaSeries({
      'id': 2060,
      'canonical_url': 'https://mangabaka.org/manhwa/2060/x',
      'type': 'manhwa',
      'status': 'hiatus',
      'content_rating': 'safe',
      'cover': {'raw': 'raw.jpg', 'x250': 'small.jpg', 'x350': 'big.jpg'},
      'titles': [
        {'language': 'de', 'title': 'Omniscient Reader’s Viewpoint'},
        {'language': 'ko', 'title': '전지적 독자 시점', 'is_primary': true},
      ],
    });
    expect(media.cover, 'big.jpg');
    expect(media.mainName, isNotEmpty);
    expect(media.status, 'HIATUS');
  });

  test('a stack page reads owner, counts, covers and the next page', () {
    final page = parseStackPage({
      'pagination': {'next': 'https://api.mangabaka.org/v2/stacks?page=2'},
      'data': [
        {
          'id': 59,
          'title': 'Villainess',
          'canonical_url': 'https://mangabaka.org/stacks/59-villainess',
          'kind': 'personal',
          'visibility': 'public',
          'content_rating': 'suggestive',
          'is_spoiler': false,
          'is_featured': true,
          'owner': {'username': 'lelouch', 'name': 'Lelouch'},
          'entry_count': 99,
          'vote_count': 2,
          'save_count': 4,
          'covers': [
            {
              'series_id': 1,
              'cover': {'raw': 'a.jpg', 'x350': 'b.jpg'},
            },
            {'series_id': 2, 'cover': null},
          ],
        },
      ],
    });
    expect(page.hasNext, isTrue);
    final stack = page.items.single;
    expect(stack.id, 59);
    expect(stack.owner.label, 'Lelouch');
    expect(stack.entryCount, 99);
    expect(stack.featured, isTrue);
    expect(stack.covers, ['b.jpg']);
    expect(stack.adult, isFalse);
  });

  test('a stack detail keeps its entries in order and skips broken ones', () {
    final stack = parseStack({
      'id': 1,
      'title': 'T',
      'description': 'About',
      'entries': [
        {
          'kind': 'series',
          'rank': 2,
          'note': 'second',
          'series': {'id': 20, 'title': 'Two'},
        },
        {'kind': 'series', 'rank': 3, 'series': null},
        {
          'kind': 'series',
          'rank': 1,
          'series': {'id': 10, 'title': 'One'},
        },
      ],
    });
    expect(stack.description, 'About');
    expect([for (final e in stack.entries) e.rank], [2, 1]);
    expect(stack.entries.first.note, 'second');
    expect(stack.entries.first.media.id, '20');
  });

  test('a news page maps the source name and the published time', () {
    final page = parseNewsPage({
      'pagination': {'next': null},
      'data': [
        {
          'id': 5,
          'title': 'Fall guide',
          'url': 'https://example.com/a',
          'source_name': 'ann',
          'author': null,
          'published_at': '2026-10-26T00:00:00.000Z',
          'series': [
            {'id': 7, 'title': 'Wallaby'},
          ],
        },
      ],
    });
    expect(page.hasNext, isFalse);
    final item = page.items.single;
    expect(item.source, 'Anime News Network');
    expect(item.published?.year, 2026);
    expect(item.series.single.id, '7');
  });
}
