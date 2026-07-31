import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

import 'locale_host.dart';

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
    await tester.pumpWidget(localeHost(
      ConversationListView(
        conversations: const [
          ChatConversation(
              id: 'c1', title: 'Ada', lastText: 'Bis morgen', typing: true),
        ],
        onOpen: (_) {},
        capabilities: const ChatCapabilities.inApp(),
      ),
      locale: const Locale('de'),
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

  testWidgets('channel-label chip is shown when no badge builder', (tester) async {
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

  testWidgets('channelBadge replaces the text label with an avatar overlay',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: const [
            ChatConversation(id: 'c1', title: 'Ada', channelLabel: 'SMS'),
          ],
          onOpen: (_) {},
          channelBadge: (c) => const Icon(Icons.sms, key: Key('badge')),
        ),
      ),
    ));
    // Text label gone, badge shown.
    expect(find.text('SMS'), findsNothing);
    expect(find.byKey(const Key('badge')), findsOneWidget);
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

  testWidgets('Kanäle erscheinen als Marken-Reihe', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: [
            ChatConversation(
              id: 'c1',
              title: 'Ada',
              channels: [ChatChannel.whatsApp(), ChatChannel.sms()],
            ),
          ],
          onOpen: _nichts,
        ),
      ),
    ));
    expect(find.byType(ChatChannelBadge), findsNWidgets(2));
  });

  testWidgets('Kanäle-Reihe reicht die Listen-Fläche als surface durch',
      (tester) async {
    // Regression: ohne surface malt ChatChannelBadge die rohe Markenfarbe --
    // z. B. WhatsApp-Grün mit nur 2,05:1 auf dem hellen Listenhintergrund.
    // Die Fläche ist hier bekannt (die Zeile liegt auf theme.colors.background),
    // anders als bei der freistehenden Verwendung, für die surface null
    // bleiben soll.
    const theme = ChatTheme.light();
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: [
            ChatConversation(
              id: 'c1',
              title: 'Ada',
              channels: [ChatChannel.whatsApp()],
            ),
          ],
          onOpen: _nichts,
          theme: theme,
        ),
      ),
    ));
    final badge = tester.widget<ChatChannelBadge>(find.byType(ChatChannelBadge));
    expect(badge.surface, theme.colors.background);
  });

  testWidgets('channelBadge hat Vorrang vor der Kanäle-Reihe', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: const [
            ChatConversation(
              id: 'c1',
              title: 'Ada',
              channels: [ChatChannel.whatsApp(), ChatChannel.sms()],
            ),
          ],
          onOpen: (_) {},
          channelBadge: (c) => const Icon(Icons.sms, key: Key('badge')),
        ),
      ),
    ));
    expect(find.byType(ChatChannelBadge), findsNothing);
    expect(find.byKey(const Key('badge')), findsOneWidget);
  });

  testWidgets(
      'Kanäle-Reihe hat Vorrang vor dem Text-Label, wenn beide gesetzt sind',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: [
            ChatConversation(
              id: 'c1',
              title: 'Ada',
              channelLabel: 'SMS',
              channels: [ChatChannel.whatsApp(), ChatChannel.sms()],
            ),
          ],
          onOpen: _nichts,
        ),
      ),
    ));
    expect(find.byType(ChatChannelBadge), findsNWidgets(2));
    expect(find.text('SMS'), findsNothing);
  });

  testWidgets('titleBadgeBuilder wird eingesetzt', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: const [ChatConversation(id: 'c1', title: 'Ada')],
          onOpen: (_) {},
          titleBadgeBuilder: (_) => const Text('SPAM'),
        ),
      ),
    ));
    expect(find.text('SPAM'), findsOneWidget);
  });

  testWidgets('titleBadgeBuilder-Widget sitzt vor dem Titeltext',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: const [ChatConversation(id: 'c1', title: 'Ada')],
          onOpen: (_) {},
          titleBadgeBuilder: (_) =>
              const Icon(Icons.warning_rounded, key: Key('badge')),
        ),
      ),
    ));
    final badgeLeft = tester.getTopLeft(find.byKey(const Key('badge'))).dx;
    final titleLeft = tester.getTopLeft(find.text('Ada')).dx;
    expect(badgeLeft, lessThan(titleLeft));
  });

  testWidgets('onLongPress wird ausgelöst', (tester) async {
    ChatConversation? gedrueckt;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: const [ChatConversation(id: 'c1', title: 'Ada')],
          onOpen: (_) {},
          onLongPress: (c) => gedrueckt = c,
        ),
      ),
    ));
    await tester.longPress(find.text('Ada'));
    expect(gedrueckt?.id, 'c1');
  });

  testWidgets('onTap und onLongPress funktionieren unabhängig voneinander',
      (tester) async {
    ChatConversation? getippt;
    ChatConversation? gedrueckt;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConversationListView(
          conversations: const [ChatConversation(id: 'c1', title: 'Ada')],
          onOpen: (c) => getippt = c,
          onLongPress: (c) => gedrueckt = c,
        ),
      ),
    ));
    await tester.tap(find.text('Ada'));
    expect(getippt?.id, 'c1');
    expect(gedrueckt, isNull);

    await tester.longPress(find.text('Ada'));
    expect(gedrueckt?.id, 'c1');
    expect(getippt?.id, 'c1');
  });

  testWidgets(
      'lange Titel mit Abzeichen und drei Kanal-Marken laufen nicht über',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 260,
          child: ConversationListView(
            conversations: const [
              ChatConversation(
                id: 'c1',
                title: 'Ein sehr sehr sehr langer Titel für diese Zeile',
                pinned: true,
                muted: true,
                channels: [
                  ChatChannel.whatsApp(),
                  ChatChannel.sms(),
                  ChatChannel.email(),
                ],
              ),
            ],
            onOpen: (_) {},
            titleBadgeBuilder: (_) => const Text('NEU'),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tipp-Vorschau folgt der App-Sprache', (tester) async {
    await tester.pumpWidget(localeHost(
      ConversationListView(
        conversations: const [
          ChatConversation(id: 'c1', title: 'Ada', typing: true),
        ],
        onOpen: (_) {},
      ),
      locale: const Locale('uk'),
    ));
    expect(find.text('пише…'), findsOneWidget);
  });
}

void _nichts(ChatConversation c) {}
