import 'package:flutter/widgets.dart';

/// The words the package puts on screen.
///
/// Built like [ChatColors] and [ChatTypography]: one field per string, a
/// `const` preset per language, and `copyWith` to adjust single entries. The
/// widgets resolve it through [ChatStrings.of], so a host that already sets
/// its app locale gets the right language without passing anything.
@immutable
class ChatStrings {
  /// Creates a string set explicitly. Prefer one of the language presets.
  const ChatStrings({
    required this.reply,
    required this.copy,
    required this.original,
    required this.retry,
    required this.today,
    required this.yesterday,
    required this.messageHint,
    required this.send,
    required this.camera,
    required this.gallery,
    required this.file,
    required this.typing,
    required this.spam,
    required this.subject,
    required this.to,
    required this.possibleSpam,
  });

  /// Context-menu entry that quotes a message.
  final String reply;

  /// Context-menu entry that copies a message's text.
  final String copy;

  /// Label shown while a translated message displays its original text.
  final String original;

  /// Action offered next to a failed delivery.
  final String retry;

  /// Day separator for the current day.
  final String today;

  /// Day separator for the previous day.
  final String yesterday;

  /// Placeholder in the composer's input field.
  final String messageHint;

  /// Label of a send button.
  final String send;

  /// Attachment source: the device camera.
  final String camera;

  /// Attachment source: the photo library.
  final String gallery;

  /// Attachment source (and fallback name for an unnamed attachment).
  final String file;

  /// Presence line while someone is typing.
  final String typing;

  /// Tag on a message flagged as junk.
  final String spam;

  /// Mail field: subject line.
  final String subject;

  /// Mail field: recipient.
  final String to;

  /// Notice shown on a message flagged as possible junk.
  final String possibleSpam;

  /// English — also the fallback for every unsupported language.
  const ChatStrings.en()
      : reply = 'Reply',
        copy = 'Copy',
        original = 'Original',
        retry = 'Send again',
        today = 'Today',
        yesterday = 'Yesterday',
        messageHint = 'Message',
        send = 'Send',
        camera = 'Camera',
        gallery = 'Gallery',
        file = 'File',
        typing = 'typing…',
        spam = 'Spam',
        subject = 'Subject',
        to = 'To',
        possibleSpam = 'Possible spam';

  /// German.
  const ChatStrings.de()
      : reply = 'Antworten',
        copy = 'Kopieren',
        original = 'Original',
        retry = 'Erneut senden',
        today = 'Heute',
        yesterday = 'Gestern',
        messageHint = 'Nachricht',
        send = 'Senden',
        camera = 'Kamera',
        gallery = 'Galerie',
        file = 'Datei',
        typing = 'tippt…',
        spam = 'Spam',
        subject = 'Betreff',
        to = 'An',
        possibleSpam = 'Möglicher Spam';

  /// Croatian.
  const ChatStrings.hr()
      : reply = 'Odgovori',
        copy = 'Kopiraj',
        original = 'Izvornik',
        retry = 'Pošalji ponovno',
        today = 'Danas',
        yesterday = 'Jučer',
        messageHint = 'Poruka',
        send = 'Pošalji',
        camera = 'Kamera',
        gallery = 'Galerija',
        file = 'Datoteka',
        typing = 'piše…',
        spam = 'Neželjeno',
        subject = 'Predmet',
        to = 'Za',
        possibleSpam = 'Moguće neželjeno';

  /// Turkish.
  const ChatStrings.tr()
      : reply = 'Yanıtla',
        copy = 'Kopyala',
        original = 'Orijinal',
        retry = 'Yeniden gönder',
        today = 'Bugün',
        yesterday = 'Dün',
        messageHint = 'Mesaj',
        send = 'Gönder',
        camera = 'Kamera',
        gallery = 'Galeri',
        file = 'Dosya',
        typing = 'yazıyor…',
        spam = 'Spam',
        subject = 'Konu',
        to = 'Kime',
        possibleSpam = 'Olası spam';

  /// Ukrainian.
  const ChatStrings.uk()
      : reply = 'Відповісти',
        copy = 'Копіювати',
        original = 'Оригінал',
        retry = 'Надіслати ще раз',
        today = 'Сьогодні',
        yesterday = 'Учора',
        messageHint = 'Повідомлення',
        send = 'Надіслати',
        camera = 'Камера',
        gallery = 'Галерея',
        file = 'Файл',
        typing = 'пише…',
        spam = 'Спам',
        subject = 'Тема',
        to = 'Кому',
        possibleSpam = 'Можливий спам';

  /// The preset for [locale]'s language, or English when there is none.
  ///
  /// Only `languageCode` is compared — country and script are ignored, so
  /// `de_AT` and `de_DE` share one set.
  static ChatStrings forLocale(Locale? locale) {
    switch (locale?.languageCode) {
      case 'de':
        return const ChatStrings.de();
      case 'hr':
        return const ChatStrings.hr();
      case 'tr':
        return const ChatStrings.tr();
      case 'uk':
        return const ChatStrings.uk();
      default:
        return const ChatStrings.en();
    }
  }

  /// The strings a widget should use: [override] when the host passed one,
  /// otherwise the preset for the ambient locale, otherwise English.
  static ChatStrings of(BuildContext context, {ChatStrings? override}) =>
      override ?? forLocale(Localizations.maybeLocaleOf(context));

  /// Returns a copy with the given fields replaced.
  ChatStrings copyWith({
    String? reply,
    String? copy,
    String? original,
    String? retry,
    String? today,
    String? yesterday,
    String? messageHint,
    String? send,
    String? camera,
    String? gallery,
    String? file,
    String? typing,
    String? spam,
    String? subject,
    String? to,
    String? possibleSpam,
  }) {
    return ChatStrings(
      reply: reply ?? this.reply,
      copy: copy ?? this.copy,
      original: original ?? this.original,
      retry: retry ?? this.retry,
      today: today ?? this.today,
      yesterday: yesterday ?? this.yesterday,
      messageHint: messageHint ?? this.messageHint,
      send: send ?? this.send,
      camera: camera ?? this.camera,
      gallery: gallery ?? this.gallery,
      file: file ?? this.file,
      typing: typing ?? this.typing,
      spam: spam ?? this.spam,
      subject: subject ?? this.subject,
      to: to ?? this.to,
      possibleSpam: possibleSpam ?? this.possibleSpam,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatStrings &&
        other.reply == reply &&
        other.copy == copy &&
        other.original == original &&
        other.retry == retry &&
        other.today == today &&
        other.yesterday == yesterday &&
        other.messageHint == messageHint &&
        other.send == send &&
        other.camera == camera &&
        other.gallery == gallery &&
        other.file == file &&
        other.typing == typing &&
        other.spam == spam &&
        other.subject == subject &&
        other.to == to &&
        other.possibleSpam == possibleSpam;
  }

  @override
  int get hashCode => Object.hash(
        reply, copy, original, retry, today, yesterday, messageHint, send,
        camera, gallery, file, typing, spam, subject, to, possibleSpam,
      );
}
