import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  group('isPhoneNumberLike', () {
    test('recognizes phone numbers', () {
      expect(isPhoneNumberLike('+436600000000'), isTrue);
      expect(isPhoneNumberLike('+43 660 0000000'), isTrue);
      expect(isPhoneNumberLike('0660 / 20 23 428'), isTrue);
    });

    test('rejects names and short strings', () {
      expect(isPhoneNumberLike('Ada Lovelace'), isFalse);
      expect(isPhoneNumberLike('Firma 3'), isFalse);
      expect(isPhoneNumberLike('12345'), isFalse); // too few digits
      expect(isPhoneNumberLike(''), isFalse);
    });
  });

  testWidgets('phone-number contact shows a person icon, not "+"',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatAvatar(name: '+436600000000', theme: ChatTheme.light()),
      ),
    ));
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('+'), findsNothing);
  });

  testWidgets('named contact shows initials monogram', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatAvatar(name: 'Ada Lovelace', theme: ChatTheme.light()),
      ),
    ));
    expect(find.text('AL'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNothing);
  });
}
