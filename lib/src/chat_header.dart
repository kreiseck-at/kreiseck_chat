import 'package:flutter/material.dart';

import 'chat_avatar.dart';
import 'chat_capabilities.dart';
import 'chat_participant.dart';
import 'chat_strings.dart';
import 'chat_theme.dart';
import 'presence_label.dart';

/// A conversation header: avatar + title + presence/typing subtitle + actions.
class ChatHeader extends StatelessWidget {
  /// Creates a header.
  const ChatHeader({
    super.key,
    required this.title,
    required this.theme,
    this.avatar,
    this.avatarUrl,
    this.presence,
    this.typing = false,
    this.capabilities = const ChatCapabilities.inApp(),
    this.now,
    this.actions = const [],
    this.onBack,
    this.typingLabel,
    this.strings,
  });

  /// Contact/group name.
  final String title;

  /// Visual configuration.
  final ChatTheme theme;

  /// In-memory avatar; wins over [avatarUrl].
  final ImageProvider? avatar;

  /// Remote avatar URL.
  final String? avatarUrl;

  /// Presence for the subtitle.
  final ChatPresence? presence;

  /// Whether the counterpart is typing.
  final bool typing;

  /// Which affordances are allowed.
  final ChatCapabilities capabilities;

  /// Injectable "now" for presence formatting.
  final DateTime? now;

  /// Trailing action widgets.
  final List<Widget> actions;

  /// Optional back handler (renders a back button when set).
  final VoidCallback? onBack;

  /// Label shown while typing. Left null, it follows [ChatStrings.typing]
  /// for the ambient locale (see [strings]).
  final String? typingLabel;

  /// Overrides the words used by this header. Left null, they follow the
  /// ambient locale (see [ChatStrings.of]).
  final ChatStrings? strings;

  String? _subtitle(ChatStrings resolved) {
    if (typing && capabilities.typingIndicator) {
      return typingLabel ?? resolved.typing;
    }
    if (capabilities.presence) {
      return formatPresenceLabel(presence, now: now ?? DateTime.now());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ChatStrings.of(context, override: strings);
    final subtitle = _subtitle(resolved);
    return Material(
      color: theme.colors.composer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ),
              ChatAvatar(
                name: title,
                theme: theme,
                image: avatar,
                avatarUrl: avatarUrl,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: theme.typography.headerTitle
                            .copyWith(color: theme.colors.incomingText)),
                    if (subtitle != null)
                      Text(subtitle,
                          style: theme.typography.headerSubtitle.copyWith(
                              color: theme.colors.incomingText
                                  .withValues(alpha: 0.6))),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
