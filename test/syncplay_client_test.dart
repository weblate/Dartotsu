import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartotsu/Screen/Together/SyncplayClient.dart';
import 'package:dartotsu/Screen/Together/TogetherBackend.dart';
import 'package:dartotsu/Screen/Together/TogetherStream.dart';
import 'package:dartotsu_extension_bridge/Models/Video.dart' as v;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ServerSocket server;
  late Socket peer;
  late Stream<Map<String, dynamic>> incoming;
  late SyncplayClient client;

  setUp(() async {
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = Completer<Socket>();
    server.listen(accepted.complete);
    client = SyncplayClient();
    await client.connect(
      server: '127.0.0.1:${server.port}',
      room: 'room-1',
      name: 'ann',
      password: 'pw',
    );
    peer = await accepted.future;
    incoming = peer
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((l) => jsonDecode(l) as Map<String, dynamic>)
        .asBroadcastStream();
  });

  tearDown(() async {
    await client.close();
    peer.destroy();
    await server.close();
  });

  void say(Map<String, dynamic> m) =>
      peer.add(utf8.encode('${jsonEncode(m)}\r\n'));

  test('hello carries the room, hashed password and versions', () async {
    final hello = (await incoming.first)['Hello'] as Map;
    expect(hello['username'], 'ann');
    expect(hello['room'], {'name': 'room-1'});
    expect(hello['password'], SyncplayClient.hashPassword('pw'));
    expect(hello['password'], '8fe4c11451281c094a6578e6ddbf5eed');
    expect(hello['version'], SyncplayClient.protocolVersion);
  });

  test('server hello connects and asks for the user list', () async {
    final connected = client.events.firstWhere((e) => e is TogetherConnected);
    final listed = incoming.firstWhere((m) => m.containsKey('List'));
    say({
      'Hello': {'username': 'ann', 'motd': 'hi'},
    });
    expect(((await connected) as TogetherConnected).motd, 'hi');
    expect((await listed)['List'], isNull);
  });

  test('parses states, users, readiness and chat', () async {
    final seen = <TogetherEvent>[];
    client.events.listen(seen.add);
    say({
      'Hello': {'username': 'ann'},
    });
    say({
      'List': {
        'room-1': {
          'ann': {'file': {}, 'isReady': false, 'controller': false},
          'bob': {
            'file': {'name': 'ep1.mkv', 'duration': 1400.5, 'size': 9},
            'isReady': true,
            'controller': false,
          },
        },
        'other-room': {
          'eve': {'file': {}},
        },
      },
    });
    say({
      'State': {
        'playstate': {
          'position': 61.5,
          'paused': true,
          'doSeek': true,
          'setBy': 'bob',
        },
        'ping': {'latencyCalculation': 5.0},
      },
    });
    say({
      'Set': {
        'ready': {'username': 'bob', 'isReady': false},
      },
    });
    say({
      'Chat': {'username': 'bob', 'message': 'hey'},
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final users = seen.whereType<TogetherUsers>().single.users;
    expect(users.map((u) => u.name), ['ann', 'bob']);
    expect(users.last.ready, isTrue);
    expect(users.last.file.duration, 1400.5);
    final play = seen.whereType<TogetherPlaystate>().single;
    expect(
      [play.position, play.paused, play.doSeek, play.setBy],
      [61.5, true, true, 'bob'],
    );
    expect(seen.whereType<TogetherReady>().single.ready, isFalse);
    expect(seen.whereType<TogetherChat>().single.message, 'hey');
  });

  test('sends state, file, ready and chat frames', () async {
    final frames = <Map<String, dynamic>>[];
    incoming.listen(frames.add);
    client.sendState(12.5, false, seek: true, local: true);
    client.setFile('ep1.mkv', 1400.0);
    client.setReady(true);
    client.chat('hello');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final state =
        frames.firstWhere((f) => f.containsKey('State'))['State'] as Map;
    expect(state['playstate'], {
      'position': 12.5,
      'paused': false,
      'doSeek': true,
    });
    expect((state['ignoringOnTheFly'] as Map)['client'], 1);
    expect(client.awaitingEcho, isTrue);
    expect(frames.any((f) => (f['Set'] as Map?)?['file'] != null), isTrue);
    expect(
      frames.any(
        (f) => ((f['Set'] as Map?)?['ready'] as Map?)?['isReady'] == true,
      ),
      isTrue,
    );
    expect(frames.any((f) => f['Chat'] == 'hello'), isTrue);
  });

  test('a server echo of the client counter clears the pending flag', () async {
    say({
      'Hello': {'username': 'ann'},
    });
    client.sendState(1, true, local: true);
    expect(client.awaitingEcho, isTrue);
    say({
      'State': {
        'ignoringOnTheFly': {'client': 1},
      },
    });
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(client.awaitingEcho, isFalse);
  });

  test(
    'the host tag travels inside the file name and is split back out',
    () async {
      const tag = TogetherTag(host: true, id: 'a1b2c3d4');
      client.setFile('Show - Episode 5', 1400.0, tag: tag);
      final file =
          ((await incoming.firstWhere((m) => m.containsKey('Set')))['Set']
                  as Map)['file']
              as Map;
      final parsed = TogetherFile.fromJson(file);
      expect(parsed.name, 'Show - Episode 5');
      expect(parsed.tag!.host, isTrue);
      expect(parsed.tag!.id, 'a1b2c3d4');
      expect(TogetherFile.fromJson({'name': 'plain.mkv'}).tag, isNull);
    },
  );

  test('a stream with headers and soft subs survives encode and decode', () {
    final video = v.Video(
      'Sub',
      'https://cdn.example/v.m3u8?x=a|b]c',
      '1080p',
      headers: {'Referer': 'https://site.example'},
      subtitles: [
        v.Track(file: 'https://cdn.example/en.vtt', label: 'English'),
        v.Track(file: '/home/me/local.srt', label: 'Local'),
      ],
      audios: [v.Track(file: 'https://cdn.example/ja.m4a', label: 'Japanese')],
    );
    final stream = TogetherStream.from('Show - 5', video)!;
    final back = TogetherStream.decode(stream.encode())!;
    expect(back.id, TogetherStream.idOf(video.url));
    expect(back.name, 'Show - 5');
    expect(back.video.url, video.url);
    expect(back.video.headers, {'Referer': 'https://site.example'});
    expect(back.video.subtitles!.map((t) => t.label), ['English']);
    expect(back.video.audios!.single.label, 'Japanese');
    expect(
      TogetherStream.from('x', v.Video('', 'http://127.0.0.1:8090/s', '')),
      isNull,
    );
    expect(
      TogetherStream.from(
        'x',
        v.Video('', 'magnet:?xt=urn:btih:abc&dn=Show', 'Torrent'),
      ),
      isNotNull,
    );
  });

  test('a payload is split over chat lines and reassembled', () async {
    final payload = List.generate(60, (i) => 'abcdefghij').join();
    final got = client.events.firstWhere((e) => e is TogetherData);
    final chats = <TogetherEvent>[];
    final sub = client.events.where((e) => e is TogetherChat).listen(chats.add);
    final parts = (payload.length / 110).ceil();
    for (var i = parts - 1; i >= 0; i--) {
      final end = (i + 1) * 110 > payload.length
          ? payload.length
          : (i + 1) * 110;
      say({
        'Chat': {
          'username': 'bob',
          'message': '~dt1|ff|$i|$parts|${payload.substring(i * 110, end)}',
        },
      });
    }
    final data = (await got) as TogetherData;
    expect(data.user, 'bob');
    expect(data.payload, payload);
    await sub.cancel();
    expect(chats, isEmpty);
  });
}
