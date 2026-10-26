import 'dart:async';

import '../../Api/Discord/DiscordPresence.dart';
import '../../Core/Services/MediaServiceController.dart';
import '../../Core/State/State.dart';
import '../../Core/ThemeManager/LanguageSwitcher.dart';
import '../../Widgets/Components/ScreenState.dart';

class CalendarState extends ScreenState {
  final CalendarScreenView view;

  CalendarState(this.view);

  final entries = <CalendarEntry>[].liveList;
  final loading = true.live;
  final failed = false.live;
  final day = 0.live;

  static DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  final today = dayOf(DateTime.now());

  StreamSubscription<List<CalendarEntry>>? _sub;

  MediaService get service =>
      find<MediaServiceController>().currentService.value;

  DateTime _day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  List<DateTime> get days => [for (var i = -1; i <= 5; i++) _day(i)];

  List<CalendarEntry> get selectedEntries {
    final selected = _day(day.value);
    return [
      for (final e in entries)
        if (dayOf(e.airingAt) == selected) e,
    ];
  }

  DiscordPresence get presence =>
      DiscordPresence.browsing(getString.calendarTitle);

  @override
  void onInit() => unawaited(load());

  Future<void> load() async {
    await _sub?.cancel();
    loading.value = true;
    failed.value = false;
    final done = Completer<void>();
    _sub = view.schedule().listen(
      (list) {
        entries.value = list;
        loading.value = false;
      },
      onError: (_) {
        failed.value = entries.isEmpty;
        loading.value = false;
        if (!done.isCompleted) done.complete();
      },
      onDone: () {
        loading.value = false;
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
  }

  @override
  void onClose() => unawaited(_sub?.cancel());
}
