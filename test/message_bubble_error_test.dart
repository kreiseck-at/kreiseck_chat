import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

ChatMessage _failed({String errorText = 'Nicht zugestellt'}) => ChatMessage(
      id: 'm1',
      direction: MessageDirection.outgoing,
      text: 'Bin in fünf Minuten da',
      at: DateTime(2026, 1, 1, 14, 32),
      errorText: errorText,
    );

// The framework's Default(Material|Widgets)Localizations only declare
// themselves supported for 'en' (see their isSupported overrides), so a
// plain Localizations(locale: de, delegates: [Default...]) drops out of
// Localizations.of<MaterialLocalizations> entirely -- fine for ChatStrings
// (which only reads the locale field, not the resource map), but it makes
// ChatThreadView's composer TextField throw "No MaterialLocalizations
// found." These wrappers hand back the very same English-only resources,
// just without gating on the locale, so a German ambient locale can coexist
// with a TextField in a test without depending on flutter_localizations.
class _AnyLocaleWidgetsLocalizations
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _AnyLocaleWidgetsLocalizations();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      DefaultWidgetsLocalizations.load(locale);
  @override
  bool shouldReload(_AnyLocaleWidgetsLocalizations old) => false;
}

class _AnyLocaleMaterialLocalizations
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _AnyLocaleMaterialLocalizations();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);
  @override
  bool shouldReload(_AnyLocaleMaterialLocalizations old) => false;
}

/// Wraps [child] so [ChatStrings.of] resolves to [locale], while widgets
/// that need [MaterialLocalizations] (like the composer's TextField) keep
/// working -- see the delegates above for why the plain Default delegates
/// alone are not enough here.
Widget _germanLocaleHost(Widget child) => MaterialApp(
      home: Localizations(
        locale: const Locale('de'),
        delegates: const [
          _AnyLocaleWidgetsLocalizations(),
          _AnyLocaleMaterialLocalizations(),
        ],
        child: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('the error line is readable on the dark background', (tester) async {
    const theme = ChatTheme.dark();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(messages: [_failed()], theme: theme, onSend: (_) {}),
      ),
    ));
    await tester.pump();

    final text = tester.widget<Text>(find.text('Nicht zugestellt'));
    expect(contrastRatio(text.style!.color!, theme.colors.background),
        greaterThanOrEqualTo(4.5));
  });

  testWidgets('with onRetry a retry action appears and calls back', (tester) async {
    var retried = 0;
    // ChatThreadView has no strings override yet -- pin the ambient locale
    // instead, so the button keeps reading the expected German text
    // regardless of the test host's default locale.
    await tester.pumpWidget(_germanLocaleHost(
      ChatThreadView(
        messages: [_failed()],
        theme: const ChatTheme.light(),
        onSend: (_) {},
        onRetry: (_) => retried++,
      ),
    ));
    // pumpAndSettle: the last (here, only) bubble in a ChatThreadView plays a
    // slide/fade entrance animation, so a bare pump() would still be mid-flight
    // and land the tap outside the button.
    await tester.pumpAndSettle();

    await tester.tap(find.text('Erneut senden'));
    await tester.pump();
    expect(retried, 1);
  });

  testWidgets('without onRetry only the reason is shown', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChatThreadView(
          messages: [_failed()],
          theme: const ChatTheme.light(),
          onSend: (_) {},
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Nicht zugestellt'), findsOneWidget);
    expect(find.text('Erneut senden'), findsNothing);
  });

  testWidgets('the retry action has an at-least 44x44 tap target', (tester) async {
    await tester.pumpWidget(_germanLocaleHost(
      ChatThreadView(
        messages: [_failed()],
        theme: const ChatTheme.light(),
        onSend: (_) {},
        onRetry: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    final size =
        tester.getSize(find.widgetWithText(TextButton, 'Erneut senden'));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets(
      'a very long failure reason does not overflow the row on a narrow, '
      'larger-text device', (tester) async {
    // A narrow, common device width (360dp) combined with the largest
    // common accessibility text scale (2x): without a bound on the reason
    // text, a long sentence used to wrap into dozens of lines and blow past
    // any bounded host -- the retry action must keep its footprint and the
    // reason must give way (wrap/truncate) instead.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          textScaler: TextScaler.linear(2.0),
        ),
        child: Scaffold(
          body: MessageBubble(
            message: _failed(
              errorText: 'Die Zustellung ist fehlgeschlagen, weil der '
                  'Empfänger vorübergehend nicht erreichbar war und der '
                  'Server nach mehreren Versuchen aufgegeben hat',
            ),
            onRetry: () {},
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
