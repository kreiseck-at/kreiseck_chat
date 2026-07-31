import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  testWidgets('volle Form zeigt Symbol und Label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatChannelBadge(channel: ChatChannel.whatsApp()),
      ),
    ));
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.byIcon(Icons.chat_rounded), findsOneWidget);
  });

  testWidgets('kompakte Form zeigt nur das Symbol', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatChannelBadge(channel: ChatChannel.sms(), compact: true),
      ),
    ));
    expect(find.byIcon(Icons.sms_rounded), findsOneWidget);
    expect(find.text('SMS'), findsNothing);
  });

  testWidgets('mit surface wird die Kanalfarbe auf ihr lesbar gemacht',
      (tester) async {
    // Blaue Bubble aus der Prüfung: WhatsApp-Grün darauf maß dort nur 2,05:1.
    const surface = Color(0xFF3478F6);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatChannelBadge(
          channel: ChatChannel.whatsApp(),
          compact: true,
          surface: surface,
        ),
      ),
    ));
    final icon = tester.widget<Icon>(find.byIcon(Icons.chat_rounded));
    expect(icon.color, isNot(const Color(0xFF25D366)));
    expect(contrastRatio(icon.color!, surface), greaterThanOrEqualTo(3.0));
  });

  testWidgets('ohne surface bleibt die rohe Kanalfarbe erhalten (freistehend)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ChatChannelBadge(channel: ChatChannel.whatsApp(), compact: true),
      ),
    ));
    final icon = tester.widget<Icon>(find.byIcon(Icons.chat_rounded));
    expect(icon.color, const Color(0xFF25D366));
  });

  testWidgets('langes Label wird gekürzt, ohne Fehler', (tester) async {
    final longChannel = ChatChannel.whatsApp(label: 'A' * 100);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 80,
            child: ChatChannelBadge(channel: longChannel),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.chat_rounded), findsOneWidget);
  });
}
