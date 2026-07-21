import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  testWidgets('renders title and last text; tap opens', (tester) async {
    ChatConversation? opened;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: [
            ChatConversation(id: 'c1', title: 'Ada', lastText: 'Bis morgen'),
          ],
          onOpen: (c) => opened = c,
        ),
      ),
    ));
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Bis morgen'), findsOneWidget);
    await tester.tap(find.text('Ada'));
    expect(opened?.id, 'c1');
  });

  testWidgets('typing preview overrides last text when enabled', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: const [
            ChatConversation(
                id: 'c1', title: 'Ada', lastText: 'Bis morgen', typing: true),
          ],
          onOpen: (_) {},
          capabilities: const ChatCapabilities.inApp(),
        ),
      ),
    ));
    expect(find.text('tippt…'), findsOneWidget);
    expect(find.text('Bis morgen'), findsNothing);
  });

  testWidgets('unread badge shows count', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: const [
            ChatConversation(id: 'c1', title: 'Ada', unread: 3),
          ],
          onOpen: (_) {},
        ),
      ),
    ));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('avatar shows initials monogram when no image', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: const [
            ChatConversation(id: 'c1', title: 'Ada'),
          ],
          onOpen: (_) {},
        ),
      ),
    ));
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('channel-label chip is shown', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: const [
            ChatConversation(id: 'c1', title: 'Ada', channelLabel: 'SMS'),
          ],
          onOpen: (_) {},
        ),
      ),
    ));
    expect(find.text('SMS'), findsOneWidget);
  });

  testWidgets('pinned and muted icons are shown', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: const [
            ChatConversation(id: 'c1', title: 'Ada', pinned: true, muted: true),
          ],
          onOpen: (_) {},
        ),
      ),
    ));
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    expect(find.byIcon(Icons.volume_off), findsOneWidget);
  });

  testWidgets('presence dot shown when online and presence capability on',
      (tester) async {
    const theme = ChatTheme.light();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: [
            ChatConversation(
              id: 'c1',
              title: 'Ada',
              presence: ChatPresence.online(),
            ),
          ],
          onOpen: (_) {},
          capabilities: const ChatCapabilities.inApp(),
          theme: theme,
        ),
      ),
    ));
    final dot = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color == theme.colors.presenceOnline);
    expect(dot, findsOneWidget);
  });

  testWidgets('no presence dot when presence capability off', (tester) async {
    const theme = ChatTheme.light();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: [
            ChatConversation(
              id: 'c1',
              title: 'Ada',
              presence: ChatPresence.online(),
            ),
          ],
          onOpen: (_) {},
          capabilities: const ChatCapabilities.twilioSms(),
          theme: theme,
        ),
      ),
    ));
    final dot = find.byWidgetPredicate((w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color == theme.colors.presenceOnline);
    expect(dot, findsNothing);
  });
}
