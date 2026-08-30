import 'package:flutter/foundation.dart';

/// What a voice message is currently doing.
enum ChatAudioState {
  /// Nothing loaded, or playback finished.
  idle,

  /// The source is being prepared.
  loading,

  /// Audible right now.
  playing,

  /// Loaded and stopped, position kept.
  paused,
}

/// The playback state of exactly one voice attachment.
///
/// Backend- and plugin-agnostic: it carries no player, only what the bubble
/// needs to draw itself.
@immutable
class ChatAudioPlayback {
  /// Creates a playback state.
  const ChatAudioPlayback({
    required this.messageId,
    this.attachmentIndex = 0,
    this.state = ChatAudioState.idle,
    this.position = Duration.zero,
    this.duration,
    this.speed = 1.0,
  });

  /// The message this playback belongs to.
  final String messageId;

  /// Which attachment of that message — a message can carry several.
  final int attachmentIndex;

  /// What playback is doing.
  final ChatAudioState state;

  /// How far in.
  final Duration position;

  /// Total length, or null while still unknown. The bubble shows a placeholder
  /// rather than a made-up number until the player reports it.
  final Duration? duration;

  /// Playback rate, 1.0 being normal speed.
  final double speed;

  /// Returns a copy with the given fields replaced. Passing
  /// `clearDuration: true` sets [duration] back to null.
  ChatAudioPlayback copyWith({
    String? messageId,
    int? attachmentIndex,
    ChatAudioState? state,
    Duration? position,
    Duration? duration,
    bool clearDuration = false,
    double? speed,
  }) {
    assert(
      !(clearDuration && duration != null),
      'clearDuration und ein duration-Wert schließen sich aus.',
    );
    return ChatAudioPlayback(
      messageId: messageId ?? this.messageId,
      attachmentIndex: attachmentIndex ?? this.attachmentIndex,
      state: state ?? this.state,
      position: position ?? this.position,
      duration: clearDuration ? null : (duration ?? this.duration),
      speed: speed ?? this.speed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatAudioPlayback &&
        other.messageId == messageId &&
        other.attachmentIndex == attachmentIndex &&
        other.state == state &&
        other.position == position &&
        other.duration == duration &&
        other.speed == speed;
  }

  @override
  int get hashCode => Object.hash(
    messageId,
    attachmentIndex,
    state,
    position,
    duration,
    speed,
  );
}

/// Holds voice-playback state for a thread and enforces the one rule every
/// host would otherwise reimplement: **only one voice message plays at a
/// time**.
///
/// The package deliberately ships no audio plugin. Subclass this, wire the
/// five abstract members to your player of choice, and feed progress back in
/// through [reportPosition], [reportDuration] and [reportEnded]. See the
/// "Voice messages" section of the README for a complete `just_audio` wiring.
abstract class ChatAudioPlaybackController extends ChangeNotifier {
  ChatAudioPlayback? _current;

  /// What is loaded right now, or null if nothing ever was.
  ChatAudioPlayback? get current => _current;

  /// Whether [messageId]/[attachmentIndex] is the attachment currently loaded.
  /// Says nothing about whether it is audible — check [current] for that.
  bool isActive(String messageId, [int attachmentIndex = 0]) {
    final c = _current;
    return c != null &&
        c.messageId == messageId &&
        c.attachmentIndex == attachmentIndex;
  }

  /// Starts, pauses or resumes [url] for the given attachment.
  ///
  /// Tapping a different attachment pauses the running one first, so two voice
  /// messages can never overlap.
  Future<void> toggle(
    String messageId,
    String url, {
    int attachmentIndex = 0,
  }) async {
    if (isActive(messageId, attachmentIndex)) {
      if (_current!.state == ChatAudioState.playing) {
        await pause();
        _set(_current!.copyWith(state: ChatAudioState.paused));
      } else {
        await resume();
        _set(_current!.copyWith(state: ChatAudioState.playing));
      }
      return;
    }
    if (_current != null && _current!.state == ChatAudioState.playing) {
      await pause();
    }
    _set(
      ChatAudioPlayback(
        messageId: messageId,
        attachmentIndex: attachmentIndex,
        state: ChatAudioState.loading,
      ),
    );
    await loadSource(url);
    await resume();
    _set(_current!.copyWith(state: ChatAudioState.playing));
  }

  /// Jumps to [position] within the loaded attachment. No-op when nothing is
  /// loaded.
  Future<void> seek(Duration position) async {
    if (_current == null) return;
    await seekSource(position);
    _set(_current!.copyWith(position: position));
  }

  /// Sets the playback rate. No-op when nothing is loaded.
  Future<void> setSpeed(double speed) async {
    if (_current == null) return;
    await applySpeed(speed);
    _set(_current!.copyWith(speed: speed));
  }

  /// Feed the player's position stream in here.
  void reportPosition(Duration position) {
    if (_current == null) return;
    _set(_current!.copyWith(position: position));
  }

  /// Feed the player's resolved duration in here — this is what turns the
  /// bubble's placeholder into a real length.
  void reportDuration(Duration duration) {
    if (_current == null) return;
    _set(_current!.copyWith(duration: duration));
  }

  /// Call when the player reaches the end.
  void reportEnded() {
    if (_current == null) return;
    _set(
      _current!.copyWith(state: ChatAudioState.idle, position: Duration.zero),
    );
  }

  void _set(ChatAudioPlayback next) {
    if (_current == next) return;
    _current = next;
    notifyListeners();
  }

  /// Prepare [url] in the underlying player. Must not start playback.
  @protected
  Future<void> loadSource(String url);

  /// Start or continue playback of the loaded source.
  @protected
  Future<void> resume();

  /// Stop playback, keeping the position.
  @protected
  Future<void> pause();

  /// Jump the underlying player to [position].
  @protected
  Future<void> seekSource(Duration position);

  /// Apply [speed] to the underlying player.
  @protected
  Future<void> applySpeed(double speed);
}
