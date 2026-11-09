import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'content_sync.dart';
import 'dialogue_service.dart';
import 'learner_prefs.dart';
import 'tts_service.dart';

/// 회화 턴의 생성 음성(mp4) — 일본어앱 `dialogue_audio.dart` 이식(2026-11-09, 앱 구축 전략 단계 A).
///
/// 목록은 `ContentSync.audioIndex`(편 → 턴 → 판 m·f, 매니페스트 `/art/pt/audio/manifest`). 학습자 성별의 판을 쓴다.
/// **음성의 글이 지금 대사와 같을 때만** 재생한다 — 회화를 다시 쓰면 옛 음성이 엉뚱한 말을 하지 않게.
/// 기기에 받아 둔 파일이 있으면 파일로, 없으면 주소로 바로 재생한다. 음성이 없는 턴은 기기 음성(TTS, pt-PT)으로 읽는다.
class DialogueAudio {
  DialogueAudio._();
  static final DialogueAudio instance = DialogueAudio._();

  AudioPlayer? _player;
  Completer<void>? _wait;
  int _gen = 0;

  static String _norm(String s) => s.replaceAll(RegExp(r'[«»"“”]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// 이 턴에 쓸 음성(없거나 글이 바뀌었으면 null).
  AudioLine? line(String episodeId, DialogueTurn t) {
    final l = ContentSync.instance.audioIndex[episodeId]?[t.num]?[LearnerPrefs.isFemale ? 'f' : 'm'];
    if (l == null || _norm(l.text) != _norm(t.tl)) return null;
    return l;
  }

  /// 음성을 끝까지 재생한다. 음성이 없거나 재생에 실패하면 false(부르는 쪽이 TTS 로 넘긴다).
  Future<bool> play(String episodeId, DialogueTurn t, {double rate = 1.0}) async {
    final l = line(episodeId, t);
    if (l == null) return false;
    final my = ++_gen;
    try {
      await TtsService.instance.stop();
      final p = _player ??= AudioPlayer();
      await p.stop();
      _wait?.complete();
      final done = _wait = Completer<void>();
      final sub = p.onPlayerComplete.listen((_) {
        if (!done.isCompleted) done.complete();
      });
      try {
        final url = '${ContentSync.instance.base}/${l.key}';
        final f = ContentSync.instance.localFile(url);
        await p.setPlaybackRate(rate);
        await p.play(f != null ? DeviceFileSource(f.path) : UrlSource(url)).timeout(const Duration(seconds: 12));
        if (my != _gen) return true;
        await p.setPlaybackRate(rate); // 일부 기기는 재생을 시작한 뒤에야 속도가 먹는다
        await done.future.timeout(Duration(milliseconds: (l.ms / rate).round() + 6000), onTimeout: () {});
      } finally {
        await sub.cancel();
      }
      return true;
    } catch (e) {
      debugPrint('DialogueAudio: 재생 실패 $episodeId/${t.num} $e');
      return false;
    }
  }

  Future<void> stop() async {
    _gen++;
    final w = _wait;
    if (w != null && !w.isCompleted) w.complete();
    try {
      await _player?.stop();
    } catch (_) {}
    await TtsService.instance.stop();
  }
}

/// 기기 음성으로 읽을 글: 괄호·`{name}` 자리·이모지·인용 부호는 소리 내지 않는다.
String ttsText(String tl) => tl
    .replaceAll(RegExp(r'\([^)]*\)'), '')
    .replaceAll(RegExp(r'\{[a-z_]+\}'), '')
    .replaceAll(RegExp(r'[«»]|[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}]', unicode: true), '')
    .trim();

/// 턴 하나 읽기: 생성 음성이 있으면 그것, 없으면 기기 음성. 끝날 때까지 기다린다.
Future<void> speakTurn(Dialogue d, DialogueTurn t, {double rate = 1.0}) async {
  if (await DialogueAudio.instance.play(d.id, t, rate: rate)) return;
  await TtsService.instance.speakAs(ttsText(t.tl), gender: d.voiceGender(t.speaker), rate: rate * 0.45);
}
