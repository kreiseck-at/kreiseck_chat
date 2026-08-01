import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  group('registrableDomain', () {
    test('reduziert auf das, was man liest', () {
      expect(registrableDomain('mail.bank.at'), 'bank.at');
      expect(registrableDomain('www.bank.at'), 'bank.at');
      expect(registrableDomain('bank.at'), 'bank.at');
      expect(registrableDomain('localhost'), 'localhost');
      expect(registrableDomain(''), '');
    });
  });

  group('linkLooksDisguised', () {
    test('Text behauptet eine andere Domain als das Ziel', () {
      expect(
        linkLooksDisguised('bank.at', Uri.parse('https://bank.at.evil.tld/x')),
        isTrue,
      );
      expect(
        linkLooksDisguised(
            'https://paypal.com/login', Uri.parse('https://evil.tld/p')),
        isTrue,
      );
    });

    test('gleiche Domain ist keine Verkleidung', () {
      expect(linkLooksDisguised('bank.at', Uri.parse('https://bank.at/x')),
          isFalse);
      // Unterdomäne derselben Domain ebenfalls nicht.
      expect(
        linkLooksDisguised('bank.at', Uri.parse('https://mail.bank.at/x')),
        isFalse,
      );
      expect(
        linkLooksDisguised('www.bank.at', Uri.parse('https://bank.at/')),
        isFalse,
      );
    });

    test('Text ohne Domain widerspricht nichts', () {
      expect(linkLooksDisguised('hier klicken', Uri.parse('https://x.at')),
          isFalse);
      expect(linkLooksDisguised('', Uri.parse('https://x.at')), isFalse);
      expect(linkLooksDisguised(null, Uri.parse('https://x.at')), isFalse);
    });

    test('Ziel ohne Host ist keine Aussage', () {
      expect(linkLooksDisguised('bank.at', Uri.parse('mailto:a@b.at')), isFalse);
    });
  });
}
