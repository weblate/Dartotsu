import '../../Core/Services/Model/Media.dart';

const _logo =
    'https://cdn.discordapp.com/emojis/1305525420938100787.gif?size=128&animated=true&name=dartotsu';
const _repo = 'https://github.com/aayush2622/Dartotsu';

class PresenceStyle {
  final bool images;
  final bool buttons;
  final bool timer;
  final bool hideTitles;
  final String activity;

  const PresenceStyle({
    this.images = true,
    this.buttons = true,
    this.timer = true,
    this.hideTitles = false,
    this.activity = 'auto',
  });
}

enum PresenceType {
  playing(0),
  listening(2),
  watching(3);

  final int code;

  const PresenceType(this.code);
}

class PresenceButton {
  final String label;
  final String url;

  const PresenceButton(this.label, this.url);

  @override
  bool operator ==(Object other) =>
      other is PresenceButton && other.label == label && other.url == url;

  @override
  int get hashCode => Object.hash(label, url);
}

class DiscordPresence {
  static final _session = DateTime.now().millisecondsSinceEpoch;

  final PresenceType type;
  final String name;
  final String details;
  final String? state;
  final String? largeImage;
  final String? largeText;
  final String? smallImage;
  final String? smallText;
  final int? start;
  final int? end;
  final bool live;
  final bool sensitive;
  final List<PresenceButton> buttons;

  const DiscordPresence({
    this.type = PresenceType.playing,
    this.name = 'Dartotsu',
    required this.details,
    this.state,
    this.largeImage = _logo,
    this.largeText,
    this.smallImage,
    this.smallText,
    this.start,
    this.end,
    this.live = false,
    this.sensitive = false,
    this.buttons = const [PresenceButton('Open Dartotsu', _repo)],
  });

  factory DiscordPresence.browsing(String details, {String? state}) =>
      DiscordPresence(
        details: details,
        state: state,
        largeText: 'Dartotsu',
        start: _session,
      );

  factory DiscordPresence.viewing(Media media) => DiscordPresence(
    sensitive: true,
    details: media.mainName,
    state: media.isAnime ? 'Viewing an anime' : 'Viewing a manga',
    largeImage: media.cover ?? _logo,
    largeText: media.mainName,
    smallImage: _logo,
    smallText: 'Dartotsu',
    start: _session,
    buttons: [
      if (media.shareLink.startsWith('http'))
        PresenceButton(
          media.isAnime ? 'View anime' : 'View manga',
          media.shareLink,
        ),
      const PresenceButton('Open Dartotsu', _repo),
    ],
  );

  factory DiscordPresence.reading(
    Media media, {
    required String number,
    required int since,
    int? total,
  }) => DiscordPresence(
    type: PresenceType.watching,
    sensitive: true,
    details: media.mainName,
    state: 'Chapter $number/${total ?? '?'}',
    largeImage: media.cover ?? _logo,
    largeText: media.mainName,
    smallImage: _logo,
    smallText: 'Dartotsu',
    start: since,
    live: true,
    buttons: [
      if (media.shareLink.startsWith('http'))
        PresenceButton(
          'View ${media.format?.toLowerCase() == 'novel' ? 'novel' : 'manga'}',
          media.shareLink,
        ),
      const PresenceButton('Open Dartotsu', _repo),
    ],
  );

  factory DiscordPresence.consuming(
    Media media, {
    required num number,
    int? total,
    String? thumbnail,
    int positionSeconds = 0,
    int? durationSeconds,
    int? anchorMs,
    double rate = 1,
    bool paused = false,
  }) {
    final at = anchorMs ?? DateTime.now().millisecondsSinceEpoch;
    final speed = rate <= 0 ? 1.0 : rate;
    final start = (at - positionSeconds * 1000 / speed).round();
    final unit = media.isAnime ? 'Episode' : 'Chapter';
    final count = '$unit $number/${total ?? '?'}';
    return DiscordPresence(
      type: media.isAnime ? PresenceType.watching : PresenceType.playing,
      sensitive: true,
      details: media.mainName,
      state: paused ? '$count • Paused at ${_clock(positionSeconds)}' : count,
      largeImage: thumbnail ?? media.cover ?? _logo,
      largeText: media.mainName,
      smallImage: _logo,
      smallText: paused ? 'Paused' : 'Dartotsu',
      start: paused ? null : start,
      end: paused || durationSeconds == null
          ? null
          : (start + durationSeconds * 1000 / speed).round(),
      live: !paused,
      buttons: [
        if (media.shareLink.startsWith('http'))
          PresenceButton(
            media.isAnime ? 'View anime' : 'View manga',
            media.shareLink,
          ),
        const PresenceButton('Open Dartotsu', _repo),
      ],
    );
  }

  static String _clock(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600 ~/ 60).toString().padLeft(h > 0 ? 2 : 1, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  DiscordPresence shifted(Duration by) {
    if (!live || by == Duration.zero) return this;
    return DiscordPresence(
      type: type,
      name: name,
      details: details,
      state: state,
      largeImage: largeImage,
      largeText: largeText,
      smallImage: smallImage,
      smallText: smallText,
      start: start == null ? null : start! + by.inMilliseconds,
      end: end == null ? null : end! + by.inMilliseconds,
      live: live,
      sensitive: sensitive,
      buttons: buttons,
    );
  }

  DiscordPresence styled(PresenceStyle style) {
    final hide = style.hideTitles && sensitive;
    return DiscordPresence(
      type: switch (style.activity) {
        'playing' => PresenceType.playing,
        'watching' => PresenceType.watching,
        _ => type,
      },
      name: name,
      details: hide ? 'Something private' : details,
      state: hide ? null : state,
      largeImage: style.images && !hide ? largeImage : null,
      largeText: hide ? null : largeText,
      smallImage: style.images ? smallImage : null,
      smallText: style.images ? smallText : null,
      start: style.timer ? start : null,
      end: style.timer ? end : null,
      live: live,
      sensitive: sensitive,
      buttons: style.buttons && !hide ? buttons : const [],
    );
  }

  bool get isBrowsing => !live;

  @override
  bool operator ==(Object other) =>
      other is DiscordPresence &&
      other.type == type &&
      other.name == name &&
      other.details == details &&
      other.state == state &&
      other.largeImage == largeImage &&
      other.largeText == largeText &&
      other.smallImage == smallImage &&
      other.smallText == smallText &&
      other.start == start &&
      other.end == end &&
      other.live == live &&
      other.sensitive == sensitive &&
      _same(other.buttons, buttons);

  static bool _same(List<PresenceButton> a, List<PresenceButton> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    type,
    name,
    details,
    state,
    largeImage,
    largeText,
    smallImage,
    smallText,
    start,
    end,
    live,
    sensitive,
    Object.hashAll(buttons),
  );
}
