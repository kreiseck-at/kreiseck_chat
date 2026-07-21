/// Visual preset for message bubbles, controlling tail, corners, and the
/// placement of time/status.
enum BubbleStyle {
  /// Tailed bubbles, time + ticks inside the bubble's bottom-right.
  whatsApp,

  /// Continuous rounded bubbles, time as a separate light row, tapback-style
  /// reactions overlapping the corner.
  iMessage,

  /// No tail, uniform corners — a neutral base for custom branding.
  minimal,
}
