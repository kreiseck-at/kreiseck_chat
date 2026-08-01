import 'chat_attachment.dart';
import 'models.dart';

/// Merges runs of consecutive image-only messages into one message carrying
/// all their images, so the thread shows a single album instead of one bubble
/// per photo.
///
/// Channels that transport one image per message — MMS, WhatsApp, most
/// mail-to-chat bridges — deliver a batch of photos as separate messages a
/// second apart. Every messenger shows those as one album; this is where that
/// happens, so a host doesn't have to reshape its data first.
///
/// A message joins a run when it carries only images (no text, headline,
/// translation, error, reply or reactions), goes the same direction as the
/// run, and lands within [window] of its predecessor. The merged message
/// keeps the FIRST message's id — so keys and callbacks stay stable while
/// more photos arrive — and takes the LAST message's timestamp and status.
///
/// Anything else passes through untouched.
List<ChatMessage> groupMediaRuns(
  List<ChatMessage> messages, {
  Duration window = const Duration(minutes: 5),
}) {
  final out = <ChatMessage>[];
  var lauf = <ChatMessage>[];

  void laufAbschliessen() {
    if (lauf.isEmpty) return;
    if (lauf.length == 1) {
      out.add(lauf.first);
    } else {
      final letzte = lauf.last;
      out.add(
        lauf.first.copyWith(
          at: letzte.at,
          status: letzte.status,
          attachments: [for (final m in lauf) ...m.attachments],
        ),
      );
    }
    lauf = [];
  }

  for (final m in messages) {
    if (!_istNurBild(m)) {
      laufAbschliessen();
      out.add(m);
      continue;
    }
    if (lauf.isNotEmpty &&
        (lauf.last.direction != m.direction ||
            m.at.difference(lauf.last.at).abs() > window)) {
      laufAbschliessen();
    }
    lauf.add(m);
  }
  laufAbschliessen();
  return out;
}

/// Whether this message is nothing but images — the only kind that may be
/// folded into an album.
bool _istNurBild(ChatMessage m) =>
    m.kind == ChatMessageKind.normal &&
    m.text.isEmpty &&
    m.attachments.isNotEmpty &&
    m.attachments.every((a) => a.kind == AttachmentKind.image) &&
    m.headline == null &&
    m.translation == null &&
    m.errorText == null &&
    m.replyTo == null &&
    m.reactions.isEmpty;
