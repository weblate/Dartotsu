import '../../../Logger.dart';
import 'Auth.dart';
import 'Data/Mapper.dart';
import 'Client.dart';

typedef MangaBakaIds = ({int id, int? anilist, int? mal});

Future<MangaBakaIds?> mangaBakaIdsFor({int? anilist, int? mal}) async {
  final lookups = [
    if (mal != null) 'my-anime-list/$mal',
    if (anilist != null) 'anilist/$anilist',
  ];
  for (final path in lookups) {
    try {
      final body = await mangaBakaAuth.client.get('/source/$path');
      final series = (body['data'] as Map?)?['series'];
      final first = series is List && series.isNotEmpty ? series.first : null;
      if (first is! Map) continue;
      final media = mapMangaBakaSeries(first.cast<String, dynamic>());
      final id = int.tryParse(media.id);
      if (id == null) continue;
      final extras = mangaBakaExtras[media];
      return (id: id, anilist: extras?.anilistId, mal: extras?.malId);
    } on MangaBakaException catch (e) {
      if (e.status != 404) {
        logger('MangaBaka id lookup failed: $e', tag: 'WATCH');
      }
    }
  }
  return null;
}
