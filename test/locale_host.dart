import 'package:flutter/material.dart';

// The framework's Default(Material|Widgets)Localizations only declare
// themselves supported for 'en' (see their isSupported overrides), so a
// plain Localizations(locale: xx, delegates: [Default...]) drops out of
// Localizations.of<MaterialLocalizations> entirely for any other language --
// fine for ChatStrings (which only reads the locale field, not the resource
// map), but it makes anything with a TextField (like the composer) throw "No
// MaterialLocalizations found." These wrappers hand back the very same
// English-only resources, just without gating on the locale, so a non-English
// ambient locale can coexist with a TextField in a test without depending on
// flutter_localizations.
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
Widget localeHost(Widget child, {required Locale locale}) => MaterialApp(
      home: Localizations(
        locale: locale,
        delegates: const [
          _AnyLocaleWidgetsLocalizations(),
          _AnyLocaleMaterialLocalizations(),
        ],
        child: Scaffold(body: child),
      ),
    );
