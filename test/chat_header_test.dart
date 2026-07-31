import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

import 'locale_host.dart';

void main() {
  testWidgets('shows title and presence label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatHeader(
          title: 'Ada',
          presence: const ChatPresence.online(),
          theme: const ChatTheme.light(),
          now: DateTime(2026, 7, 21, 15),
        ),
      ),
    ));
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('typing overrides presence when enabled', (tester) async {
    await tester.pumpWidget(localeHost(
      ChatHeader(
        title: 'Ada',
        presence: const ChatPresence.online(),
        typing: true,
        theme: const ChatTheme.light(),
        now: DateTime(2026, 7, 21, 15),
      ),
      locale: const Locale('de'),
    ));
    expect(find.text('tippt…'), findsOneWidget);
    expect(find.text('Online'), findsNothing);
  });

  testWidgets('presence hidden when capability off', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatHeader(
          title: 'Ada',
          presence: const ChatPresence.online(),
          capabilities: const ChatCapabilities.twilioSms(),
          theme: const ChatTheme.light(),
          now: DateTime(2026, 7, 21, 15),
        ),
      ),
    ));
    expect(find.text('Online'), findsNothing);
  });

  testWidgets('Tipp-Hinweis folgt der App-Sprache', (tester) async {
    await tester.pumpWidget(localeHost(
      const ChatHeader(title: 'Ada', typing: true, theme: ChatTheme.light()),
      locale: const Locale('uk'),
    ));
    expect(find.text('пише…'), findsOneWidget);
  });

  testWidgets('typingLabel gewinnt weiterhin', (tester) async {
    await tester.pumpWidget(localeHost(
      const ChatHeader(
        title: 'Ada',
        typing: true,
        theme: ChatTheme.light(),
        typingLabel: 'schreibt',
      ),
      locale: const Locale('uk'),
    ));
    expect(find.text('schreibt'), findsOneWidget);
  });
}
