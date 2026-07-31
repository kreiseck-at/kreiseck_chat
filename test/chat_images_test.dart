import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

void main() {
  test('ohne Zutun landen Bilder im Zwischenspeicher', () {
    final p = const ChatTheme().imageProvider('https://x/a.jpg');
    expect(p, isA<CachedNetworkImageProvider>());
    // Auch in den Vorlagen — sonst hinge es davon ab, wie der Host sein Thema
    // gebaut hat.
    expect(const ChatTheme.light().imageProvider('https://x/a.jpg'),
        isA<CachedNetworkImageProvider>());
    expect(const ChatTheme.dark().imageProvider('https://x/a.jpg'),
        isA<CachedNetworkImageProvider>());
  });

  test('Host kann das Laden austauschen', () {
    const ohne = ChatTheme(imageProvider: plainChatImage);
    expect(ohne.imageProvider('https://x/a.jpg'), isA<NetworkImage>());

    expect(const ChatTheme(imageProvider: _eigen).imageProvider('u'),
        isA<AssetImage>());
  });
}

ImageProvider _eigen(String url) => const AssetImage('x');
