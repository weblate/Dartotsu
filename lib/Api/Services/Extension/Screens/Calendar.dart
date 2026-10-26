import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';

import '../../../../Core/Services/MediaService.dart';
import '../../../../Core/SourceAlerts/SourceAlerts.dart';
import '../../../../Core/SourceAlerts/SourceSchedule.dart';
import '../../../../Core/SourceAlerts/SourceSub.dart';
import '../../../../Core/SourceAlerts/SourceSubscriptions.dart';
import '../../../../Core/State/State.dart';

class ExtensionCalendarView implements CalendarScreenView {
  @override
  Stream<List<CalendarEntry>> schedule() async* {
    final now = DateTime.now().millisecondsSinceEpoch;
    final alerts = find<SourceAlerts>();
    final out = <CalendarEntry>[];
    for (final sub in find<SourceSubscriptions>().subs) {
      if (sub.muted || sub.health == SubHealth.finished) continue;
      final chapter = ItemType.values.asNameMap()[sub.type] != ItemType.anime;
      final media = sub.buildMedia();
      for (final r in subReleases(sub, now)) {
        final value = r.episode;
        out.add(
          CalendarEntry(
            media: media,
            episode: value != null && value == value.truncateToDouble()
                ? value.toInt()
                : null,
            airingAt: DateTime.fromMillisecondsSinceEpoch(r.at),
            expected: r.expected,
            chapter: chapter,
            source: sub.sourceName,
            open: () => alerts.openSub(sub),
          ),
        );
      }
    }
    out.sort((a, b) => a.airingAt.compareTo(b.airingAt));
    yield out;
  }
}
