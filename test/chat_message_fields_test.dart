import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

ChatMessage basis({
  ChatChannel? channel,
  String? errorText,
  ChatMessageKind kind = ChatMessageKind.normal,
  ChatTranslation? translation,
  String? headline,
}) =>
    ChatMessage(
      id: 'm1',
      direction: MessageDirection.incoming,
      text: 'Hallo',
      at: DateTime(2026, 7, 30, 10),
      channel: channel,
      errorText: errorText,
      kind: kind,
      translation: translation,
      headline: headline,
    );

void main() {
  test('Standardwerte: kein Kanal, normal, kein Fehler', () {
    final m = basis();
    expect(m.channel, isNull);
    expect(m.kind, ChatMessageKind.normal);
    expect(m.errorText, isNull);
    expect(m.translation, isNull);
    expect(m.headline, isNull);
  });

  test('Felder werden übernommen', () {
    final m = basis(
      channel: const ChatChannel.sms(),
      errorText: 'Zustellung fehlgeschlagen',
      kind: ChatMessageKind.system,
      translation: const ChatTranslation(text: 'Привіт', languageLabel: 'UK'),
      headline: 'Rechnung',
    );
    expect(m.channel, const ChatChannel.sms());
    expect(m.errorText, 'Zustellung fehlgeschlagen');
    expect(m.kind, ChatMessageKind.system);
    expect(m.translation?.text, 'Привіт');
    expect(m.headline, 'Rechnung');
  });

  test('copyWith ersetzt die neuen Felder', () {
    final m = basis().copyWith(
      channel: const ChatChannel.whatsApp(),
      kind: ChatMessageKind.custom,
      headline: 'Betreff',
    );
    expect(m.channel, const ChatChannel.whatsApp());
    expect(m.kind, ChatMessageKind.custom);
    expect(m.headline, 'Betreff');
    expect(m.text, 'Hallo');
  });

  test('Wertgleichheit berücksichtigt die neuen Felder', () {
    expect(basis(channel: const ChatChannel.sms()),
        basis(channel: const ChatChannel.sms()));
    expect(basis(channel: const ChatChannel.sms()) == basis(), isFalse);
    expect(basis(errorText: 'x') == basis(), isFalse);
    expect(basis(kind: ChatMessageKind.system) == basis(), isFalse);
    expect(basis(headline: 'h') == basis(), isFalse);
  });

  test('ChatTranslation: copyWith und Gleichheit', () {
    const t = ChatTranslation(text: 'Hi', languageLabel: 'EN');
    expect(t.copyWith(text: 'Hello').text, 'Hello');
    expect(t.copyWith(text: 'Hello').languageLabel, 'EN');
    expect(t, const ChatTranslation(text: 'Hi', languageLabel: 'EN'));
    expect(t.hashCode,
        const ChatTranslation(text: 'Hi', languageLabel: 'EN').hashCode);
  });
}
