import 'package:dartotsu/Api/Services/MangaBaka/Client.dart';
import 'package:dartotsu/Api/Services/MangaBaka/LibrarySync.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> entry(int id, int series, int progress) => {
  'type': 'entry',
  'action': 'upsert',
  'revision': 0,
  'current': {
    'id': id,
    'series_id': series,
    'state': 'reading',
    'progress_chapter': progress,
    'is_private': false,
  },
};

class Fake {
  final calls = <String>[];
  final batches = <List<String>>[];
  List<Map<String, dynamic>> Function(String? cursor) changes = (_) => [];
  String cursor = 'c1';
  Object? failCursor;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    Map<String, List<String>>? multi,
  }) async {
    calls.add('$path ${query?['cursor']}');
    if (path == '/v2/my/library/changes') {
      final given = query?['cursor'];
      if (given != null && failCursor != null) {
        throw MangaBakaException('bad cursor', 400);
      }
      return {
        'data': changes(given),
        'pagination': {'limit': 250, 'cursor': cursor, 'more': false},
      };
    }
    final ids = multi!['id']!;
    batches.add(ids);
    return {
      'data': [
        for (final id in ids)
          {
            'id': int.parse(id),
            'title': 'Series $id',
            'description': 'long text',
            'content_rating': 'safe',
          },
      ],
    };
  }
}

MangaBakaLibraryStore store(
  Fake fake,
  Map<String, Map<String, dynamic>> disk,
) => MangaBakaLibraryStore(
  get: fake.get,
  read: () => disk['value'],
  write: (v) => disk['value'] = v,
  erase: disk.clear,
);

void main() {
  test(
    'the first pull reads everything, later pulls only the changes',
    () async {
      final fake = Fake()
        ..changes = (cursor) => cursor == null
            ? [entry(1, 10, 3), entry(2, 20, 5)]
            : [
                entry(1, 10, 4),
                {
                  'type': 'entry',
                  'action': 'delete',
                  'revision': 7,
                  'previous': {'id': 2, 'series_id': 20},
                },
                entry(3, 30, 1),
              ];
      final disk = <String, Map<String, dynamic>>{};
      final lib = store(fake, disk);

      final first = await lib.rows();
      expect(first.map((r) => r['id']), [1, 2]);
      expect(first.first['Series']['title'], 'Series 10');
      expect(first.first['Series'].containsKey('description'), isFalse);
      expect(fake.batches.single, ['10', '20']);

      fake.cursor = 'c2';
      final second = await lib.rows();
      expect(
        fake.calls.where((c) => c.startsWith('/v2')).last,
        '/v2/my/library/changes c1',
      );
      expect(second.map((r) => r['id']), [1, 3]);
      expect(second.first['progress_chapter'], 4);
      expect(fake.batches.last, ['30']);
    },
  );

  test(
    'a restart restores the stored state instead of fetching it again',
    () async {
      final fake = Fake()..changes = (c) => c == null ? [entry(1, 10, 3)] : [];
      final disk = <String, Map<String, dynamic>>{};
      await store(fake, disk).rows();
      fake.batches.clear();

      final again = await store(fake, disk).rows();
      expect(fake.calls.last, '/v2/my/library/changes c1');
      expect(fake.batches, isEmpty);
      expect(again.single['Series']['title'], 'Series 10');
    },
  );

  test('a rejected cursor starts over from a full pull', () async {
    final fake = Fake()..changes = (c) => [entry(1, 10, 3)];
    final disk = <String, Map<String, dynamic>>{};
    final lib = store(fake, disk);
    await lib.rows();

    fake.failCursor = true;
    fake.calls.clear();
    final rows = await lib.rows();
    expect(rows.single['id'], 1);
    expect(fake.calls.first, '/v2/my/library/changes c1');
    expect(fake.calls[1], '/v2/my/library/changes null');
  });
}
