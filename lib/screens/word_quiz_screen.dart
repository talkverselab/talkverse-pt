import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/embed_env.dart';
import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../services/word_lookup.dart' as lookup;
import 'word_freq_screen.dart' show kCliffsPt, kWordCap;
import '../core/word_filter.dart';

/// 단어 퀴즈 복습(베트남어앱 word_quiz_screen 이식, 2026-11-22).
/// 단어 = 절벽 단어표 `assets/data/freq/cliff_pt_PT.csv`(pt-PT 빈도 2,000위, 한국어 뜻 있는 것만).
/// 3단계 = 핵심(R1~R2) → 중급까지(R1~R4) → 전체(2,000위). 문제 두 꼴, 보기 1~4, 10문제, 틀린 단어 먼저.
///  · 뜻 — 포르투갈어를 보고 한국어 뜻 고르기
///  · 단어 — 한국어 뜻을 보고 포르투갈어 고르기(베트남어판의 「성조」 문제 자리)
const int kWordQuizSize = 10;
const String _kWrong = 'word_quiz_wrong';

class QWord {
  final int rank;
  final String tl, ko;
  String rd;
  QWord(this.rank, this.tl, this.ko, {this.rd = ''});
}

/// 단계별 끝 순위(절벽 v2 — word_freq_screen kCliffsPt: R2 끝·R4 끝).
List<(String, String, int)> get kQuizStages => [
      (tr('핵심'), trf('1-{0}위', [kCliffsPt[1]]), kCliffsPt[1]),
      (tr('중급까지'), trf('1-{0}위', [kCliffsPt[3]]), kCliffsPt[3]),
      (tr('전체'), trf('1-{0}위', ['2,000']), kWordCap),
    ];

List<QWord>? _cache;

Future<List<QWord>> loadQuizWords() async {
  final c = _cache;
  if (c != null) return c;
  final raw = await rootBundle.loadString(assetPath('assets/data/freq/cliff_pt_PT.csv'));
  final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(raw);
  final out = <QWord>[];
  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    if (r.length < 5) continue;
    final ko = '${r[4]}'.trim();
    final tl = '${r[1]}'.trim();
    if (ko.isEmpty || tl.isEmpty || isOffensiveWord(tl, ko)) continue; // 12+ — 비속어 제외
    out.add(QWord(int.tryParse('${r[0]}') ?? 0, tl, ko));
  }
  // 독음은 단어장에 있는 말만(절벽 단어 화면과 같게)
  try {
    final found = await lookup.WordLookup.instance.byLemmas(out.map((e) => e.tl));
    for (final w in out) {
      w.rd = found[w.tl]?.rd ?? '';
    }
  } catch (_) {}
  return _cache = out;
}

/// 단계 고르기 → 퀴즈.
class WordQuizHome extends StatelessWidget {
  const WordQuizHome({super.key});

  @override
  Widget build(BuildContext context) {
    final stages = kQuizStages;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('단어 퀴즈')), actions: const [KoReadingToggleAction()]),
      body: ListView(padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context)), children: [
        Text(tr('뜻 고르기와 단어 고르기, 10문제씩. 틀린 단어는 다음에 먼저 나와요.'), style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 14),
        for (var i = 0; i < stages.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              key: ValueKey('wq-stage-$i'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                alignment: Alignment.centerLeft,
                side: const BorderSide(color: AppColors.line, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final all = await loadQuizWords();
                if (!context.mounted) return;
                final words = all.where((w) => w.rank <= stages[i].$3).toList();
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => WordQuizScreen(words: words)));
              },
              child: Row(children: [
                Text(trf('{0}단계', [i + 1]), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.beni)),
                const SizedBox(width: 12),
                Expanded(child: Text(stages[i].$1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.sumi))),
                Text(stages[i].$2, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _Q {
  final QWord w;
  final bool reverse; // true = 뜻 → 포르투갈어, false = 포르투갈어 → 뜻
  final List<String> options;
  const _Q(this.w, this.reverse, this.options);
  String get answer => reverse ? w.tl : w.ko;
}

class WordQuizScreen extends StatefulWidget {
  final List<QWord> words;
  final int? seed;
  const WordQuizScreen({super.key, required this.words, this.seed});
  @override
  State<WordQuizScreen> createState() => _WordQuizScreenState();
}

class _WordQuizScreenState extends State<WordQuizScreen> {
  late final _rnd = Random(widget.seed);
  List<_Q>? _qs;
  int _i = 0;
  String? _picked;
  int _right = 0;
  final List<QWord> _missed = [];

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    final p = await Prefs.getInstance();
    final wrong = (p.getStringList(_kWrong) ?? const []).toSet();
    final uniq = <String, QWord>{for (final w in widget.words) w.tl: w}.values.toList()..shuffle(_rnd);
    uniq.sort((a, b) => (wrong.contains(b.tl) ? 1 : 0) - (wrong.contains(a.tl) ? 1 : 0));
    final picked = uniq.take(kWordQuizSize).toList()..shuffle(_rnd);
    final qs = <_Q>[];
    for (var k = 0; k < picked.length; k++) {
      final w = picked[k];
      if (k.isEven) {
        // 뜻이 같은 단어는 보기에서 뺀다(정답이 둘이 되지 않게)
        final others = ({for (final o in uniq) if (o.ko != w.ko && o.tl != w.tl) o.tl}.toList()..shuffle(_rnd)).take(3);
        qs.add(_Q(w, true, [w.tl, ...others]..shuffle(_rnd)));
      } else {
        final others = ({for (final o in uniq) if (o.ko != w.ko) o.ko}.toList()..shuffle(_rnd)).take(3);
        qs.add(_Q(w, false, [w.ko, ...others]..shuffle(_rnd)));
      }
    }
    if (mounted) setState(() => _qs = qs);
  }

  Future<void> _record(String tl, bool ok) async {
    final p = await Prefs.getInstance();
    final s = (p.getStringList(_kWrong) ?? const []).toSet();
    ok ? s.remove(tl) : s.add(tl);
    await p.setStringList(_kWrong, s.toList());
  }

  void _again() => setState(() {
        _qs = null;
        _i = 0;
        _picked = null;
        _right = 0;
        _missed.clear();
        _build();
      });

  @override
  Widget build(BuildContext context) {
    final qs = _qs;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('퀴즈 복습')), actions: const [KoReadingToggleAction()]),
      body: qs == null
          ? const Center(child: CircularProgressIndicator())
          : qs.isEmpty
              ? Center(child: Text(tr('단어 준비 중'), style: const TextStyle(color: AppColors.muted)))
              : _i >= qs.length
                  ? _summary(qs.length)
                  : _question(qs[_i], qs.length),
    );
  }

  Widget _summary(int n) => Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset(context)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(trf('{0}문제 중 {1}개 맞힘', [n, _right]), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            if (_missed.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(tr('틀린 단어 — 다음 복습에 먼저 나와요'), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 6),
              for (final w in _missed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(children: [
                    Text('${w.tl}  ${w.ko}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                    if (w.rd.isNotEmpty) KoReadingText('[${w.rd}]', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.sumiLight)),
                  ]),
                ),
            ],
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton(key: const ValueKey('wq-again'), onPressed: _again, child: Text(tr('한 번 더'))),
              const SizedBox(width: 10),
              FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.sumi),
                  child: Text(tr('나가기'))),
            ]),
          ]),
        ),
      );

  Widget _question(_Q q, int n) {
    final w = q.w;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${q.reverse ? tr('단어') : tr('뜻')} · ${_i + 1} / $n', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 14),
        Text(
          q.reverse ? w.ko : w.tl,
          key: const ValueKey('wq-stem'),
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.sumi),
        ),
        if (!q.reverse && w.rd.isNotEmpty)
          KoReadingText(w.rd, style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
        const SizedBox(height: 8),
        Text(q.reverse ? tr('포르투갈어로 맞는 것을 고르세요.') : tr('뜻으로 맞는 것을 고르세요.'), style: const TextStyle(fontSize: 14, color: AppColors.sumi)),
        if (_picked != null) ...[
          const SizedBox(height: 4),
          Text('${w.tl} · ${w.ko}', style: const TextStyle(fontSize: 13, color: AppColors.beni, fontWeight: FontWeight.w700)),
          if (w.rd.isNotEmpty) KoReadingText('[${w.rd}]', style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
        ],
        const SizedBox(height: 14),
        for (var k = 0; k < q.options.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              key: ValueKey('wq-opt-$k'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                backgroundColor: _picked == null ? null : (q.options[k] == q.answer ? const Color(0x3336A35B) : (q.options[k] == _picked ? const Color(0x33D83A3A) : null)),
                side: BorderSide(color: _picked != null && q.options[k] == q.answer ? AppColors.matcha : AppColors.line, width: 1.4),
              ),
              onPressed: _picked != null
                  ? null
                  : () {
                      final ok = q.options[k] == q.answer;
                      TtsService.instance.speak(w.tl);
                      _record(w.tl, ok);
                      setState(() {
                        _picked = q.options[k];
                        ok ? _right++ : _missed.add(w);
                      });
                    },
              child: Row(children: [
                SizedBox(width: 26, child: Text('${k + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.muted))),
                Expanded(child: Text(q.options[k], style: TextStyle(fontSize: q.reverse ? 20 : 16, fontWeight: FontWeight.w800, color: AppColors.sumi))),
              ]),
            ),
          ),
        if (_picked != null)
          FilledButton(
            key: const ValueKey('wq-next'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.sumi, minimumSize: const Size.fromHeight(48)),
            onPressed: () => setState(() {
              _i++;
              _picked = null;
            }),
            child: Text(tr('다음 →')),
          ),
      ]),
    );
  }
}
