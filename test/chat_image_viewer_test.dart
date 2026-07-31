import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

final _pixel = MemoryImage(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='));

ImageProvider _lokal(String url) => _pixel;

const _theme = ChatTheme(imageProvider: _lokal);

void main() {
  testWidgets('zeigt Zähler und blättert, schließt bei Tipp', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold(body: SizedBox());
      }),
    ));

    showChatImageViewer(ctx,
        urls: const ['a', 'b', 'c'], index: 1, theme: _theme);
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsOneWidget);

    await tester.tapAt(const Offset(20, 300));
    await tester.pumpAndSettle();
    expect(find.text('3 / 3'), findsNothing);
  });

  testWidgets('bei einem einzigen Bild kein Zähler', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold(body: SizedBox());
      }),
    ));
    showChatImageViewer(ctx, urls: const ['a'], theme: _theme);
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsNothing);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('Profilbild öffnet sich beim Antippen', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ChatAvatar(
              name: 'Ada', theme: _theme, avatarUrl: 'https://x/ada.jpg'),
        ),
      ),
    ));
    await tester.tap(find.byType(ChatAvatar));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('Monogramm ohne Bild lässt sich nicht öffnen', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(child: ChatAvatar(name: 'Ada', theme: _theme)),
      ),
    ));
    await tester.tap(find.byType(ChatAvatar));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('onTap ersetzt das Öffnen', (tester) async {
    var getippt = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: ChatAvatar(
            name: 'Ada',
            theme: _theme,
            avatarUrl: 'https://x/ada.jpg',
            onTap: () => getippt = true,
          ),
        ),
      ),
    ));
    await tester.tap(find.byType(ChatAvatar));
    await tester.pumpAndSettle();
    expect(getippt, isTrue);
    expect(find.byType(InteractiveViewer), findsNothing);
  });
}
