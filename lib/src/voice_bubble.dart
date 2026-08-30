import 'package:flutter/material.dart';

import 'chat_attachment.dart';
import 'chat_audio.dart';
import 'chat_strings.dart';
import 'chat_theme.dart';

/// Renders one audio attachment as a voice message: a play/pause button, a
/// draggable progress bar, elapsed / total time and a speed chip.
///
/// The widget plays nothing itself. Give it the [playback] state your
/// [ChatAudioPlaybackController] holds and wire [onToggle], [onSeek] and
/// [onSpeed] back to it — see the README's "Voice messages" section.
///
/// Deliberately no waveform: the package never analyses the audio, and a
/// waveform derived from the URL would draw information nobody has.
class VoiceBubble extends StatelessWidget {
  /// Creates a voice bubble.
  const VoiceBubble({
    super.key,
    required this.attachment,
    required this.messageId,
    required this.attachmentIndex,
    required this.theme,
    required this.ink,
    this.playback,
    this.onToggle,
    this.onSeek,
    this.onSpeed,
    this.strings,
  });

  /// The audio attachment to render.
  final ChatAttachment attachment;

  /// Id of the message carrying it — used to tell playbacks apart.
  final String messageId;

  /// Index of this attachment within the message.
  final int attachmentIndex;

  /// Visual configuration.
  final ChatTheme theme;

  /// Foreground color resolved for the surrounding bubble.
  final Color ink;

  /// Playback state, when this attachment is the one loaded. Null means
  /// "not loaded" and renders the resting state.
  final ChatAudioPlayback? playback;

  /// Called when the play/pause button is tapped.
  final VoidCallback? onToggle;

  /// Called with the target position when the bar is dragged. Ignored while
  /// the duration is unknown — there is nothing to seek within.
  final void Function(Duration position)? onSeek;

  /// Called with the next rate when the speed chip is tapped.
  final void Function(double speed)? onSpeed;

  /// Overrides the resolved strings.
  final ChatStrings? strings;

  /// The rates the speed chip cycles through.
  static const List<double> speeds = [1.0, 1.5, 2.0];

  bool get _isMine =>
      playback != null &&
      playback!.messageId == messageId &&
      playback!.attachmentIndex == attachmentIndex;

  ChatAudioState get _state => _isMine ? playback!.state : ChatAudioState.idle;

  Duration? get _duration => _isMine ? playback!.duration : null;

  Duration get _position => _isMine ? playback!.position : Duration.zero;

  static String _clock(Duration? d) {
    if (d == null) return '--:--';
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final s = ChatStrings.of(context, override: strings);
    final total = _duration;
    final canSeek = onSeek != null && total != null && total > Duration.zero;
    final value = canSeek
        ? (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    // Beim Abspielen die verstrichene Zeit, sonst die Gesamtlaenge -- das ist
    // die Zahl, die im jeweiligen Zustand etwas aussagt.
    final label =
        _state == ChatAudioState.playing || _state == ChatAudioState.paused
        ? _clock(_position)
        : _clock(total);

    return Semantics(
      label: s.voiceMessage,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _button(s),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      activeTrackColor: ink,
                      inactiveTrackColor: ink.withValues(alpha: 0.25),
                      thumbColor: ink,
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                        disabledThumbRadius: 4,
                      ),
                    ),
                    child: Slider(
                      value: value,
                      onChanged: canSeek
                          ? (v) => onSeek!(
                              Duration(
                                milliseconds: (total.inMilliseconds * v)
                                    .round(),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      bottom: 2,
                    ),
                    child: Row(
                      children: [
                        Text(
                          label,
                          style: theme.typography.timestamp.copyWith(color: ink),
                        ),
                        const Spacer(),
                        if (_isMine && onSpeed != null) _speedChip(s),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(ChatStrings s) {
    if (_state == ChatAudioState.loading) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2, color: ink),
        ),
      );
    }
    final playing = _state == ChatAudioState.playing;
    return IconButton(
      iconSize: 28,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      color: ink,
      tooltip: s.voiceMessage,
      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
      onPressed: onToggle,
    );
  }

  Widget _speedChip(ChatStrings s) {
    final current = playback!.speed;
    final index = speeds.indexWhere((v) => (v - current).abs() < 0.01);
    final next = speeds[(index < 0 ? 0 : index + 1) % speeds.length];
    final text = current == current.roundToDouble()
        ? '${current.toStringAsFixed(0)}×'
        : '${current.toStringAsFixed(1).replaceAll('.', ',')}×';
    return InkWell(
      onTap: () => onSpeed!(next),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Tooltip(
          message: s.playbackSpeed,
          child: Text(
            text,
            style: theme.typography.timestamp.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
