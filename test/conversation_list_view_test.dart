import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  testWidgets('shows conversations and reports taps', (tester) async {
    final conversations = [
      const ChatConversation(id: '1', title: 'Alice', lastText: 'Hi there'),
      const ChatConversation(id: '2', title: 'Bob', lastText: 'See you'),
    ];
    ChatConversation? opened;

    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListView(
          conversations: conversations,
          onOpen: (conversation) => opened = conversation,
        ),
      ),
    );

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);

    await tester.tap(find.text('Bob'));
    await tester.pump();

    expect(opened, conversations[1]);
  });

  testWidgets('shows an empty state without crashing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListView(
          conversations: const [],
          onOpen: (_) {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ConversationListView), findsOneWidget);
  });
}
