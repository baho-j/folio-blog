import 'package:flutter_test/flutter_test.dart';
import 'package:folio/util/search_query.dart';

void main() {
  group('likePattern', () {
    test('wraps the text in wildcards', () {
      expect(likePattern('lake'), '%lake%');
    });

    test('trims surrounding spaces', () {
      expect(likePattern('  lake  '), '%lake%');
    });

    test('escapes the percent sign', () {
      expect(likePattern('100%'), r'%100\%%');
    });

    test('escapes the underscore', () {
      expect(likePattern('a_b'), r'%a\_b%');
    });

    test('escapes the escape character itself', () {
      expect(likePattern(r'a\b'), r'%a\\b%');
    });
  });

  group('splitMatches', () {
    test('marks a match in the middle of the text', () {
      expect(splitMatches('the lake is calm', 'lake'), [
        (text: 'the ', isMatch: false),
        (text: 'lake', isMatch: true),
        (text: ' is calm', isMatch: false),
      ]);
    });

    test('ignores case and keeps the original letters', () {
      expect(splitMatches('LAKE', 'lake'), [(text: 'LAKE', isMatch: true)]);
    });

    test('marks every occurrence', () {
      final matches = splitMatches('a b a', 'a').where((part) => part.isMatch);
      expect(matches, hasLength(2));
    });

    test('returns the whole text when nothing matches', () {
      expect(splitMatches('calm', 'lake'), [(text: 'calm', isMatch: false)]);
    });

    test('returns the whole text for an empty query', () {
      expect(splitMatches('calm', '  '), [(text: 'calm', isMatch: false)]);
    });

    test('rebuilds the original text exactly', () {
      final parts = splitMatches('Lake, lake and LAKE.', 'lake');
      expect(parts.map((part) => part.text).join(), 'Lake, lake and LAKE.');
    });
  });

  group('excerptAround', () {
    test('leaves a match near the start alone', () {
      expect(excerptAround('the lake is calm', 'lake'), 'the lake is calm');
    });

    test('moves a late match into view on a word boundary', () {
      final text = '${'word ' * 20}target ends here';
      final excerpt = excerptAround(text, 'target');
      expect(excerpt, startsWith('…'));
      expect(excerpt, contains('target'));
      expect(excerpt.length, lessThan(text.length));
    });

    test('returns the text when nothing matches', () {
      expect(excerptAround('calm', 'lake'), 'calm');
    });
  });
}
