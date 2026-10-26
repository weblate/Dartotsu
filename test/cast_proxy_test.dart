import 'dart:convert';
import 'dart:io';

import 'package:dartotsu/Core/Cast/CastProxy.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(int, Map<String, String>, String)> fetch(String url) async {
  final client = HttpClient();
  final uri = Uri.parse(url).replace(host: '127.0.0.1');
  final reply = await (await client.getUrl(uri)).close();
  final body = await reply.transform(utf8.decoder).join();
  final headers = <String, String>{};
  reply.headers.forEach((k, v) => headers[k] = v.join(','));
  client.close(force: true);
  return (reply.statusCode, headers, body);
}

void main() {
  late HttpServer upstream;
  late String origin;
  late CastProxy proxy;

  const media =
      '#EXTM3U\n#EXT-X-TARGETDURATION:4\n#EXTINF:4,\nseg1.jpg\n'
      '#EXTINF:4,\nseg2.jpg\n#EXT-X-ENDLIST\n';
  const master =
      '#EXTM3U\n'
      '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="a",NAME="en",URI="audio.m3u8"\n'
      '#EXT-X-STREAM-INF:BANDWIDTH=800000,AUDIO="a"\nvideo.m3u8\n'
      '#EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=1,URI="iframe.m3u8"\n';

  setUp(() async {
    upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    origin = 'http://127.0.0.1:${upstream.port}';
    upstream.listen((request) async {
      final path = request.uri.path;
      final response = request.response;
      if (path == '/proxied/media') {
        response.headers.contentType = ContentType('text', 'plain');
        response.write(media);
      } else if (path == '/proxied/master') {
        response.headers.contentType = ContentType('application', 'x-mpegurl');
        response.write(master);
      } else if (path == '/video.webm') {
        response.headers.contentType = ContentType('video', 'webm');
        response.write('webm');
      } else if (path.endsWith('.jpg')) {
        response.headers.contentType = ContentType('image', 'jpeg');
        response.write('ts');
      } else if (path.endsWith('.m3u8')) {
        response.write(media);
      } else {
        response.statusCode = 404;
      }
      await response.close();
    });
    proxy = CastProxy();
  });

  tearDown(() async {
    await proxy.stop();
    await upstream.close(force: true);
  });

  test('a playlist behind a url without m3u8 is served as HLS', () async {
    await proxy.start(video: '$origin/proxied/media');
    expect(proxy.isHls, isTrue);
    expect(proxy.contentType, 'application/x-mpegURL');
    expect(proxy.videoUrl, endsWith('/hls/master.m3u8'));
    final (status, _, body) = await fetch(proxy.videoUrl!);
    expect(status, 200);
    final lines = body.split('\n').where((l) => !l.startsWith('#')).toList();
    expect(lines, hasLength(2));
    expect(lines.every((l) => l.contains('/hls/segment?url=')), isTrue);
    expect(body.contains('variant.m3u8'), isFalse);
  });

  test('segments with an image type are served as video', () async {
    await proxy.start(video: '$origin/proxied/media');
    final (_, _, body) = await fetch(proxy.videoUrl!);
    final segment = body
        .split('\n')
        .firstWhere((l) => l.contains('/hls/segment'));
    final (status, headers, _) = await fetch(segment);
    expect(status, 200);
    expect(headers['content-type'], startsWith('video/mp2t'));
  });

  test('a master playlist routes audio renditions through the proxy', () async {
    await proxy.start(video: '$origin/proxied/master');
    final (_, _, body) = await fetch(proxy.videoUrl!);
    final media = body
        .split('\n')
        .firstWhere((l) => l.startsWith('#EXT-X-MEDIA'));
    expect(media, contains('/hls/variant.m3u8?url='));
    expect(body.contains('I-FRAME'), isFalse);
    final variants = body
        .split('\n')
        .where((l) => l.startsWith('http'))
        .toList();
    expect(variants.single, contains('/hls/variant.m3u8?url='));
  });

  test('a plain file keeps its real type', () async {
    await proxy.start(video: '$origin/video.webm');
    expect(proxy.isHls, isFalse);
    expect(proxy.contentType, 'video/webm');
    final (status, headers, body) = await fetch(proxy.videoUrl!);
    expect(status, 200);
    expect(headers['content-type'], startsWith('video/webm'));
    expect(body, 'webm');
  });
}
