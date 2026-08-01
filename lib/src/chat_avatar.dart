import 'package:flutter/material.dart';

import 'chat_image_viewer.dart';
import 'chat_participant.dart';
import 'chat_theme.dart';

/// Whether [value] looks like a phone number rather than a person/group name.
///
/// Used to decide the avatar fallback: phone-number contacts get a neutral
/// person icon instead of a meaningless "+"-monogram.
bool isPhoneNumberLike(String value) {
  final s = value.trim();
  if (s.isEmpty) return false;
  final digitCount = s.replaceAll(RegExp(r'\D'), '').length;
  if (digitCount < 6) return false;
  return RegExp(r'^[+()\d\s\-/.]+$').hasMatch(s);
}

/// A circular avatar that shows, in order of preference: the supplied image,
/// a neutral person icon for phone-number contacts, otherwise an initials
/// monogram derived from [name].
class ChatAvatar extends StatelessWidget {
  /// Creates an avatar.
  const ChatAvatar({
    super.key,
    required this.name,
    required this.theme,
    this.image,
    this.avatarUrl,
    this.radius = 20,
    this.onTap,
    this.openable = true,
  });

  /// Display name or contact used for the monogram / phone-number detection.
  final String name;

  /// Visual configuration.
  final ChatTheme theme;

  /// In-memory avatar image; wins over [avatarUrl].
  final ImageProvider? image;

  /// Remote avatar URL; used when [image] is null.
  final String? avatarUrl;

  /// Circle radius.
  final double radius;

  /// Called when the avatar is tapped. Overrides the built-in behavior of
  /// opening the picture full screen — pass one to open a profile instead.
  final VoidCallback? onTap;

  /// Whether tapping an avatar that HAS a picture opens it full screen (see
  /// [showChatImageViewer]). Ignored when [onTap] is set; irrelevant when
  /// there is only a monogram, which is nothing to enlarge.
  final bool openable;

  @override
  Widget build(BuildContext context) {
    final provider =
        image ?? (avatarUrl != null ? theme.imageProvider(avatarUrl!) : null);
    Widget? child;
    if (provider == null) {
      if (isPhoneNumberLike(name)) {
        child = Icon(Icons.person, color: theme.colors.accent, size: radius);
      } else {
        child = Text(
          ChatParticipant(id: name, displayName: name).initials,
          style: TextStyle(color: theme.colors.accent),
        );
      }
    }
    final kreis = CircleAvatar(
      radius: radius,
      backgroundColor: theme.colors.accent.withValues(alpha: 0.2),
      backgroundImage: provider,
      child: child,
    );

    // Ein Monogramm gibt es nicht zu vergrößern — nur ein echtes Bild.
    final oeffnen =
        onTap ??
        (openable && avatarUrl != null && image == null
            ? () =>
                  showChatImageViewer(context, urls: [avatarUrl!], theme: theme)
            : null);
    if (oeffnen == null) return kreis;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: oeffnen,
      child: kreis,
    );
  }
}
