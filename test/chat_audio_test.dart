import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kreiseck_chat/kreiseck_chat.dart';

/// Ein Controller ohne echten Player: merkt sich nur, was von ihm verlangt
/// wurde. Damit ist die Regel „nur eine laeuft" ohne Plattform-Plugin pruefbar.
class _FakeController extends ChatAudioPlaybackController {
  final List<String> calls = [];
  bool failLoad = false;
  bool failResume = false;
  Future<void>? resumeGate;
  Future<void>? loadGate;

  @override
  Future<void> loadSource(String url) async {
    calls.add('load:$url');
    if (loadGate != null) await loadGate;
    if (failLoad) throw StateError('laden');
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
    if (resumeGate != null) await resumeGate;
    if (failResume) throw StateError('abspielen');
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> seekSource(Duration position) async =>
      calls.add('seek:${position.inMilliseconds}');

  @override
  Future<void> applySpeed(double speed) async => calls.add('speed:$speed');
}

void main() {
  test('blockierendes resume: playing waehrend es aussteht, Ende bleibt idle', () async {
    final gate = Completer<void>();
    final c = _FakeController()..resumeGate = gate.future;
    final f = c.toggle('m1', 'https://x/a.ogg');
    await pumpEventQueue();
    expect(c.current!.state, ChatAudioState.playing);
    c.reportEnded();
    expect(c.current!.state, ChatAudioState.idle);
    gate.complete();
    await f;
    expect(c.current!.state, ChatAudioState.idle);
  });

  test('blockierendes resume wirft spaeter → failed', () async {
    final gate = Completer<void>();
    final c = _FakeController()..resumeGate = gate.future;
    final f = c.toggle('m1', 'https://x/a.ogg');
    await pumpEventQueue();
    expect(c.current!.state, ChatAudioState.playing);
    gate.completeError(StateError('abspielen'));
    await f;
    expect(c.current!.state, ChatAudioState.failed);
  });

  test('verspaetetes Laden von A ueberschreibt B nicht', () async {
    final gate = Completer<void>();
    final c = _FakeController()..loadGate = gate.future;
    final a = c.toggle('a', 'https://x/a.ogg');
    await pumpEventQueue();
    c.loadGate = null;
    await c.toggle('b', 'https://x/b.ogg');
    expect(c.current!.messageId, 'b');
    c.calls.clear();
    gate.complete();
    await a;
    expect(c.current!.messageId, 'b');
    expect(c.current!.state, ChatAudioState.playing);
    expect(c.calls, isEmpty);
  });

  test('toggle: loadSource wirft → state failed, kein Rethrow', () async {
    final c = _FakeController()..failLoad = true;
    await c.toggle('m1', 'https://x/a.ogg');
    expect(c.current!.state, ChatAudioState.failed);
  });

  test('toggle: resume wirft → state failed', () async {
    final c = _FakeController()..failResume = true;
    await c.toggle('m1', 'https://x/a.ogg');
    expect(c.current!.state, ChatAudioState.failed);
  });

  test('toggle nach failed versucht es erneut', () async {
    final c = _FakeController()..failLoad = true;
    await c.toggle('m1', 'https://x/a.ogg');
    c.failLoad = false;
    c.calls.clear();
    await c.toggle('m1', 'https://x/a.ogg');
    expect(c.calls, ['load:https://x/a.ogg', 'resume']);
    expect(c.current!.state, ChatAudioState.playing);
  });

  test('toggle nach reportEnded spult auf 0 zurueck', () async {
    final c = _FakeController();
    await c.toggle('m1', 'https://x/a.ogg');
    c.reportEnded();
    c.calls.clear();
    await c.toggle('m1', 'https://x/a.ogg');
    expect(c.calls, ['seek:0', 'resume']);
    expect(c.current!.state, ChatAudioState.playing);
  });

  test('neue Nachricht uebernimmt das Tempo', () async {
    final c = _FakeController();
    await c.toggle('m1', 'https://x/a.ogg');
    await c.setSpeed(1.5);
    c.calls.clear();
    await c.toggle('m2', 'https://x/b.ogg');
    expect(c.current!.speed, 1.5);
    expect(
      c.calls.indexOf('speed:1.5'),
      greaterThan(c.calls.indexOf('load:https://x/b.ogg')),
    );
  });

  test('ChatAudioPlayback: copyWith ersetzt nur das Angegebene', () {
    const a = ChatAudioPlayback(messageId: 'm1');
    final b = a.copyWith(state: ChatAudioState.playing, position: const Duration(seconds: 3));
    expect(b.messageId, 'm1');
    expect(b.state, ChatAudioState.playing);
    expect(b.position, const Duration(seconds: 3));
    expect(b.speed, 1.0);
  });

  test('ChatAudioPlayback: gleiche Werte sind gleich', () {
    expect(
      const ChatAudioPlayback(messageId: 'm1', position: Duration(seconds: 2)),
      const ChatAudioPlayback(messageId: 'm1', position: Duration(seconds: 2)),
    );
  });

  test('toggle laedt und spielt, wenn nichts laeuft', () async {
    final c = _FakeController();
    await c.toggle('m1', 'https://x/a.ogg');
    expect(c.calls, ['load:https://x/a.ogg', 'resume']);
    expect(c.current!.messageId, 'm1');
    expect(c.current!.state, ChatAudioState.playing);
    expect(c.isActive('m1'), isTrue);
  });

  test('toggle auf derselben Nachricht pausiert statt neu zu laden', () async {
    final c = _FakeController();
    await c.toggle('m1', 'https://x/a.ogg');
    c.calls.clear();
    await c.toggle('m1', 'https://x/a.ogg');
    expect(c.calls, ['pause']);
    expect(c.current!.state, ChatAudioState.paused);
  });

  test('toggle auf derselben Nachricht spielt aus der Pause weiter, ohne neu zu laden', () async {
    final c = _FakeController();
    await c.toggle('m1', 'https://x/a.ogg');
    await c.toggle('m1', 'https://x/a.ogg');
    c.calls.clear();
    await c.toggle('m1', 'https://x/a.ogg');
    expect(c.calls, ['resume']);
    expect(c.current!.state, ChatAudioState.playing);
  });

  test('nur eine laeuft: eine zweite Nachricht loest die erste ab', () async {
    final c = _FakeController();
    await c.toggle('m1', 'https://x/a.ogg');
    c.calls.clear();
    await c.toggle('m2', 'https://x/b.ogg');
    expect(c.calls, ['pause', 'load:https://x/b.ogg', 'resume']);
    expect(c.isActive('m1'), isFalse);
    expect(c.isActive('m2'), isTrue);
  });

  test('zwei Anhaenge derselben Nachricht sind auseinanderzuhalten', () async {
    final c = _FakeController();
    await c.toggle('m1', 'https://x/a.ogg');
    expect(c.isActive('m1', 0), isTrue);
    expect(c.isActive('m1', 1), isFalse);
    await c.toggle('m1', 'https://x/b.ogg', attachmentIndex: 1);
    expect(c.isActive('m1', 0), isFalse);
    expect(c.isActive('m1', 1), isTrue);
  });

  test('reportDuration und reportPosition melden Zuhoerern', () async {
    final c = _FakeController();
    var notifications = 0;
    c.addListener(() => notifications++);
    await c.toggle('m1', 'https://x/a.ogg');
    notifications = 0;
    c.reportDuration(const Duration(seconds: 12));
    c.reportPosition(const Duration(seconds: 4));
    expect(c.current!.duration, const Duration(seconds: 12));
    expect(c.current!.position, const Duration(seconds: 4));
    expect(notifications, 2);
  });

  test('reportEnded setzt zurueck auf Anfang und idle', () async {
    final c = _FakeController();
    await c.toggle('m1', 'https://x/a.ogg');
    c.reportPosition(const Duration(seconds: 4));
    c.reportEnded();
    expect(c.current!.state, ChatAudioState.idle);
    expect(c.current!.position, Duration.zero);
  });

  test('seek und setSpeed wirken nur, wenn etwas aktiv ist', () async {
    final c = _FakeController();
    await c.seek(const Duration(seconds: 5));
    await c.setSpeed(1.5);
    expect(c.calls, isEmpty);
    await c.toggle('m1', 'https://x/a.ogg');
    c.calls.clear();
    await c.seek(const Duration(seconds: 5));
    await c.setSpeed(1.5);
    expect(c.calls, ['seek:5000', 'speed:1.5']);
    expect(c.current!.position, const Duration(seconds: 5));
    expect(c.current!.speed, 1.5);
  });
}
