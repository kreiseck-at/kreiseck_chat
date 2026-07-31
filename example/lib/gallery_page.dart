import 'package:flutter/material.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

/// Fixed outgoing-bubble color swatches offered by the gallery.
const _swatches = [
  Color(0xFF3478F6),
  Color(0xFF25D366),
  Color(0xFFFFD60A),
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFFF2D95),
  Color(0xFFE9E9EB),
  Color(0xFF2C2C2E),
];

/// Shows every message state — reply, delivery failure, attachment, a
/// consecutive-message group, a very long word, and reactions — against a
/// chosen outgoing bubble color, with the measured contrast of the derived
/// ink printed above the thread so a color choice can be judged at a glance.
class GalleryPage extends StatefulWidget {
  /// Creates the gallery page.
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  Color _outgoingBubble = _swatches.first;
  Color? _incomingBubble;
  bool _dark = false;
  bool _showBubbleTail = false;
  bool _maxContrastInk = false;
  late final List<ChatMessage> _messages = _seed();

  List<ChatMessage> _seed() {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: 'g1',
        direction: MessageDirection.incoming,
        text: 'Kurze Antwort.',
        at: now.subtract(const Duration(minutes: 60)),
      ),
      ChatMessage(
        id: 'g2',
        direction: MessageDirection.outgoing,
        text: 'Alles klar.',
        at: now.subtract(const Duration(minutes: 54)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'g3',
        direction: MessageDirection.outgoing,
        text: 'Ja, das passt für mich.',
        at: now.subtract(const Duration(minutes: 48)),
        replyTo: const ChatMessageRef(
          id: 'g1',
          snippet: 'Kurze Antwort.',
          senderLabel: 'Kontakt',
        ),
      ),
      ChatMessage(
        id: 'g4',
        direction: MessageDirection.outgoing,
        text: 'Automatische Benachrichtigung an alle.',
        at: now.subtract(const Duration(minutes: 42)),
        status: MessageStatus.failed,
        errorText: 'Zustellung fehlgeschlagen',
      ),
      ChatMessage(
        id: 'g5',
        direction: MessageDirection.outgoing,
        text: 'Hier ist die Übersicht.',
        at: now.subtract(const Duration(minutes: 36)),
        status: MessageStatus.delivered,
        attachments: const [
          ChatAttachment(
            kind: AttachmentKind.file,
            fileName: 'bericht.pdf',
            sizeBytes: 248320,
          ),
        ],
      ),
      ChatMessage(
        id: 'g6',
        direction: MessageDirection.outgoing,
        text: 'Fahre gleich los.',
        at: now.subtract(const Duration(minutes: 20)),
      ),
      ChatMessage(
        id: 'g7',
        direction: MessageDirection.outgoing,
        text: 'Bin in zehn Minuten da.',
        at: now.subtract(const Duration(minutes: 19)),
      ),
      ChatMessage(
        id: 'g8',
        direction: MessageDirection.outgoing,
        text: 'Bis gleich!',
        at: now.subtract(const Duration(minutes: 18)),
        status: MessageStatus.delivered,
      ),
      ChatMessage(
        id: 'g9',
        direction: MessageDirection.incoming,
        text:
            'Donaudampfschifffahrtsgesellschaftskapitänspatentinhaberprüfungsordnung',
        at: now.subtract(const Duration(minutes: 12)),
      ),
      ChatMessage(
        id: 'g10',
        direction: MessageDirection.outgoing,
        text: 'Danke dir!',
        at: now.subtract(const Duration(minutes: 5)),
        status: MessageStatus.read,
        reactions: const [
          MessageReaction(emoji: '❤️', count: 2),
          MessageReaction(emoji: '👍', count: 1, reactedByMe: true),
        ],
      ),
    ];
  }

  ChatColors get _colors {
    final base = _dark ? const ChatColors.dark() : const ChatColors.light();
    final incoming = _incomingBubble ?? base.incomingBubble;
    // outgoingText follows the chosen bubble via BubbleInk.forSurface, the
    // same derivation ChatColors.inkFor would fall back to -- but, like
    // inkFor, steered by the base palette's own outgoingText so the gallery
    // shows the real shipped state: white stays white on the default blue
    // (the accepted ~4.07:1 trade-off) instead of switching to
    // higher-contrast black just because black measures better in
    // isolation. On a light swatch (yellow, white, #E9E9EB) white can't even
    // reach 3:1, so the polarity exception in BubbleInk.forSurface still
    // switches it to black -- exactly what would happen in the app.
    return base.copyWith(
      outgoingBubble: _outgoingBubble,
      outgoingText:
          BubbleInk.forSurface(_outgoingBubble, textColor: base.outgoingText)
              .text,
      incomingBubble: incoming,
      incomingText:
          BubbleInk.forSurface(incoming, textColor: base.incomingText).text,
      // With the switch on, the host supplies the ink itself instead of
      // letting inkFor derive it -- here the plain maximum-contrast
      // derivation, without the textColor polarity. On the default blue that
      // flips timestamp, quote bar and reply name from white to black while
      // the message text stays white: the very disagreement the polarity
      // rule exists to prevent, made visible side by side.
      incomingInk: _maxContrastInk ? BubbleInk.forSurface(incoming) : null,
      outgoingInk:
          _maxContrastInk ? BubbleInk.forSurface(_outgoingBubble) : null,
    );
  }

  ChatTheme get _theme =>
      ChatTheme(colors: _colors, showBubbleTail: _showBubbleTail);

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Zustände')),
      body: Column(
        children: [
          _measurements(colors),
          _colorPicker(
            label: 'Ausgehend',
            selected: _outgoingBubble,
            onPick: (c) => setState(() => _outgoingBubble = c),
          ),
          _colorPicker(
            label: 'Eingehend',
            selected: colors.incomingBubble,
            onPick: (c) => setState(() => _incomingBubble = c),
          ),
          _switches(),
          Expanded(
            child: ChatThreadView(
              messages: _messages,
              onSend: (_) {},
              theme: _theme,
              readOnly: true,
              onRetry: (_) {},
              onReact: (_, _) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _measurements(ChatColors colors) {
    String on(Color a, Color surface) =>
        contrastRatio(a, surface).toStringAsFixed(1);

    Widget row(String label, Color bubble, bool isOutgoing) {
      final ink = colors.inkFor(bubble, isOutgoing: isOutgoing);
      return Text(
        '$label · Text ${on(ink.text, bubble)} · '
        'Gedämpft ${on(ink.muted, bubble)} · Linie ${on(ink.line, bubble)}',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('Ausgehend', colors.outgoingBubble, true),
          row('Eingehend', colors.incomingBubble, false),
          // readableOn hebt eine Farbe, die eine eigene Bedeutung trägt, nur
          // so weit Richtung Schwarz/Weiß an, bis sie das Ziel erreicht —
          // der Farbton bleibt. Hier an Fehler- und Warnfarbe gezeigt.
          Text(
            'Fehler ${on(colors.error, colors.background)} → '
            '${on(colors.errorOnBackground, colors.background)} · '
            'Warnung ${on(colors.warning, colors.background)} → '
            '${on(colors.warningOnBackground, colors.background)}',
          ),
        ],
      ),
    );
  }

  Widget _colorPicker({
    required String label,
    required Color selected,
    required void Function(Color) onPick,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(width: 84, child: Text(label)),
          ..._swatches.map((c) {
          final isSelected = c == selected;
          return GestureDetector(
            onTap: () => onPick(c),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.grey,
                  width: isSelected ? 3 : 1,
                ),
              ),
            ),
          );
          }),
        ],
      ),
    );
  }

  Widget _switches() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _labeledSwitch(
            label: 'Dunkel',
            value: _dark,
            onChanged: (v) => setState(() => _dark = v),
          ),
          _labeledSwitch(
            label: 'Blasenschweif',
            value: _showBubbleTail,
            onChanged: (v) => setState(() => _showBubbleTail = v),
          ),
          _labeledSwitch(
            label: 'Tinte: max. Kontrast',
            value: _maxContrastInk,
            onChanged: (v) => setState(() => _maxContrastInk = v),
          ),
        ],
      ),
    );
  }

  Widget _labeledSwitch({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
