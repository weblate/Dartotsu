import 'dart:io';

import 'package:dartotsu/Screen/Player/Engine/Mpris.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHost implements MprisHost {
  final calls = <String>[];
  @override
  String status = 'Paused';
  @override
  double rate = 1;
  @override
  Duration position = const Duration(seconds: 30);
  @override
  Duration length = const Duration(minutes: 24);
  @override
  String title = 'Episode 3';
  @override
  String? album = 'Some Show';
  @override
  String? art = 'https://example.com/a.jpg';
  @override
  int trackIndex = 2;
  @override
  bool hasNext = true;
  @override
  bool hasPrevious = false;

  @override
  Future<void> play() async {
    calls.add('play');
    status = 'Playing';
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    status = 'Paused';
  }

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<void> next() async => calls.add('next');

  @override
  Future<void> previous() async => calls.add('previous');

  @override
  Future<void> seekBy(Duration by) async => calls.add('seekBy ${by.inSeconds}');

  @override
  Future<void> seekTo(Duration to) async => calls.add('seekTo ${to.inSeconds}');

  @override
  Future<void> setRate(double value) async => rate = value;
}

void main() {
  final hasBus =
      Platform.isLinux &&
      (Platform.environment['DBUS_SESSION_BUS_ADDRESS'] ?? '').isNotEmpty;

  test(
    'players and media keys can read and control the player over D-Bus',
    () async {
      final host = FakeHost();
      final service = MprisService(
        host,
        busName: 'org.mpris.MediaPlayer2.dartotsu_test',
      );
      await service.start();
      expect(service.active, isTrue);
      final client = DBusClient.session();
      final remote = DBusRemoteObject(
        client,
        name: 'org.mpris.MediaPlayer2.dartotsu_test',
        path: DBusObjectPath('/org/mpris/MediaPlayer2'),
      );
      const player = 'org.mpris.MediaPlayer2.Player';
      try {
        final identity = await remote.getProperty(
          'org.mpris.MediaPlayer2',
          'Identity',
        );
        expect(identity.asString(), 'Dartotsu');
        expect(
          (await remote.getProperty(player, 'PlaybackStatus')).asString(),
          'Paused',
        );
        expect(
          (await remote.getProperty(player, 'Position')).asInt64(),
          30 * 1000000,
        );
        final metadata = (await remote.getProperty(
          player,
          'Metadata',
        )).asStringVariantDict();
        expect(metadata['xesam:title']!.asString(), 'Episode 3');
        expect(metadata['mpris:length']!.asInt64(), 24 * 60 * 1000000);
        expect(metadata['xesam:artist']!.asStringArray().toList(), [
          'Some Show',
        ]);
        expect(
          (await remote.getProperty(player, 'CanGoNext')).asBoolean(),
          isTrue,
        );
        expect(
          (await remote.getProperty(player, 'CanGoPrevious')).asBoolean(),
          isFalse,
        );

        await remote.callMethod(
          player,
          'PlayPause',
          [],
          replySignature: DBusSignature(''),
        );
        await remote.callMethod(
          player,
          'Next',
          [],
          replySignature: DBusSignature(''),
        );
        await remote.callMethod(player, 'Seek', [
          const DBusInt64(10 * 1000000),
        ], replySignature: DBusSignature(''));
        await remote.callMethod(player, 'SetPosition', [
          DBusObjectPath('/org/dartotsu/track/2'),
          const DBusInt64(60 * 1000000),
        ], replySignature: DBusSignature(''));
        expect(host.calls, ['play', 'next', 'seekBy 10', 'seekTo 60']);
        expect(host.status, 'Playing');
      } finally {
        await client.close();
        await service.dispose();
      }
    },
    skip: hasBus ? false : 'needs a D-Bus session bus',
  );
}
