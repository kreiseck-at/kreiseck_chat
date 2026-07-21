import 'package:flutter/material.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() => runApp(const ExampleApp());

/// Minimal demo app wiring up [ConversationListView] and [ChatThreadView]
/// against in-memory data (no backend involved).
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kreiseck_chat example',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const ConversationsPage(),
    );
  }
}

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final Map<String, List<ChatMessage>> _messagesByConversation = {
    '1': [
      ChatMessage(
        id: 'm1',
        direction: MessageDirection.incoming,
        text: 'Hey, are you around later?',
        at: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        id: 'm2',
        direction: MessageDirection.outgoing,
        text: 'Yes, from 4pm.',
        at: DateTime.now().subtract(const Duration(minutes: 8)),
        status: MessageStatus.read,
      ),
    ],
    '2': [
      ChatMessage(
        id: 'm3',
        direction: MessageDirection.incoming,
        text: 'Thanks for the update!',
        at: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
  };

  List<ChatConversation> get _conversations => [
        ChatConversation(
          id: '1',
          title: 'Alice',
          lastText: _messagesByConversation['1']!.last.text,
          lastAt: _messagesByConversation['1']!.last.at,
          unread: 1,
        ),
        ChatConversation(
          id: '2',
          title: 'Bob',
          lastText: _messagesByConversation['2']!.last.text,
          lastAt: _messagesByConversation['2']!.last.at,
        ),
      ];

  void _openConversation(ChatConversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          title: conversation.title,
          messages: _messagesByConversation[conversation.id]!,
          onSend: (text) => _sendMessage(conversation.id, text),
        ),
      ),
    );
  }

  void _sendMessage(String conversationId, String text) {
    setState(() {
      _messagesByConversation[conversationId] = [
        ..._messagesByConversation[conversationId]!,
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: ConversationListView(
        conversations: _conversations,
        onOpen: _openConversation,
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.title,
    required this.messages,
    required this.onSend,
  });

  final String title;
  final List<ChatMessage> messages;
  final ValueChanged<String> onSend;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = widget.messages;
  }

  void _handleSend(String text) {
    widget.onSend(text);
    setState(() {
      _messages = [
        ..._messages,
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          direction: MessageDirection.outgoing,
          text: text,
          at: DateTime.now(),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ChatThreadView(
        messages: _messages,
        onSend: _handleSend,
        hintText: 'Message ${widget.title}',
      ),
    );
  }
}
