import 'package:flutter/material.dart';

/// Text styles used by the chat widgets.
class ChatTypography {
  /// Creates a typography set. Defaults are reasonable standalone values;
  /// prefer [ChatTypography.fromTextTheme] to inherit the ambient theme.
  const ChatTypography({
    this.body = const TextStyle(fontSize: 15, height: 1.3),
    this.timestamp = const TextStyle(fontSize: 11),
    this.senderName = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    this.dateSeparator = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    this.systemMessage = const TextStyle(fontSize: 12),
    this.headerTitle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    this.headerSubtitle = const TextStyle(fontSize: 12),
    this.replyQuote = const TextStyle(fontSize: 13),
    this.reaction = const TextStyle(fontSize: 16, height: 1.1),
  });

  /// Message body text.
  final TextStyle body;

  /// In-bubble timestamp.
  final TextStyle timestamp;

  /// Sender name in group threads.
  final TextStyle senderName;

  /// Date separator pill label.
  final TextStyle dateSeparator;

  /// System/notice message text.
  final TextStyle systemMessage;

  /// Header title (contact/group name).
  final TextStyle headerTitle;

  /// Header subtitle (presence / typing line).
  final TextStyle headerSubtitle;

  /// Quoted reply preview text.
  final TextStyle replyQuote;

  /// Emoji and count inside a reaction chip.
  final TextStyle reaction;

  /// Derives a typography set from an ambient [TextTheme].
  factory ChatTypography.fromTextTheme(TextTheme t) {
    return ChatTypography(
      body: t.bodyMedium ?? const TextStyle(fontSize: 15, height: 1.3),
      timestamp: (t.labelSmall ?? const TextStyle(fontSize: 11)).copyWith(
        fontSize: 11,
      ),
      senderName: (t.labelMedium ?? const TextStyle()).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      dateSeparator: (t.labelMedium ?? const TextStyle()).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      systemMessage: t.bodySmall ?? const TextStyle(fontSize: 12),
      headerTitle: (t.titleMedium ?? const TextStyle()).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      headerSubtitle: t.bodySmall ?? const TextStyle(fontSize: 12),
      replyQuote: t.bodySmall ?? const TextStyle(fontSize: 13),
      reaction: (t.bodyMedium ?? const TextStyle()).copyWith(
        fontSize: 16,
        height: 1.1,
      ),
    );
  }

  /// Returns a copy with the given fields replaced.
  ChatTypography copyWith({
    TextStyle? body,
    TextStyle? timestamp,
    TextStyle? senderName,
    TextStyle? dateSeparator,
    TextStyle? systemMessage,
    TextStyle? headerTitle,
    TextStyle? headerSubtitle,
    TextStyle? replyQuote,
    TextStyle? reaction,
  }) {
    return ChatTypography(
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      senderName: senderName ?? this.senderName,
      dateSeparator: dateSeparator ?? this.dateSeparator,
      systemMessage: systemMessage ?? this.systemMessage,
      headerTitle: headerTitle ?? this.headerTitle,
      headerSubtitle: headerSubtitle ?? this.headerSubtitle,
      replyQuote: replyQuote ?? this.replyQuote,
      reaction: reaction ?? this.reaction,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatTypography &&
        other.body == body &&
        other.timestamp == timestamp &&
        other.senderName == senderName &&
        other.dateSeparator == dateSeparator &&
        other.systemMessage == systemMessage &&
        other.headerTitle == headerTitle &&
        other.headerSubtitle == headerSubtitle &&
        other.replyQuote == replyQuote &&
        other.reaction == reaction;
  }

  @override
  int get hashCode => Object.hash(
    body,
    timestamp,
    senderName,
    dateSeparator,
    systemMessage,
    headerTitle,
    headerSubtitle,
    replyQuote,
    reaction,
  );
}
