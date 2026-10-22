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
    expect(
        basis(
                translation:
                    const ChatTranslation(text: 'Hi', languageLabel: 'EN')) ==
            basis(),
        isFalse);
  });

  test('ChatTranslation: copyWith und Gleichheit', () {
    const t = ChatTranslation(text: 'Hi', languageLabel: 'EN');
    expect(t.copyWith(text: 'Hello').text, 'Hello');
    expect(t.copyWith(text: 'Hello').languageLabel, 'EN');
    expect(t, const ChatTranslation(text: 'Hi', languageLabel: 'EN'));
    expect(t.hashCode,
        const ChatTranslation(text: 'Hi', languageLabel: 'EN').hashCode);
  });

  test('clearErrorText leert, ein normaler Aufruf behält', () {
    final mitFehler = basis(errorText: 'Grund');
    expect(mitFehler.copyWith(clearErrorText: true).errorText, isNull);
    // Der Regressionsfall: ohne clear bleibt der Wert stehen.
    expect(mitFehler.copyWith(status: MessageStatus.sent).errorText, 'Grund');
  });

  test('jedes nullable Feld von ChatMessage lässt sich leeren', () {
    final voll = ChatMessage(
      id: 'm1',
      direction: MessageDirection.outgoing,
      text: 'Hallo',
      at: DateTime(2026, 7, 31, 10),
      sender: const ChatParticipant(id: 'a', displayName: 'Ada'),
      replyTo: const ChatMessageRef(id: 'x', snippet: 'y'),
      editedAt: DateTime(2026, 7, 31, 11),
      deliveredAt: DateTime(2026, 7, 31, 12),
      readAt: DateTime(2026, 7, 31, 13),
      channel: const ChatChannel.sms(),
      errorText: 'Grund',
      translation: const ChatTranslation(text: 'Hi', languageLabel: 'EN'),
      headline: 'Betreff',
    );
    final leer = voll.copyWith(
      clearSender: true,
      clearReplyTo: true,
      clearEditedAt: true,
      clearDeliveredAt: true,
      clearReadAt: true,
      clearChannel: true,
      clearErrorText: true,
      clearTranslation: true,
      clearHeadline: true,
    );
    expect(leer.sender, isNull);
    expect(leer.replyTo, isNull);
    expect(leer.editedAt, isNull);
    expect(leer.deliveredAt, isNull);
    expect(leer.readAt, isNull);
    expect(leer.channel, isNull);
    expect(leer.errorText, isNull);
    expect(leer.translation, isNull);
    expect(leer.headline, isNull);
    // Nicht-nullable Felder bleiben unangetastet.
    expect(leer.id, 'm1');
    expect(leer.text, 'Hallo');
  });

  test('clear zusammen mit einem Wert ist ein Programmierfehler', () {
    expect(
      () => basis().copyWith(errorText: 'x', clearErrorText: true),
      throwsAssertionError,
    );
  });

  test('clearHeadline behält headline und channel bei einem normalen Aufruf',
      () {
    final mitHeadline = basis(
      channel: const ChatChannel.sms(),
      headline: 'Betreff',
    );
    expect(mitHeadline.copyWith(clearHeadline: true).headline, isNull);
    // Der Regressionsfall: ohne clear bleiben headline und channel stehen.
    final unveraendert = mitHeadline.copyWith(status: MessageStatus.sent);
    expect(unveraendert.headline, 'Betreff');
    expect(unveraendert.channel, const ChatChannel.sms());
  });

  test('transcriptState: Standard null, copyWith setzt und leert', () {
    final m = basis();
    expect(m.transcriptState, isNull);
    final mit = m.copyWith(transcriptState: ChatTranscriptState.pending);
    expect(mit.transcriptState, ChatTranscriptState.pending);
    expect(mit.copyWith(text: 'x').transcriptState, ChatTranscriptState.pending);
    expect(mit.copyWith(clearTranscriptState: true).transcriptState, isNull);
    expect(
      () => mit.copyWith(
        transcriptState: ChatTranscriptState.done,
        clearTranscriptState: true,
      ),
      throwsAssertionError,
    );
  });

  test('transcriptState zählt bei == und hashCode', () {
    final a = basis().copyWith(transcriptState: ChatTranscriptState.done);
    final b = basis().copyWith(transcriptState: ChatTranscriptState.done);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == basis(), isFalse);
    expect(
        a == basis().copyWith(transcriptState: ChatTranscriptState.pending),
        isFalse);
  });
}
