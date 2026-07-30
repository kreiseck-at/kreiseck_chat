import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  test('Vorlagen setzen id, label, icon und color', () {
    const wa = ChatChannel.whatsApp();
    expect(wa.id, 'whatsapp');
    expect(wa.label, 'WhatsApp');
    expect(wa.color, const Color(0xFF25D366));

    const sms = ChatChannel.sms();
    expect(sms.id, 'sms');
    expect(sms.label, 'SMS');

    expect(const ChatChannel.email().id, 'email');
    expect(const ChatChannel.inApp().id, 'inapp');
    expect(const ChatChannel.voice().id, 'voice');
  });

  test('Label lässt sich übersetzen, id bleibt stabil', () {
    const wa = ChatChannel.whatsApp(label: 'WhatsApp Business');
    expect(wa.label, 'WhatsApp Business');
    expect(wa.id, 'whatsapp');
  });

  test('copyWith ersetzt nur das Angegebene', () {
    const wa = ChatChannel.whatsApp();
    final eigen = wa.copyWith(color: const Color(0xFF000000));
    expect(eigen.id, 'whatsapp');
    expect(eigen.label, 'WhatsApp');
    expect(eigen.color, const Color(0xFF000000));
    expect(eigen.icon, wa.icon);
  });

  test('Wertgleichheit', () {
    expect(const ChatChannel.sms(), const ChatChannel.sms());
    expect(const ChatChannel.sms().hashCode, const ChatChannel.sms().hashCode);
    expect(const ChatChannel.sms() == const ChatChannel.email(), isFalse);
  });

  test('eigener Kanal ohne Vorlage', () {
    const eigen = ChatChannel(
      id: 'fax',
      label: 'Fax',
      icon: Icons.print_rounded,
      color: Color(0xFF123456),
    );
    expect(eigen.id, 'fax');
  });
}
