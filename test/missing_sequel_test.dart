import 'dart:convert';

import 'package:dartotsu/Api/Services/Anilist/Queries.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> entry(String status, int id, List<List<Object>> edges) => {
  'status': status,
  'media': {
    'id': id,
    'relations': {
      'edges': [
        for (final e in edges)
          {
            'relationType': e[0],
            'node': {'id': e[1], 'type': e[2]},
          },
      ],
    },
  },
};

void main() {
  test('only sequels of completed anime count and owned ones are known', () {
    final body = jsonEncode({
      'data': {
        'MediaListCollection': {
          'hasNextChunk': true,
          'lists': [
            {
              'entries': [
                entry('COMPLETED', 1, [
                  ['SEQUEL', 2, 'ANIME'],
                  ['PREQUEL', 9, 'ANIME'],
                  ['ADAPTATION', 3, 'MANGA'],
                  ['SEQUEL', 4, 'MANGA'],
                ]),
                entry('DROPPED', 5, [
                  ['SEQUEL', 6, 'ANIME'],
                ]),
                entry('PLANNING', 2, const []),
              ],
            },
          ],
        },
      },
    });
    final result = parseSequelOwnership(body);
    expect(result.owned, {1, 5, 2});
    expect(result.sequels, {2});
    expect(result.hasNext, isTrue);
  });
}
