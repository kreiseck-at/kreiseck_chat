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
    required this.voiceMessage,
    required this.playbackSpeed,
    required this.voicePlaybackFailed,
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
    required this.cc,
    required this.bcc,
    required this.replyAll,
    required this.forward,
    required this.loadImages,
    required this.remoteContentBlocked,
    required this.attachmentBlocked,
    required this.attachmentUnknown,
    required this.openAnyway,
    required this.senderUnverified,
    required this.showQuoted,
    required this.openLink,
    required this.linkGoesTo,
    required this.linkDisguised,
    required this.cancel,
    required this.quotedMessage,
    required this.open,
    required this.writeMail,
    required this.callNumber,
    required this.discardDraft,
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

  /// Label for a voice message, e.g. on the voice bubble's accessibility node.
  final String voiceMessage;

  /// Label for the voice bubble's playback-rate control.
  final String playbackSpeed;

  /// Label shown when a voice message could not be played.
  final String voicePlaybackFailed;

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

  /// Label of the copy-recipients field.
  final String cc;

  /// Label of the blind-copy-recipients field.
  final String bcc;

  /// Action: answer everyone on the mail.
  final String replyAll;

  /// Action: pass the mail on.
  final String forward;

  /// Button on the notice that remote images were held back.
  final String loadImages;

  /// Notice that remote content was not loaded.
  final String remoteContentBlocked;

  /// Shown instead of a refused attachment.
  final String attachmentBlocked;

  /// Shown on an attachment nobody vouched for.
  final String attachmentUnknown;

  /// Confirms opening an unchecked attachment.
  final String openAnyway;

  /// Notice that the sender's origin could not be verified.
  final String senderUnverified;

  /// Expands the quoted earlier mail.
  final String showQuoted;

  /// Title of the sheet shown before a link from a mail is opened.
  final String openLink;

  /// Label above the link's real target.
  final String linkGoesTo;

  /// Warning that the link text names a different domain than the link.
  final String linkDisguised;

  /// Dismisses a confirmation.
  final String cancel;

  /// Header of the quoted earlier mail in a reply.
  final String quotedMessage;

  /// Confirms opening a link.
  final String open;

  /// Confirms opening the mail composer for a mailto: link.
  final String writeMail;

  /// Confirms placing a call for a tel: link.
  final String callNumber;

  /// Closes a draft without sending it.
  final String discardDraft;

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
      voiceMessage = 'Voice message',
      playbackSpeed = 'Playback speed',
      voicePlaybackFailed = "Can't play",
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
      body = 'Text',
      cc = 'Cc',
      bcc = 'Bcc',
      replyAll = 'Reply all',
      forward = 'Forward',
      loadImages = 'Load images',
      remoteContentBlocked = 'Images were not loaded.',
      attachmentBlocked = 'Blocked',
      attachmentUnknown = 'Not checked',
      openAnyway = 'Open anyway',
      senderUnverified = 'Sender could not be verified.',
      showQuoted = 'Show earlier mail',
      openLink = 'Open link?',
      linkGoesTo = 'This link goes to',
      linkDisguised =
          'The text names a different address than the link. Be careful.',
      cancel = 'Cancel',
      quotedMessage = 'Quoted message',
      open = 'Open',
      writeMail = 'Write mail',
      callNumber = 'Call',
      discardDraft = 'Discard draft';

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
      voiceMessage = 'Sprachnachricht',
      playbackSpeed = 'Wiedergabetempo',
      voicePlaybackFailed = 'Kann nicht abgespielt werden',
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
      body = 'Text',
      cc = 'Cc',
      bcc = 'Bcc',
      replyAll = 'Allen antworten',
      forward = 'Weiterleiten',
      loadImages = 'Bilder laden',
      remoteContentBlocked = 'Bilder wurden nicht geladen.',
      attachmentBlocked = 'Gesperrt',
      attachmentUnknown = 'Ungeprüft',
      openAnyway = 'Trotzdem öffnen',
      senderUnverified = 'Absender konnte nicht bestätigt werden.',
      showQuoted = 'Frühere Nachricht anzeigen',
      openLink = 'Link öffnen?',
      linkGoesTo = 'Dieser Link führt zu',
      linkDisguised =
          'Der Text nennt eine andere Adresse als der Link. Vorsicht.',
      cancel = 'Abbrechen',
      quotedMessage = 'Zitierte Nachricht',
      open = 'Öffnen',
      writeMail = 'E-Mail schreiben',
      callNumber = 'Anrufen',
      discardDraft = 'Entwurf verwerfen';

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
      voiceMessage = 'Glasovna poruka',
      playbackSpeed = 'Brzina reprodukcije',
      voicePlaybackFailed = 'Nije moguće reproducirati',
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
      body = 'Tekst',
      cc = 'Cc',
      bcc = 'Bcc',
      replyAll = 'Odgovori svima',
      forward = 'Proslijedi',
      loadImages = 'Učitaj slike',
      remoteContentBlocked = 'Slike nisu učitane.',
      attachmentBlocked = 'Blokirano',
      attachmentUnknown = 'Neprovjereno',
      openAnyway = 'Ipak otvori',
      senderUnverified = 'Pošiljatelja nije bilo moguće potvrditi.',
      showQuoted = 'Prikaži raniju poruku',
      openLink = 'Otvoriti poveznicu?',
      linkGoesTo = 'Ova poveznica vodi na',
      linkDisguised = 'Tekst navodi drugu adresu od poveznice. Oprez.',
      cancel = 'Odustani',
      quotedMessage = 'Citirana poruka',
      open = 'Otvori',
      writeMail = 'Napiši e-poštu',
      callNumber = 'Nazovi',
      discardDraft = 'Odbaci skicu';

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
      voiceMessage = 'Sesli mesaj',
      playbackSpeed = 'Oynatma hızı',
      voicePlaybackFailed = 'Oynatılamıyor',
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
      body = 'Metin',
      cc = 'Cc',
      bcc = 'Bcc',
      replyAll = 'Tümünü yanıtla',
      forward = 'İlet',
      loadImages = 'Görselleri yükle',
      remoteContentBlocked = 'Görseller yüklenmedi.',
      attachmentBlocked = 'Engellendi',
      attachmentUnknown = 'Denetlenmedi',
      openAnyway = 'Yine de aç',
      senderUnverified = 'Gönderen doğrulanamadı.',
      showQuoted = 'Önceki iletiyi göster',
      openLink = 'Bağlantı açılsın mı?',
      linkGoesTo = 'Bu bağlantı şuraya gidiyor',
      linkDisguised = 'Metin, bağlantıdan farklı bir adres belirtiyor. Dikkat.',
      cancel = 'Vazgeç',
      quotedMessage = 'Alıntılanan ileti',
      open = 'Aç',
      writeMail = 'E-posta yaz',
      callNumber = 'Ara',
      discardDraft = 'Taslağı sil';

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
      voiceMessage = 'Голосове повідомлення',
      playbackSpeed = 'Швидкість відтворення',
      voicePlaybackFailed = 'Не вдається відтворити',
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
      body = 'Текст',
      cc = 'Копія',
      bcc = 'Прихована копія',
      replyAll = 'Відповісти всім',
      forward = 'Переслати',
      loadImages = 'Завантажити зображення',
      remoteContentBlocked = 'Зображення не завантажено.',
      attachmentBlocked = 'Заблоковано',
      attachmentUnknown = 'Не перевірено',
      openAnyway = 'Усе одно відкрити',
      senderUnverified = 'Не вдалося підтвердити відправника.',
      showQuoted = 'Показати попереднє повідомлення',
      openLink = 'Відкрити посилання?',
      linkGoesTo = 'Це посилання веде на',
      linkDisguised =
          'Текст називає іншу адресу, ніж саме посилання. Будьте уважні.',
      cancel = 'Скасувати',
      quotedMessage = 'Цитоване повідомлення',
      open = 'Відкрити',
      writeMail = 'Написати лист',
      callNumber = 'Подзвонити',
      discardDraft = 'Відхилити чернетку';

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
    String? voiceMessage,
    String? playbackSpeed,
    String? voicePlaybackFailed,
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
    String? cc,
    String? bcc,
    String? replyAll,
    String? forward,
    String? loadImages,
    String? remoteContentBlocked,
    String? attachmentBlocked,
    String? attachmentUnknown,
    String? openAnyway,
    String? senderUnverified,
    String? showQuoted,
    String? openLink,
    String? linkGoesTo,
    String? linkDisguised,
    String? cancel,
    String? quotedMessage,
    String? open,
    String? writeMail,
    String? callNumber,
    String? discardDraft,
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
      voiceMessage: voiceMessage ?? this.voiceMessage,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      voicePlaybackFailed: voicePlaybackFailed ?? this.voicePlaybackFailed,
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
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      replyAll: replyAll ?? this.replyAll,
      forward: forward ?? this.forward,
      loadImages: loadImages ?? this.loadImages,
      remoteContentBlocked: remoteContentBlocked ?? this.remoteContentBlocked,
      attachmentBlocked: attachmentBlocked ?? this.attachmentBlocked,
      attachmentUnknown: attachmentUnknown ?? this.attachmentUnknown,
      openAnyway: openAnyway ?? this.openAnyway,
      senderUnverified: senderUnverified ?? this.senderUnverified,
      showQuoted: showQuoted ?? this.showQuoted,
      openLink: openLink ?? this.openLink,
      linkGoesTo: linkGoesTo ?? this.linkGoesTo,
      linkDisguised: linkDisguised ?? this.linkDisguised,
      cancel: cancel ?? this.cancel,
      quotedMessage: quotedMessage ?? this.quotedMessage,
      open: open ?? this.open,
      writeMail: writeMail ?? this.writeMail,
      callNumber: callNumber ?? this.callNumber,
      discardDraft: discardDraft ?? this.discardDraft,
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
        other.voiceMessage == voiceMessage &&
        other.playbackSpeed == playbackSpeed &&
        other.voicePlaybackFailed == voicePlaybackFailed &&
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
    reply,
    copy,
    original,
    retry,
    today,
    yesterday,
    messageHint,
    send,
    camera,
    gallery,
    file,
    voiceMessage,
    playbackSpeed,
    voicePlaybackFailed,
    typing,
    spam,
    subject,
    to,
    possibleSpam,
    online,
    lastSeenTodayPrefix,
    lastSeenYesterdayPrefix,
    lastSeenDatePrefix,
    lastSeenAtJoiner,
    noMailYet,
    body,
  ]);
}
