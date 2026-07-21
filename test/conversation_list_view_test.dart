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
}
