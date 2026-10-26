import 'dart:convert';
import 'dart:io';

import 'package:dartotsu/Screen/Together/TogetherStream.dart';
import 'package:dartotsu_extension_bridge/Models/Video.dart' as v;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a shared stream round trips and keeps its id', () {
    final stream = TogetherStream.from(
      'Show - 1',
      v.Video('720p', 'https://cdn.example.com/a.m3u8', '720p'),
    )!;
    final back = TogetherStream.decode(stream.encode())!;
    expect(back.id, stream.id);
    expect(back.video.url, 'https://cdn.example.com/a.m3u8');
  });

  test('a payload whose id does not match its url is refused', () {
    final good = TogetherStream.from(
      'Show - 1',
      v.Video('720p', 'https://cdn.example.com/a.m3u8', '720p'),
    )!;
    final forged = base64Url.encode(
      gzip.encode(
        utf8.encode(
          jsonEncode({
            'i': good.id,
            'n': 'Show - 1',
            'v': {
              'title': '720p',
              'url': 'https://evil.example.com/b.m3u8',
              'quality': '720p',
              'headers': null,
              'subtitles': null,
              'audios': null,
            },
          }),
        ),
      ),
    );
    expect(TogetherStream.decode(forged), isNull);
  });

  test('local and private addresses are not shareable', () {
    expect(TogetherStream.shareable('http://192.168.1.5/a.mp4'), isFalse);
    expect(TogetherStream.shareable('https://example.com/a.mp4'), isTrue);
  });
}
