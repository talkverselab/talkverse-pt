import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../main.dart';

/// 단어장 한 항목 — 레마 칩·단어 시트용(2026-11-04).
/// 포르투갈어앱의 단어장 = 번들 `assets/data/vocab/travel_words.json`(주제별 단어, `{ko, tx, rd, ic}`) + DB `words`(빈도 단어, 지금은 비어 있음).
class WordEntry {
  final String word;
  final String ko;
  final String rd;
  final String icon;
  final int? rank;
  const WordEntry({required this.word, required this.ko, this.rd = '', this.icon = '', this.rank});
  String get gloss => ko;
}

/// 기본형(레마)으로 단어장 찾기 — 일본어앱 `WordService.byLemmas` 의 포르투갈어판.
/// 대소문자·악센트 그대로 비교하고, 못 찾으면 소문자로 한 번 더 본다.
class WordLookup {
  WordLookup._();
  static final WordLookup instance = WordLookup._();

  Map<String, WordEntry>? _bundle;
  Future<void>? _loading;

  Future<void> _ensure() => _loading ??= _load();

  Future<void> _load() async {
    final out = <String, WordEntry>{};
    try {
      final j = json.decode(await rootBundle.loadString('assets/data/vocab/travel_words.json')) as Map<String, dynamic>;
      for (final th in (j['themes'] as List? ?? const [])) {
        for (final sec in ((th as Map)['sections'] as List? ?? const [])) {
          for (final w in ((sec as Map)['words'] as List? ?? const [])) {
            final m = w as Map;
            final tx = (m['tx'] ?? '').toString().trim();
            if (tx.isEmpty) continue;
            out.putIfAbsent(tx.toLowerCase(), () => WordEntry(word: tx, ko: (m['ko'] ?? '').toString(), rd: (m['rd'] ?? '').toString(), icon: (m['ic'] ?? '').toString()));
          }
        }
      }
    } catch (_) {}
    _bundle = out;
  }

  /// 기본형 목록 → 찾은 것만 {기본형: 단어}. 번들 단어장 먼저, 없으면 DB `words`(빈도 단어).
  Future<Map<String, WordEntry>> byLemmas(Iterable<String> bases) async {
    await _ensure();
    final keys = bases.toSet().where((b) => b.isNotEmpty).toList();
    if (keys.isEmpty) return const {};
    final out = <String, WordEntry>{};
    final left = <String>[];
    for (final b in keys) {
      final e = _bundle![b.toLowerCase()];
      if (e != null) {
        out[b] = e;
      } else {
        left.add(b.toLowerCase());
      }
    }
    if (left.isNotEmpty) {
      try {
        final rows = await (appDb.select(appDb.words)..where((w) => w.word.isIn(left))).get();
        for (final r in rows) {
          final b = keys.firstWhere((k) => k.toLowerCase() == r.word.toLowerCase(), orElse: () => r.word);
          out.putIfAbsent(b, () => WordEntry(word: r.word, ko: r.meaningKo ?? '', rank: r.rank));
        }
      } catch (_) {}
    }
    return out;
  }
}
