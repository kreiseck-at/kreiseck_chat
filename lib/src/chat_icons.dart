import 'package:flutter/material.dart';

/// Icon set used by the chat widgets; swap for a different family (e.g.
/// Cupertino) by supplying overrides.
class ChatIcons {
  /// Creates an icon set (defaults to Material icons).
  const ChatIcons({
    this.send = Icons.send_rounded,
    this.attach = Icons.attach_file_rounded,
    this.camera = Icons.photo_camera_rounded,
    this.mic = Icons.mic_none_rounded,
    this.sent = Icons.done,
    this.delivered = Icons.done_all,
    this.read = Icons.done_all,
    this.reply = Icons.reply_rounded,
    this.copy = Icons.copy_rounded,
    this.error = Icons.error_outline,
  });

  /// Send button.
  final IconData send;

  /// Attach (file) button.
  final IconData attach;

  /// Camera button.
  final IconData camera;

  /// Voice message button (placeholder in v1).
  final IconData mic;

  /// Status: sent.
  final IconData sent;

  /// Status: delivered.
  final IconData delivered;

  /// Status: read (tinted with accent).
  final IconData read;

  /// Reply action.
  final IconData reply;

  /// Copy-to-clipboard action.
  final IconData copy;

  /// Status: failed.
  final IconData error;

  /// Returns a copy with the given fields replaced.
  ChatIcons copyWith({
    IconData? send,
    IconData? attach,
    IconData? camera,
    IconData? mic,
    IconData? sent,
    IconData? delivered,
    IconData? read,
    IconData? reply,
    IconData? copy,
    IconData? error,
  }) {
    return ChatIcons(
      send: send ?? this.send,
      attach: attach ?? this.attach,
      camera: camera ?? this.camera,
      mic: mic ?? this.mic,
      sent: sent ?? this.sent,
      delivered: delivered ?? this.delivered,
      read: read ?? this.read,
      reply: reply ?? this.reply,
      copy: copy ?? this.copy,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatIcons &&
        other.send == send &&
        other.attach == attach &&
        other.camera == camera &&
        other.mic == mic &&
        other.sent == sent &&
        other.delivered == delivered &&
        other.read == read &&
        other.reply == reply &&
        other.copy == copy &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
      send, attach, camera, mic, sent, delivered, read, reply, copy, error);
}
