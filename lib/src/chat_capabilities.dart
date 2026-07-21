/// Describes which chat UI affordances a channel supports.
///
/// Widgets read this to decide what to render — e.g. the reaction menu only
/// appears when [reactions] is true, the composer's attach button only when
/// [media] is true. Motion and haptics are configured separately in the theme.
class ChatCapabilities {
  /// Creates a capability set. All flags default to `false`; this is also the
  /// "custom" entry point — set exactly the flags a channel supports.
  const ChatCapabilities({
    this.reactions = false,
    this.replies = false,
    this.media = false,
    this.typingIndicator = false,
    this.presence = false,
    this.readReceipts = false,
  });

  /// Alias of the default constructor for readability at call sites.
  const ChatCapabilities.custom({
    bool reactions = false,
    bool replies = false,
    bool media = false,
    bool typingIndicator = false,
    bool presence = false,
    bool readReceipts = false,
  }) : this(
          reactions: reactions,
          replies: replies,
          media: media,
          typingIndicator: typingIndicator,
          presence: presence,
          readReceipts: readReceipts,
        );

  /// Classic Twilio SMS: plain text, delivery ceiling, nothing else.
  const ChatCapabilities.twilioSms()
      : reactions = false,
        replies = false,
        media = false,
        typingIndicator = false,
        presence = false,
        readReceipts = false;

  /// Twilio WhatsApp: media, inbound reactions, quoted replies, read receipts.
  /// No outbound typing signal and no presence in the Business API.
  const ChatCapabilities.twilioWhatsApp()
      : reactions = true,
        replies = true,
        media = true,
        typingIndicator = false,
        presence = false,
        readReceipts = true;

  /// Full in-app messaging: every affordance enabled.
  const ChatCapabilities.inApp()
      : reactions = true,
        replies = true,
        media = true,
        typingIndicator = true,
        presence = true,
        readReceipts = true;

  /// Whether long-press reactions and reaction chips are shown.
  final bool reactions;

  /// Whether swipe-to-reply and quoted-reply blocks are shown.
  final bool replies;

  /// Whether image bubbles and the composer attach button are shown.
  final bool media;

  /// Whether the typing indicator (bubble + list preview) is shown.
  final bool typingIndicator;

  /// Whether presence (online dot + "last seen") is shown.
  final bool presence;

  /// When false, an outgoing status icon never advances past
  /// [MessageStatus.delivered] even if the message reports `read`.
  final bool readReceipts;

  /// Returns a copy with the given flags replaced.
  ChatCapabilities copyWith({
    bool? reactions,
    bool? replies,
    bool? media,
    bool? typingIndicator,
    bool? presence,
    bool? readReceipts,
  }) {
    return ChatCapabilities(
      reactions: reactions ?? this.reactions,
      replies: replies ?? this.replies,
      media: media ?? this.media,
      typingIndicator: typingIndicator ?? this.typingIndicator,
      presence: presence ?? this.presence,
      readReceipts: readReceipts ?? this.readReceipts,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatCapabilities &&
        other.reactions == reactions &&
        other.replies == replies &&
        other.media == media &&
        other.typingIndicator == typingIndicator &&
        other.presence == presence &&
        other.readReceipts == readReceipts;
  }

  @override
  int get hashCode => Object.hash(
        reactions,
        replies,
        media,
        typingIndicator,
        presence,
        readReceipts,
      );
}
