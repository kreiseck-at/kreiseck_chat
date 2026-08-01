import 'package:flutter/material.dart';

import 'chat_strings.dart';
import 'mail_link.dart';
import 'mail_theme.dart';

/// Asks before following a link from a mail, showing what the link *is*
/// rather than what it says: the domain large and bold, the full address
/// small underneath.
///
/// A link in a mail is a stranger's instruction. Reading the target before
/// following it is the one habit that defeats most phishing, and it only
/// works if the target is legible — hence the domain on its own line.
///
/// [linkText] is the text the link was shown as, when the host knows it.
/// When it names a different domain than [uri], the sheet says so.
///
/// Returns true when the reader chose to open it.
Future<bool> showMailLinkSheet(
  BuildContext context, {
  required Uri uri,
  String? linkText,
  MailTheme theme = const MailTheme.light(),
  ChatStrings? strings,
}) async {
  final s = ChatStrings.of(context, override: strings);
  final art = mailLinkAction(uri);
  final verkleidet = linkLooksDisguised(linkText, uri);
  // Bei Telefon und Mail steht das Ziel selbst da — eine Domain gibt es nicht.
  final gross = switch (art) {
    MailLinkAction.open =>
      uri.host.isEmpty ? uri.toString() : registrableDomain(uri.host),
    _ => uri.path.isEmpty ? uri.toString() : uri.path,
  };
  final titel = switch (art) {
    MailLinkAction.writeMail => s.writeMail,
    MailLinkAction.call => s.callNumber,
    MailLinkAction.open => s.openLink,
  };
  final knopf = switch (art) {
    MailLinkAction.writeMail => s.writeMail,
    MailLinkAction.call => s.callNumber,
    MailLinkAction.open => s.open,
  };

  final ok = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: theme.surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titel,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              art == MailLinkAction.open ? s.linkGoesTo : titel,
              style: TextStyle(
                color: theme.textColor.withValues(alpha: 0.6),
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            // Die Domain groß: das ist der Teil, an dem eine gefälschte
            // Adresse auffällt.
            Text(
              gross,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            // Der ganze Link klein darunter — vollständig, ohne Kürzung des
            // Anfangs, damit nichts versteckt bleibt.
            SelectableText(
              uri.toString(),
              maxLines: 3,
              style: TextStyle(
                color: theme.textColor.withValues(alpha: 0.6),
                fontSize: 11,
                height: 1.35,
              ),
            ),
            if (verkleidet) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFB5374A).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Color(0xFFB5374A),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.linkDisguised,
                        style: const TextStyle(
                          color: Color(0xFFB5374A),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(s.cancel),
                ),
                const SizedBox(width: 8),
                // Bei einer Verkleidung ist der Öffnen-Knopf bewusst der
                // unauffälligere von beiden.
                verkleidet
                    ? TextButton(
                        key: const ValueKey('mail-link-open'),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB5374A),
                        ),
                        child: Text(s.openAnyway),
                      )
                    : ElevatedButton(
                        key: const ValueKey('mail-link-open'),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.accentColor,
                          foregroundColor: Colors.white,
                        ),
                        // Nicht derselbe Text wie die Überschrift — sonst
                        // liest man den Knopf als Frage und findet ihn nicht.
                        child: Text(knopf),
                      ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return ok ?? false;
}
