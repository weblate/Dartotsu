import 'package:dartotsu/Api/Services/Anilist/Data/Sanitize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emoji outside the BMP become html entities', () {
    expect(
      anilistSafeText('ah here we go again \u{1FAE9}'),
      'ah here we go again &#129769;',
    );
  });

  test('plain text and BMP symbols are untouched', () {
    expect(anilistSafeText('héllo ★ 日本語'), 'héllo ★ 日本語');
  });
}
