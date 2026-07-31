import 'package:flutter/material.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

import 'gallery_page.dart';

void main() => runApp(const DemoApp());

enum _Screen { thread, conversations }

// Flutter's own Default(Material|Widgets)Localizations only declare
// themselves supported for 'en' (see their isSupported overrides), so
// switching MaterialApp.locale to 'de'/'hr'/'tr'/'uk' alone leaves widgets
// that need MaterialLocalizations (the Composer's TextField, among others)
// without resources to load, even once `supportedLocales` lists the locale.
// These delegates hand back the very same English-only resources, just
// without gating on the locale, so the demo can show all five languages
// without depending on the flutter_localizations package (this package has
// none of its own dependencies, and the example follows suit). See
// test/locale_host.dart in the package root for the same pattern used by
// the test suite.
class _AnyLocaleWidgetsLocalizations
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _AnyLocaleWidgetsLocalizations();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      DefaultWidgetsLocalizations.load(locale);
  @override
  bool shouldReload(_AnyLocaleWidgetsLocalizations old) => false;
}

class _AnyLocaleMaterialLocalizations
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _AnyLocaleMaterialLocalizations();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);
  @override
  bool shouldReload(_AnyLocaleMaterialLocalizations old) => false;
}

const _supportedLocales = [
  Locale('en'),
  Locale('de'),
  Locale('hr'),
  Locale('tr'),
  Locale('uk'),
];

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  BubbleStyle _style = BubbleStyle.iMessage;
  ChatCapabilities _caps = const ChatCapabilities.inApp();
  bool _dark = false;
  bool _showBubbleTail = false;
  _Screen _screen = _Screen.thread;
  String _composerChannel = 'whatsapp';
  Locale _locale = const Locale('de');
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = _seed();
  }

  List<ChatMessage> _seed() {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: '1',
        direction: MessageDirection.incoming,
        text: 'Servus! Bist du heute noch unterwegs?',
        at: now.subtract(const Duration(minutes: 50)),
        sender: const ChatParticipant(id: 'ada', displayName: 'Ada'),
        reactions: const [MessageReaction(emoji: '👍', count: 1)],
        channel: const ChatChannel.whatsApp(),
      ),
      ChatMessage(
        id: '2',
        direction: MessageDirection.outgoing,
        text: 'Ja, ab 18 Uhr. Passt das?',
        at: now.subtract(const Duration(minutes: 48)),
        status: MessageStatus.read,
        replyTo: const ChatMessageRef(
          id: '1',
          snippet: 'Bist du heute noch unterwegs?',
          senderLabel: 'Ada',
        ),
        channel: const ChatChannel.whatsApp(),
      ),
      ChatMessage(
        id: '3',
        direction: MessageDirection.incoming,
        text: 'Alles klar, bis dann. Ruf mich falls was ist.',
        at: now.subtract(const Duration(minutes: 40)),
        channel: const ChatChannel.sms(),
      ),
      ChatMessage(
        id: '4',
        direction: MessageDirection.outgoing,
        text: 'Anbei die aktuelle Übersicht.',
        at: now.subtract(const Duration(minutes: 32)),
        status: MessageStatus.sent,
        headline: 'Kurzinfo',
      ),
      ChatMessage(
        id: '5',
        direction: MessageDirection.outgoing,
        text: 'Automatische Nachricht an alle Teilnehmer.',
        at: now.subtract(const Duration(minutes: 24)),
        status: MessageStatus.failed,
        errorText: 'Empfängerin hat abbestellt',
      ),
      ChatMessage(
        id: '6',
        direction: MessageDirection.incoming,
        text: 'Привіт, як справи?',
        at: now.subtract(const Duration(minutes: 16)),
        translation: const ChatTranslation(
          text: 'Hello there',
          languageLabel: 'EN',
        ),
      ),
      ChatMessage(
        id: '7',
        direction: MessageDirection.incoming,
        text: 'Ada hat den Kanal auf WhatsApp gewechselt.',
        at: now.subtract(const Duration(minutes: 8)),
        kind: ChatMessageKind.system,
      ),
      ChatMessage(
        id: '8',
        direction: MessageDirection.incoming,
        text: 'Anruf verpasst, 0:42 Min.',
        at: now.subtract(const Duration(minutes: 2)),
        kind: ChatMessageKind.custom,
      ),
    ];
  }

  ChatTheme get _theme {
    final brightness = _dark ? Brightness.dark : Brightness.light;
    final base = switch (_style) {
      BubbleStyle.whatsApp => ChatTheme.whatsApp(brightness: brightness),
      BubbleStyle.iMessage => ChatTheme.iMessage(brightness: brightness),
      BubbleStyle.minimal =>
        _dark ? const ChatTheme.dark() : const ChatTheme.light(),
    };
    // Seit 0.14.0 zeichnen auch die whatsApp-/iMessage-Vorlagen von Haus aus
    // keinen Blasenschweif mehr — der Schalter holt ihn zurück. Genau hier
    // fällt die Verhaltensänderung auf, nicht in der Zustands-Galerie.
    return base.copyWith(showBubbleTail: _showBubbleTail);
  }

  void _send(String text) {
    setState(() {
      _messages = [
        ..._messages,
        ChatMessage(
          id: '${_messages.length + 1}',
          direction: MessageDirection.outgoing,
          text: text,
          at: DateTime.now(),
          status: MessageStatus.sent,
          channel: _composerChannel == 'whatsapp'
              ? const ChatChannel.whatsApp()
              : const ChatChannel.sms(),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Nothing is passed to the chat widgets themselves — locale is the
      // only thing that changes, and ChatStrings.of picks it up from here.
      locale: _locale,
      supportedLocales: _supportedLocales,
      localizationsDelegates: const [
        _AnyLocaleMaterialLocalizations(),
        _AnyLocaleWidgetsLocalizations(),
      ],
      theme: ThemeData(brightness: _dark ? Brightness.dark : Brightness.light),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('kreiseck_chat Demo'),
          actions: [
            IconButton(
              icon: const Icon(Icons.palette_outlined),
              tooltip: 'Zustände',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const GalleryPage()),
              ),
            ),
            IconButton(
              icon: Icon(_dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _dark = !_dark),
            ),
          ],
        ),
        body: Column(
          children: [
            _screenSwitch(),
            if (_screen == _Screen.thread) _controls(),
            Expanded(
              child: _screen == _Screen.thread
                  ? _threadDemo()
                  : _conversationListDemo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _screenSwitch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: SegmentedButton<_Screen>(
        segments: const [
          ButtonSegment(value: _Screen.thread, label: Text('Verlauf')),
          ButtonSegment(
            value: _Screen.conversations,
            label: Text('Konversationen'),
          ),
        ],
        selected: {_screen},
        onSelectionChanged: (s) => setState(() => _screen = s.first),
      ),
    );
  }

  Widget _threadDemo() {
    return ChatThreadView(
      messages: _messages,
      onSend: _send,
      theme: _theme,
      capabilities: _caps,
      typing: const TypingState(
        participants: [ChatParticipant(id: 'ada', displayName: 'Ada')],
      ),
      header: ChatHeader(
        title: 'Ada',
        presence: const ChatPresence.online(),
        theme: _theme,
        capabilities: _caps,
      ),
      onReplyRequested: (_) {},
      onReact: (_, _) {},
      onAttach: (_) {},
      // Ohne onRetry zeigt eine fehlgeschlagene Nachricht nur den Grund;
      // mit ihm zusätzlich eine Wiederholen-Aktion mit 44x44-Tippfläche.
      // Die Nachricht wird neu gebaut statt kopiert: copyWith kann einen
      // gesetzten errorText nicht wieder entfernen (`errorText ?? this.…`).
      onRetry: (message) => setState(() {
        _messages = [
          for (final m in _messages)
            if (m.id == message.id)
              ChatMessage(
                id: m.id,
                direction: m.direction,
                text: m.text,
                at: m.at,
                status: MessageStatus.sent,
                channel: m.channel,
                headline: m.headline,
              )
            else
              m,
        ];
      }),
      customMessageBuilder: (m) =>
          _CallSummaryCard(theme: _theme, text: m.text),
      composerBanner: ChatBanner(
        text: 'Nur Text möglich',
        variant: ChatBannerVariant.warning,
        theme: _theme,
      ),
      composerLeading: DropdownButton<String>(
        value: _composerChannel,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(
            value: 'whatsapp',
            child: Icon(Icons.chat_rounded, size: 18),
          ),
          DropdownMenuItem(
            value: 'sms',
            child: Icon(Icons.sms_rounded, size: 18),
          ),
        ],
        onChanged: (v) =>
            setState(() => _composerChannel = v ?? _composerChannel),
      ),
    );
  }

  Widget _conversationListDemo() {
    return ConversationListView(
      theme: _theme,
      capabilities: _caps,
      conversations: [
        const ChatConversation(
          id: 'c1',
          title: 'Ada',
          subtitle: 'Ja, ab 18 Uhr. Passt das?',
          lastText: 'Ja, ab 18 Uhr. Passt das?',
          pinned: true,
          channels: [ChatChannel.whatsApp(), ChatChannel.sms()],
        ),
        const ChatConversation(
          id: 'c2',
          title: 'Noah',
          subtitle: 'Klingt gut, bis dann!',
          unread: 2,
          channels: [ChatChannel.email()],
        ),
        const ChatConversation(
          id: 'c3',
          title: 'Mira',
          subtitle: 'Danke, hat geklappt.',
          channelLabel: 'E-Mail',
        ),
      ],
      onOpen: (_) {},
      onLongPress: (_) {},
      titleBadgeBuilder: (c) => c.unread > 0
          ? Icon(
              Icons.priority_high_rounded,
              size: 14,
              color: _theme.colors.error,
            )
          : null,
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<BubbleStyle>(
            value: _style,
            items: BubbleStyle.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (s) => setState(() => _style = s!),
          ),
          DropdownButton<String>(
            value: _capsLabel,
            items: const [
              DropdownMenuItem(value: 'sms', child: Text('Twilio SMS')),
              DropdownMenuItem(
                value: 'whatsapp',
                child: Text('Twilio WhatsApp'),
              ),
              DropdownMenuItem(value: 'inapp', child: Text('In-App')),
            ],
            onChanged: (v) => setState(() {
              switch (v) {
                case 'sms':
                  _caps = const ChatCapabilities.twilioSms();
                  break;
                case 'whatsapp':
                  _caps = const ChatCapabilities.twilioWhatsApp();
                  break;
                default:
                  _caps = const ChatCapabilities.inApp();
              }
            }),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Schweif'),
              Switch(
                value: _showBubbleTail,
                onChanged: (v) => setState(() => _showBubbleTail = v),
              ),
            ],
          ),
          DropdownButton<Locale>(
            value: _locale,
            items: const [
              DropdownMenuItem(value: Locale('en'), child: Text('English')),
              DropdownMenuItem(value: Locale('de'), child: Text('Deutsch')),
              DropdownMenuItem(value: Locale('hr'), child: Text('Hrvatski')),
              DropdownMenuItem(value: Locale('tr'), child: Text('Türkçe')),
              DropdownMenuItem(
                value: Locale('uk'),
                child: Text('Українська'),
              ),
            ],
            onChanged: (l) => setState(() => _locale = l ?? _locale),
          ),
        ],
      ),
    );
  }

  String get _capsLabel {
    if (_caps == const ChatCapabilities.twilioSms()) return 'sms';
    if (_caps == const ChatCapabilities.twilioWhatsApp()) return 'whatsapp';
    return 'inapp';
  }
}

/// A fully custom card for [ChatMessageKind.custom] messages — shows how a
/// host app can render its own bespoke content instead of a normal bubble.
class _CallSummaryCard extends StatelessWidget {
  const _CallSummaryCard({required this.theme, required this.text});

  final ChatTheme theme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colors.accent),
          borderRadius: BorderRadius.circular(theme.bubbleRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.call_rounded, size: 16, color: theme.colors.accent),
            const SizedBox(width: 8),
            Text(text, style: theme.typography.systemMessage),
          ],
        ),
      ),
    );
  }
}
