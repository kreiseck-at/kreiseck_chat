import 'package:flutter/material.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() => runApp(const DemoApp());

enum _Screen { thread, conversations }

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  BubbleStyle _style = BubbleStyle.iMessage;
  ChatCapabilities _caps = const ChatCapabilities.inApp();
  bool _dark = false;
  _Screen _screen = _Screen.thread;
  String _composerChannel = 'whatsapp';
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
    switch (_style) {
      case BubbleStyle.whatsApp:
        return ChatTheme.whatsApp(brightness: brightness);
      case BubbleStyle.iMessage:
        return ChatTheme.iMessage(brightness: brightness);
      case BubbleStyle.minimal:
        return _dark ? const ChatTheme.dark() : const ChatTheme.light();
    }
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
      theme: ThemeData(brightness: _dark ? Brightness.dark : Brightness.light),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('kreiseck_chat Demo'),
          actions: [
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
      customMessageBuilder: (m) =>
          _CallSummaryCard(theme: _theme, text: m.text),
      composerBanner: const ChatBanner(
        text: 'Nur Text möglich',
        variant: ChatBannerVariant.warning,
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
