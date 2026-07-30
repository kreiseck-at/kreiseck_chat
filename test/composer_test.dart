import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

// 1x1 transparentes PNG -- gültige Bytes, damit MemoryImage im Test nicht wirft.
final _pixel = MemoryImage(base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='));

void _mockHaptics(WidgetTester tester, List<String> sink) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        sink.add(call.arguments as String? ?? '');
      }
      return null;
    },
  );
  addTearDown(() {
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

void main() {
  testWidgets('attach button hidden when media capability off', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          capabilities: const ChatCapabilities.twilioSms(),
        ),
      ),
    ));
    expect(find.byIcon(const ChatIcons().attach), findsNothing);
  });

  testWidgets('attach button shown when media capability on', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          capabilities: const ChatCapabilities.inApp(),
          onAttach: (_) {},
        ),
      ),
    ));
    expect(find.byIcon(const ChatIcons().attach), findsOneWidget);
  });

  testWidgets('send button appears only when there is text', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Composer(onSend: (_) {})),
    ));
    // Empty: no send button.
    expect(find.byIcon(const ChatIcons().send), findsNothing);
    await _type(tester, 'hallo');
    // Typing: send button visible.
    expect(find.byIcon(const ChatIcons().send), findsOneWidget);
  });

  testWidgets('empty field without media/mic shows a disabled send button',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          capabilities: const ChatCapabilities.twilioSms(), // media & mic off
        ),
      ),
    ));
    // Send icon present but disabled (no camera to show instead).
    expect(find.byIcon(const ChatIcons().send), findsOneWidget);
    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(const ChatIcons().send),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
    // Becomes active once there is text.
    await _type(tester, 'hallo');
    final active = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(const ChatIcons().send),
        matching: find.byType(IconButton),
      ),
    );
    expect(active.onPressed, isNotNull);
  });

  testWidgets('camera shortcut shown when empty + media, hidden while typing',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          capabilities: const ChatCapabilities.inApp(),
          onAttach: (_) {},
        ),
      ),
    ));
    expect(find.byIcon(const ChatIcons().camera), findsOneWidget);
    await _type(tester, 'hallo');
    expect(find.byIcon(const ChatIcons().camera), findsNothing);
  });

  testWidgets('camera shortcut fires onAttach(camera)', (tester) async {
    final sources = <AttachSource>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          capabilities: const ChatCapabilities.inApp(),
          onAttach: sources.add,
        ),
      ),
    ));
    await tester.tap(find.byIcon(const ChatIcons().camera));
    await tester.pump();
    expect(sources, [AttachSource.camera]);
  });

  testWidgets('input uses sentence capitalization by default', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Composer(onSend: (_) {})),
    ));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.textCapitalization, TextCapitalization.sentences);
  });

  testWidgets('enter inserts a newline by default (no send on enter)',
      (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Composer(onSend: sent.add)),
    ));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.textInputAction, TextInputAction.newline);
    await _type(tester, 'hallo');
    await tester.testTextInput.receiveAction(TextInputAction.newline);
    await tester.pump();
    expect(sent, isEmpty);
  });

  testWidgets('send button clears field and calls onSend', (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Composer(onSend: sent.add)),
    ));
    await _type(tester, 'hallo');
    await tester.tap(find.byIcon(const ChatIcons().send));
    await tester.pumpAndSettle();
    expect(sent, ['hallo']);
    expect(find.text('hallo'), findsNothing);
  });

  testWidgets('onTypingChanged fires true then false', (tester) async {
    final events = <bool>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Composer(onSend: (_) {}, onTypingChanged: events.add)),
    ));
    await tester.enterText(find.byType(TextField), 'h');
    await tester.enterText(find.byType(TextField), '');
    expect(events.first, isTrue);
    expect(events.last, isFalse);
  });

  testWidgets('send fires a haptic by default', (tester) async {
    final haptics = <String>[];
    _mockHaptics(tester, haptics);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Composer(onSend: (_) {})),
    ));
    await _type(tester, 'hallo');
    await tester.tap(find.byIcon(const ChatIcons().send));
    await tester.pumpAndSettle();
    expect(haptics, isNotEmpty);
  });

  testWidgets('send haptic stays silent when motion is none', (tester) async {
    final haptics = <String>[];
    _mockHaptics(tester, haptics);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          theme: ChatTheme.light().copyWith(motion: const ChatMotion.none()),
        ),
      ),
    ));
    await _type(tester, 'hallo');
    await tester.tap(find.byIcon(const ChatIcons().send));
    await tester.pumpAndSettle();
    expect(haptics, isEmpty);
  });

  testWidgets('pending attachments enable send with an empty field', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          capabilities: const ChatCapabilities.inApp(),
          onAttach: (_) {},
          attachmentPreviews: [_pixel],
        ),
      ),
    ));
    // Empty text but a pending photo: send shows, camera shortcut hides.
    expect(find.byIcon(const ChatIcons().send), findsOneWidget);
    expect(find.byIcon(const ChatIcons().camera), findsNothing);
  });

  testWidgets('multiple pending attachments each render a thumbnail + an add tile',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          capabilities: const ChatCapabilities.inApp(),
          onAttach: (_) {},
          attachmentPreviews: [_pixel, _pixel],
          onRemoveAttachmentAt: (_) {},
          onAddAttachment: () {},
        ),
      ),
    ));
    // Two × remove buttons (one per thumbnail) + one "+" add tile.
    expect(find.byIcon(Icons.close), findsNWidgets(2));
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('sending with only an attachment calls onSend with empty text',
      (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: sent.add,
          capabilities: const ChatCapabilities.inApp(),
          onAttach: (_) {},
          attachmentPreviews: [_pixel],
        ),
      ),
    ));
    await tester.tap(find.byIcon(const ChatIcons().send));
    await tester.pumpAndSettle();
    expect(sent, ['']);
  });

  testWidgets('tapping × on a thumbnail fires onRemoveAttachmentAt with its index',
      (tester) async {
    final removed = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          capabilities: const ChatCapabilities.inApp(),
          onAttach: (_) {},
          attachmentPreviews: [_pixel, _pixel],
          onRemoveAttachmentAt: removed.add,
          onAddAttachment: () {},
        ),
      ),
    ));
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pump();
    expect(removed, [0]);
  });

  testWidgets('tapping the + tile fires onAddAttachment', (tester) async {
    var added = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          capabilities: const ChatCapabilities.inApp(),
          onAttach: (_) {},
          attachmentPreviews: [_pixel],
          onAddAttachment: () => added++,
        ),
      ),
    ));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(added, 1);
  });

  testWidgets('send button is wrapped in a ScaleTransition', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Composer(onSend: (_) {})),
    ));
    await _type(tester, 'hallo');
    final scaleTransition = find.ancestor(
      of: find.byIcon(const ChatIcons().send),
      matching: find.byType(ScaleTransition),
    );
    expect(scaleTransition, findsOneWidget);
  });

  testWidgets('leading erscheint links im Eingabefeld', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Composer(
          onSend: (_) {},
          leading: const Icon(Icons.tune_rounded),
        ),
      ),
    ));
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
  });
}
