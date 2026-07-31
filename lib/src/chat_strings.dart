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
    required this.online,
    required this.lastSeenTodayPrefix,
    required this.lastSeenYesterdayPrefix,
    required this.lastSeenDatePrefix,
    required this.lastSeenAtJoiner,
    required this.noMailYet,
    required this.body,
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

  /// Presence line shown while a participant is online. See
  /// [PresenceLabels.fromStrings].
  final String online;

  /// Presence prefix before a same-day last-seen time, e.g. `'last seen at '`.
  final String lastSeenTodayPrefix;

  /// Presence prefix before a previous-day last-seen time, e.g.
  /// `'last seen yesterday at '`.
  final String lastSeenYesterdayPrefix;

  /// Presence prefix before an older last-seen date, e.g. `'last seen on '`.
  final String lastSeenDatePrefix;

  /// Joiner between an older last-seen date and its time, e.g. `' at '` in
  /// `'last seen on 3.2.2026 at 14:30'`.
  final String lastSeenAtJoiner;

  /// Shown in [MailListView] when there are no messages to list.
  final String noMailYet;

  /// Mail field: the body text input's label in [MailComposer].
  final String body;

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
        possibleSpam = 'Possible spam',
        online = 'Online',
        lastSeenTodayPrefix = 'last seen at ',
        lastSeenYesterdayPrefix = 'last seen yesterday at ',
        lastSeenDatePrefix = 'last seen on ',
        lastSeenAtJoiner = ' at ',
        noMailYet = 'No mail yet',
        body = 'Text';

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
        possibleSpam = 'Möglicher Spam',
        online = 'Online',
        lastSeenTodayPrefix = 'zuletzt gesehen um ',
        lastSeenYesterdayPrefix = 'zuletzt gesehen gestern um ',
        lastSeenDatePrefix = 'zuletzt gesehen am ',
        lastSeenAtJoiner = ' um ',
        noMailYet = 'Noch keine Mails',
        body = 'Text';

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
        possibleSpam = 'Moguće neželjeno',
        online = 'Na mreži',
        lastSeenTodayPrefix = 'posljednji put viđen u ',
        lastSeenYesterdayPrefix = 'posljednji put viđen jučer u ',
        lastSeenDatePrefix = 'posljednji put viđen ',
        lastSeenAtJoiner = ' u ',
        noMailYet = 'Još nema pošte',
        body = 'Tekst';

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
        possibleSpam = 'Olası spam',
        online = 'Çevrimiçi',
        lastSeenTodayPrefix = 'son görülme ',
        lastSeenYesterdayPrefix = 'dün son görülme ',
        lastSeenDatePrefix = 'son görülme ',
        // Deliberately just a space: Turkish uses no connecting word here --
        // "son görülme 31.07.2026 14:30" reads correctly on its own. Not a
        // missing translation; see chat_strings_test.dart for the dedicated
        // (non-trim) emptiness check this value needs instead of the
        // standard one.
        lastSeenAtJoiner = ' ',
        noMailYet = 'Henüz posta yok',
        body = 'Metin';

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
        possibleSpam = 'Можливий спам',
        online = 'У мережі',
        lastSeenTodayPrefix = 'востаннє в мережі о ',
        lastSeenYesterdayPrefix = 'востаннє в мережі вчора о ',
        lastSeenDatePrefix = 'востаннє в мережі ',
        lastSeenAtJoiner = ' о ',
        noMailYet = 'Ще немає листів',
        body = 'Текст';

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
    String? online,
    String? lastSeenTodayPrefix,
    String? lastSeenYesterdayPrefix,
    String? lastSeenDatePrefix,
    String? lastSeenAtJoiner,
    String? noMailYet,
    String? body,
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
      online: online ?? this.online,
      lastSeenTodayPrefix: lastSeenTodayPrefix ?? this.lastSeenTodayPrefix,
      lastSeenYesterdayPrefix:
          lastSeenYesterdayPrefix ?? this.lastSeenYesterdayPrefix,
      lastSeenDatePrefix: lastSeenDatePrefix ?? this.lastSeenDatePrefix,
      lastSeenAtJoiner: lastSeenAtJoiner ?? this.lastSeenAtJoiner,
      noMailYet: noMailYet ?? this.noMailYet,
      body: body ?? this.body,
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
        other.possibleSpam == possibleSpam &&
        other.online == online &&
        other.lastSeenTodayPrefix == lastSeenTodayPrefix &&
        other.lastSeenYesterdayPrefix == lastSeenYesterdayPrefix &&
        other.lastSeenDatePrefix == lastSeenDatePrefix &&
        other.lastSeenAtJoiner == lastSeenAtJoiner &&
        other.noMailYet == noMailYet &&
        other.body == body;
  }

  // Object.hash tops out at 20 positional arguments -- this class carries
  // 23 fields, so hashAll over the full list is used instead.
  @override
  int get hashCode => Object.hashAll([
        reply, copy, original, retry, today, yesterday, messageHint, send,
        camera, gallery, file, typing, spam, subject, to, possibleSpam,
        online, lastSeenTodayPrefix, lastSeenYesterdayPrefix,
        lastSeenDatePrefix, lastSeenAtJoiner, noMailYet, body,
      ]);
}
