import 'package:flutter/material.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  BubbleStyle _style = BubbleStyle.iMessage;
  ChatCapabilities _caps = const ChatCapabilities.inApp();
  bool _dark = false;
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
        at: now.subtract(const Duration(minutes: 30)),
        sender: const ChatParticipant(id: 'ada', displayName: 'Ada'),
        reactions: const [MessageReaction(emoji: '👍', count: 1)],
      ),
      ChatMessage(
        id: '2',
        direction: MessageDirection.outgoing,
        text: 'Ja, ab 18 Uhr. Passt das?',
        at: now.subtract(const Duration(minutes: 28)),
        status: MessageStatus.read,
        replyTo: const ChatMessageRef(
            id: '1', snippet: 'Bist du heute noch unterwegs?', senderLabel: 'Ada'),
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
            _controls(),
            Expanded(
              child: ChatThreadView(
                messages: _messages,
                onSend: _send,
                theme: _theme,
                capabilities: _caps,
                typing: const TypingState(participants: [
                  ChatParticipant(id: 'ada', displayName: 'Ada'),
                ]),
                header: ChatHeader(
                  title: 'Ada',
                  presence: const ChatPresence.online(),
                  theme: _theme,
                  capabilities: _caps,
                ),
                onReplyRequested: (_) {},
                onReact: (_, _) {},
                onAttach: (_) {},
              ),
            ),
          ],
        ),
      ),
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
              DropdownMenuItem(value: 'whatsapp', child: Text('Twilio WhatsApp')),
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
