import 'package:dartotsu/Screen/Reader/Engine/ReaderSettings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auto mode follows the series type', () {
    expect(autoReaderMode(format: 'MANGA', country: 'JP'), 'rtl');
    expect(autoReaderMode(format: 'MANHWA'), 'webtoon');
    expect(autoReaderMode(format: 'MANHUA'), 'webtoon');
    expect(autoReaderMode(format: 'MANGA', country: 'KR'), 'webtoon');
    expect(autoReaderMode(), 'rtl');
  });

  test('auto resolves through effectiveMode and survives copy', () {
    final s = ReaderSettings({'mode': 'auto'}, 'webtoon');
    expect(s.scrolls, isTrue);
    expect(s.copy().scrolls, isTrue);
    expect(s.merged({'mode': 'ltr'}).scrolls, isFalse);
    expect(ReaderSettings({'mode': 'auto'}).reversed, isTrue);
  });
}
