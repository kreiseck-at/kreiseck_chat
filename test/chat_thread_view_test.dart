import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

import 'locale_host.dart';

List<ChatMessage> _seed() => [
      ChatMessage(
          id: '1',
          direction: MessageDirection.incoming,
          text: 'Hallo',
          at: DateTime(2026, 7, 21, 9, 0)),
      ChatMessage(
          id: '2',
          direction: MessageDirection.outgoing,
          text: 'Servus',
          at: DateTime(2026, 7, 21, 9, 1)),
    ];

void main() {
  testWidgets('renders messages and a date separator', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: _seed(),
          onSend: (_) {},
          now: DateTime(2026, 7, 21, 10),
        ),
      ),
    ));
    expect(find.text('Hallo'), findsOneWidget);
    expect(find.text('Servus'), findsOneWidget);
    expect(find.byType(DateSeparator), findsOneWidget);
  });

  testWidgets('shows typing indicator when enabled and typing', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: _seed(),
          onSend: (_) {},
          capabilities: const ChatCapabilities.inApp(),
          typing: const TypingState(
              participants: [ChatParticipant(id: 'a', displayName: 'Ada')]),
          now: DateTime(2026, 7, 21, 10),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(TypingIndicator), findsOneWidget);
  });

  testWidgets('no typing indicator when capability off', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: _seed(),
          onSend: (_) {},
          capabilities: const ChatCapabilities.twilioSms(),
          typing: const TypingState(
              participants: [ChatParticipant(id: 'a', displayName: 'Ada')]),
          now: DateTime(2026, 7, 21, 10),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(TypingIndicator), findsNothing);
  });

  testWidgets('a newly received incoming message fires a receive haptic',
      (tester) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String? ?? '');
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final theme = ChatTheme.light().copyWith(
      motion: const ChatMotion(hapticOnReceive: true),
    );
    final messages = _seed();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: messages,
          onSend: (_) {},
          theme: theme,
          now: DateTime(2026, 7, 21, 10),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    haptics.clear();

    final grown = [
      ...messages,
      ChatMessage(
          id: '3',
          direction: MessageDirection.incoming,
          text: 'Neu',
          at: DateTime(2026, 7, 21, 9, 2)),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: grown,
          onSend: (_) {},
          theme: theme,
          now: DateTime(2026, 7, 21, 10),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(haptics, isNotEmpty);
  });

  ChatMessage nachricht(String id, ChatMessageKind kind, {String text = 'x'}) =>
      ChatMessage(
        id: id,
        direction: MessageDirection.incoming,
        text: text,
        at: DateTime(2026, 7, 30, 10),
        kind: kind,
      );

  testWidgets('Systemnachricht wird als ChatSystemCard gerendert',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: [nachricht('s1', ChatMessageKind.system, text: 'Storniert')],
          onSend: (_) {},
        ),
      ),
    ));
    expect(find.byType(ChatSystemCard), findsOneWidget);
    expect(find.text('Storniert'), findsOneWidget);
  });

  testWidgets('custom geht an den Builder', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: [nachricht('c1', ChatMessageKind.custom)],
          onSend: (_) {},
          customMessageBuilder: (m) => Text('eigen ${m.id}'),
        ),
      ),
    ));
    expect(find.text('eigen c1'), findsOneWidget);
  });

  testWidgets('custom mit null-Rückgabe fällt auf die Blase zurück',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: [nachricht('c2', ChatMessageKind.custom, text: 'Rückfall')],
          onSend: (_) {},
          customMessageBuilder: (_) => null,
        ),
      ),
    ));
    expect(find.byType(MessageBubble), findsOneWidget);
    expect(find.text('Rückfall'), findsOneWidget);
  });

  testWidgets('composerBanner und composerLeading erscheinen', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: [nachricht('m1', ChatMessageKind.normal)],
          onSend: (_) {},
          composerBanner: const ChatBanner(text: 'Nur SMS möglich'),
          composerLeading: const Icon(Icons.tune_rounded),
        ),
      ),
    ));
    expect(find.text('Nur SMS möglich'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
  });

  testWidgets('composerBanner sitzt über dem Eingabefeld', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: [nachricht('m1', ChatMessageKind.normal)],
          onSend: (_) {},
          composerBanner: const ChatBanner(text: 'Nur SMS möglich'),
        ),
      ),
    ));
    final bannerTop = tester.getTopLeft(find.text('Nur SMS möglich')).dy;
    final fieldTop = tester.getTopLeft(find.byType(TextField)).dy;
    expect(bannerTop, lessThan(fieldTop));
  });

  testWidgets('readOnly verbirgt das Eingabefeld', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: [nachricht('m1', ChatMessageKind.normal)],
          onSend: (_) {},
          readOnly: true,
        ),
      ),
    ));
    expect(find.byType(Composer), findsNothing);
  });

  testWidgets(
      'strings-Override setzt sich gegen einen ukrainischen Kontext durch',
      (tester) async {
    final failed = ChatMessage(
      id: 'm2',
      direction: MessageDirection.outgoing,
      text: 'x',
      at: DateTime(2026, 7, 30, 10),
      errorText: 'Fehlgeschlagen',
    );
    await tester.pumpWidget(localeHost(
      ChatThreadView(
        messages: [nachricht('m1', ChatMessageKind.normal), failed],
        onSend: (_) {},
        onRetry: (_) {},
        now: DateTime(2026, 7, 30, 10),
        strings: const ChatStrings.de(),
      ),
      locale: const Locale('uk'),
    ));
    // Die Blase spielt eine Eintritts-Animation; erst danach ist der
    // Retry-Text sicher im Baum.
    await tester.pumpAndSettle();

    // DateSeparator: deutsches "Heute" statt ukrainischem "Сьогодні".
    expect(find.text('Heute'), findsOneWidget);
    expect(find.text('Сьогодні'), findsNothing);

    // MessageBubble: deutscher Retry-Text statt ukrainischem.
    expect(find.text('Erneut senden'), findsOneWidget);

    // Composer: deutscher Platzhaltertext statt ukrainischem.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, 'Nachricht');
  });

  testWidgets('composerBanner bleibt bei readOnly sichtbar, Eingabefeld nicht',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: [nachricht('m1', ChatMessageKind.normal)],
          onSend: (_) {},
          readOnly: true,
          composerBanner: const ChatBanner(text: 'Konversation geschlossen'),
        ),
      ),
    ));
    expect(find.text('Konversation geschlossen'), findsOneWidget);
    expect(find.byType(Composer), findsNothing);
  });
}
