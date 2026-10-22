import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

import 'locale_host.dart';

ChatAttachment _voice() => const ChatAttachment(
      kind: AttachmentKind.audio,
      url: 'https://x/a.ogg',
      contentType: 'audio/ogg',
    );

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('zeigt einen Platzhalter, solange die Dauer unbekannt ist', (tester) async {
    await tester.pumpWidget(_host(VoiceBubble(
      attachment: _voice(),
      messageId: 'm1',
      attachmentIndex: 0,
      theme: const ChatTheme.light(),
      ink: const ChatTheme.light().colors.incomingText,
    )));
    expect(find.text('--:--'), findsOneWidget);
  });

  testWidgets('zeigt die am Anhang bekannte Dauer ohne Player', (tester) async {
    await tester.pumpWidget(_host(VoiceBubble(
      attachment: _voice().copyWith(duration: const Duration(seconds: 42)),
      messageId: 'm1',
      attachmentIndex: 0,
      theme: const ChatTheme.light(),
      ink: const ChatTheme.light().colors.incomingText,
    )));
    expect(find.text('00:42'), findsOneWidget);
    expect(find.text('--:--'), findsNothing);
  });

  testWidgets('die Dauer des Players gewinnt gegen die des Anhangs', (tester) async {
    await tester.pumpWidget(_host(VoiceBubble(
      attachment: _voice().copyWith(duration: const Duration(seconds: 42)),
      messageId: 'm1',
      attachmentIndex: 0,
      theme: const ChatTheme.light(),
      ink: const ChatTheme.light().colors.incomingText,
      playback: const ChatAudioPlayback(
        messageId: 'm1',
        duration: Duration(seconds: 75),
      ),
    )));
    expect(find.text('01:15'), findsOneWidget);
    expect(find.text('00:42'), findsNothing);
  });

  testWidgets('mit nur der Anhangs-Dauer ist der Balken nicht ziehbar', (tester) async {
    Duration? gezogen;
    await tester.pumpWidget(_host(SizedBox(
      width: 300,
      child: VoiceBubble(
        attachment: _voice().copyWith(duration: const Duration(seconds: 42)),
        messageId: 'm1',
        attachmentIndex: 0,
        theme: const ChatTheme.light(),
        ink: const ChatTheme.light().colors.incomingText,
        onSeek: (d) => gezogen = d,
      ),
    )));
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
    expect(gezogen, isNull);
  });

  testWidgets('zeigt die gemeldete Dauer, sobald sie da ist', (tester) async {
    await tester.pumpWidget(_host(VoiceBubble(
      attachment: _voice(),
      messageId: 'm1',
      attachmentIndex: 0,
      theme: const ChatTheme.light(),
      ink: const ChatTheme.light().colors.incomingText,
      playback: const ChatAudioPlayback(
        messageId: 'm1',
        duration: Duration(seconds: 75),
      ),
    )));
    expect(find.text('01:15'), findsOneWidget);
  });

  testWidgets('zeigt beim Abspielen die verstrichene Zeit', (tester) async {
    await tester.pumpWidget(_host(VoiceBubble(
      attachment: _voice(),
      messageId: 'm1',
      attachmentIndex: 0,
      theme: const ChatTheme.light(),
      ink: const ChatTheme.light().colors.incomingText,
      playback: const ChatAudioPlayback(
        messageId: 'm1',
        state: ChatAudioState.playing,
        position: Duration(seconds: 5),
        duration: Duration(seconds: 75),
      ),
    )));
    expect(find.text('00:05'), findsOneWidget);
  });

  testWidgets('Tippen auf den Knopf loest onToggle aus', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(VoiceBubble(
      attachment: _voice(),
      messageId: 'm1',
      attachmentIndex: 0,
      theme: const ChatTheme.light(),
      ink: const ChatTheme.light().colors.incomingText,
      onToggle: () => taps++,
    )));
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('beim Abspielen steht das Pause-Symbol', (tester) async {
    await tester.pumpWidget(_host(VoiceBubble(
      attachment: _voice(),
      messageId: 'm1',
      attachmentIndex: 0,
      theme: const ChatTheme.light(),
      ink: const ChatTheme.light().colors.incomingText,
      playback: const ChatAudioPlayback(
        messageId: 'm1',
        state: ChatAudioState.playing,
        duration: Duration(seconds: 10),
      ),
    )));
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });

  testWidgets('beim Laden ein Fortschrittsring statt eines Knopfes', (tester) async {
    await tester.pumpWidget(_host(VoiceBubble(
      attachment: _voice(),
      messageId: 'm1',
      attachmentIndex: 0,
      theme: const ChatTheme.light(),
      ink: const ChatTheme.light().colors.incomingText,
      playback: const ChatAudioPlayback(
        messageId: 'm1',
        state: ChatAudioState.loading,
      ),
    )));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
  });

  testWidgets('Ziehen am Balken meldet die Zielposition', (tester) async {
    Duration? sought;
    await tester.pumpWidget(_host(SizedBox(
      width: 300,
      child: VoiceBubble(
        attachment: _voice(),
        messageId: 'm1',
        attachmentIndex: 0,
        theme: const ChatTheme.light(),
        ink: const ChatTheme.light().colors.incomingText,
        playback: const ChatAudioPlayback(
          messageId: 'm1',
          state: ChatAudioState.playing,
          duration: Duration(seconds: 100),
        ),
        onSeek: (d) => sought = d,
      ),
    )));
    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);
    await tester.tapAt(tester.getCenter(slider));
    await tester.pump();
    expect(sought, isNotNull);
  });

  testWidgets('ohne bekannte Dauer ist der Balken nicht ziehbar', (tester) async {
    await tester.pumpWidget(_host(VoiceBubble(
      attachment: _voice(),
      messageId: 'm1',
      attachmentIndex: 0,
      theme: const ChatTheme.light(),
      ink: const ChatTheme.light().colors.incomingText,
      onSeek: (_) {},
    )));
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
  });

  testWidgets('der Tempo-Chip laeuft 1x -> 1,5x -> 2x -> 1x', (tester) async {
    final speeds = <double>[];
    await tester.pumpWidget(_host(VoiceBubble(
      attachment: _voice(),
      messageId: 'm1',
      attachmentIndex: 0,
      theme: const ChatTheme.light(),
      ink: const ChatTheme.light().colors.incomingText,
      playback: const ChatAudioPlayback(
        messageId: 'm1',
        state: ChatAudioState.playing,
        duration: Duration(seconds: 10),
      ),
      onSpeed: speeds.add,
    )));
    await tester.tap(find.text('1×'));
    await tester.pump();
    expect(speeds, [1.5]);
  });

  testWidgets('der Tempo-Chip erscheint nur, wenn diese Nachricht laeuft', (tester) async {
    await tester.pumpWidget(_host(VoiceBubble(
      attachment: _voice(),
      messageId: 'm1',
      attachmentIndex: 0,
      theme: const ChatTheme.light(),
      ink: const ChatTheme.light().colors.incomingText,
      onSpeed: (_) {},
    )));
    expect(find.text('1×'), findsNothing);
  });

  testWidgets('MessageBubble rendert einen Audio-Anhang als Sprachblase, nicht als Datei-Zeile',
      (tester) async {
    await tester.pumpWidget(_host(MessageBubble(
      message: ChatMessage(
        id: 'm1',
        direction: MessageDirection.incoming,
        text: '',
        at: DateTime(2026, 8, 30, 12),
        attachments: [_voice()],
      ),
    )));
    expect(find.byType(VoiceBubble), findsOneWidget);
    expect(find.byIcon(Icons.insert_drive_file_outlined), findsNothing);
  });

  testWidgets('Dauer ueber eine Stunde', (tester) async {
    await tester.pumpWidget(_host(VoiceBubble(
      attachment: _voice(),
      messageId: 'm1',
      attachmentIndex: 0,
      theme: const ChatTheme.light(),
      ink: const ChatTheme.light().colors.incomingText,
      playback: const ChatAudioPlayback(
        messageId: 'm1',
        duration: Duration(minutes: 75, seconds: 3),
      ),
    )));
    expect(find.text('75:03'), findsOneWidget);
  });

  for (final (locale, text) in [
    (const Locale('en'), '1.5×'),
    (const Locale('de'), '1,5×'),
  ]) {
    testWidgets('Tempo-Chip folgt der Sprache ${locale.languageCode}', (tester) async {
      await tester.pumpWidget(localeHost(
        VoiceBubble(
          attachment: _voice(),
          messageId: 'm1',
          attachmentIndex: 0,
          theme: const ChatTheme.light(),
          ink: const ChatTheme.light().colors.incomingText,
          onSpeed: (_) {},
          playback: const ChatAudioPlayback(
            messageId: 'm1',
            state: ChatAudioState.paused,
            speed: 1.5,
          ),
        ),
        locale: locale,
      ));
      expect(find.text(text), findsOneWidget);
    });
  }

  testWidgets('failed zeigt Fehlersymbol und Text', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(VoiceBubble(
      attachment: _voice(),
      messageId: 'm1',
      attachmentIndex: 0,
      theme: const ChatTheme.light(),
      ink: const ChatTheme.light().colors.incomingText,
      onToggle: () => taps++,
      playback: const ChatAudioPlayback(
        messageId: 'm1',
        state: ChatAudioState.failed,
      ),
    )));
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.byTooltip(const ChatStrings.en().voicePlaybackFailed), findsOneWidget);
    await tester.tap(find.byIcon(Icons.error_outline_rounded));
    expect(taps, 1);
  });
}
