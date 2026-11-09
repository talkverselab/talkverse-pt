import '../core/embed_env.dart';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/art_service.dart';
import '../services/content_sync.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../services/word_lookup.dart' as lookup;

/// 절벽 단어 — 유럽판 빈도 1~2,000위를 절벽구간(R1~R5)별 **20어 단원**으로, 단어는 **네모 타일**로(일본어앱 2026-11-07 개편 이식).
/// 위 버튼 「절벽구간 단어만 / 회화 단어 포함」 — 포함이면 회화에 나오지만 2,000위 밖인 단어가 「회화」 구간으로 뒤에 붙는다.
/// 데이터는 `tools/build_cliff_words.py` 가 만든 `cliff_pt_PT.csv`·`conv_words_pt.json`. DB 는 합치지 않고 화면에서만 합친다.
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

/// 절벽 v2 절대 기준(누적 55/60/70/80%, pt-PT 레마) · R5 는 2,000위에서 끊음.
const List<int> kCliffsPt = [55, 83, 217, 656];
const List<int> kCliffsBr = [63, 96, 243, 727];
const int kWordCap = 2000;
const double kCapPctPt = 88.5;
const double kCapPctBr = 88.2;
const int kUnit = 20;

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<CliffWord> _words = [];
  List<CliffWord> _conv = [];
  bool _loading = true;
  bool _withConv = false;
  String _filter = 'ALL';

  static Map<String, _Region> get _regions => {
        'ALL': _Region(tr('전체'), AppColors.sumi),
        'R1': _Region('R1 · 1-${kCliffsPt[0]}', AppColors.beni),
        'R2': _Region('R2 · ${kCliffsPt[0] + 1}-${kCliffsPt[1]}', AppColors.beniLight),
        'R3': _Region('R3 · ${kCliffsPt[1] + 1}-${kCliffsPt[2]}', AppColors.kinDeep),
        'R4': _Region('R4 · ${kCliffsPt[2] + 1}-${kCliffsPt[3]}', AppColors.matcha),
        'R5': _Region('R5 · ${kCliffsPt[3] + 1}-$kWordCap', AppColors.muted),
        'C': _Region(tr('회화'), AppColors.ai),
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(assetPath('assets/data/freq/cliff_pt_PT.csv'));
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(raw);
    final words = <CliffWord>[];
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length < 5) continue;
      words.add(CliffWord(rank: int.tryParse('${r[0]}') ?? 0, word: '${r[1]}', region: '${r[3]}'.trim(), ko: '${r[4]}'));
    }
    final conv = <CliffWord>[];
    try {
      final j = json.decode(await rootBundle.loadString(assetPath('assets/data/freq/conv_words_pt.json'))) as Map<String, dynamic>;
      var n = 0;
      for (final w in (j['words'] as List).cast<Map<String, dynamic>>()) {
        conv.add(CliffWord(rank: ++n, word: w['word'] as String, region: 'C', ko: (w['ko'] as String?) ?? ''));
      }
    } catch (_) {}
    // 독음은 단어장에 있는 말만(표면형 일치)
    final found = await lookup.WordLookup.instance.byLemmas([...words, ...conv].map((e) => e.word));
    for (final e in [...words, ...conv]) {
      e.rd = found[e.word]?.rd ?? '';
    }
    if (!mounted) return;
    setState(() {
      _words = words;
      _conv = conv;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pool = _withConv ? [..._words, ..._conv] : _words;
    final filtered = _filter == 'ALL' ? pool : pool.where((w) => w.region == _filter).toList();
    final units = <List<CliffWord>>[];
    for (var i = 0; i < filtered.length; i += kUnit) {
      units.add(filtered.sublist(i, (i + kUnit).clamp(0, filtered.length)));
    }
    final regions = _regions;
    final chips = regions.entries.where((e) => e.key != 'C' || _withConv).toList();

    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('절벽 단어'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(trf('회화 빈도 {0}위 · {1}어 단원 · 탭하면 발음', ['2,000', kUnit]), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
          ],
        ),
        actions: const [KoReadingToggleAction()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : Column(
              children: [
                Container(
                  color: AppColors.washiDeep,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _ModeButton(
                            label: tr('절벽구간 단어만'),
                            selected: !_withConv,
                            onTap: () => setState(() {
                              _withConv = false;
                              if (_filter == 'C') _filter = 'ALL';
                            }),
                          ),
                          const SizedBox(width: 8),
                          _ModeButton(label: trf('회화 단어 포함 (+{0})', [_conv.length]), selected: _withConv, onTap: () => setState(() => _withConv = true)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final e in chips)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() => _filter = e.key),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _filter == e.key ? e.value.color : AppColors.washi,
                                      border: Border.all(color: e.value.color, width: _filter == e.key ? 1.5 : 0.8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(e.value.label, style: TextStyle(color: _filter == e.key ? AppColors.washi : e.value.color, fontWeight: FontWeight.w700, fontSize: 12)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final cols = (c.maxWidth / 112).floor().clamp(3, 8);
                      return ListView.builder(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomInset(context)),
                        itemCount: units.length,
                        itemBuilder: (context, i) => _UnitBlock(index: i + 1, words: units[i], regions: regions, cols: cols),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.sumi : AppColors.washi,
              border: Border.all(color: selected ? AppColors.sumi : AppColors.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: TextStyle(color: selected ? AppColors.washi : AppColors.sumi, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      );
}

/// 한 단원 = 20어. 머리줄(단원 번호·순위 범위·구간) + 네모 타일 격자.
class _UnitBlock extends StatelessWidget {
  final int index;
  final List<CliffWord> words;
  final Map<String, _Region> regions;
  final int cols;
  const _UnitBlock({required this.index, required this.words, required this.regions, required this.cols});

  @override
  Widget build(BuildContext context) {
    final first = words.first;
    final last = words.last;
    final region = regions[first.region];
    final range = first.region == 'C' ? trf('회화 {0}-{1}', [first.rank, last.rank]) : '#${first.rank}-${last.rank}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
            child: Row(
              children: [
                Text(trf('{0}단원', [index]), style: const TextStyle(color: AppColors.sumi, fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Text(range, style: const TextStyle(color: AppColors.sumiLight, fontSize: 11)),
                const Spacer(),
                if (region != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: region.color, borderRadius: BorderRadius.circular(2)),
                    child: Text(first.region == 'C' ? tr('회화') : first.region, style: const TextStyle(color: AppColors.washi, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 6, crossAxisSpacing: 6),
            itemCount: words.length,
            itemBuilder: (context, i) => _WordTile(w: words[i], color: regions[words[i].region]?.color ?? AppColors.sumi),
          ),
        ],
      ),
    );
  }
}

/// 네모 타일 — 순위·독음 · 그림(있으면) · 단어 · 뜻 한 줄. 탭하면 발음.
class _WordTile extends StatelessWidget {
  final CliffWord w;
  final Color color;
  const _WordTile({required this.w, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => TtsService.instance.speak(w.word),
      child: Container(
        decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8), boxShadow: kCardShadow),
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(
          builder: (context, c) {
            final art = (c.maxHeight * 0.34).clamp(24.0, 72.0);
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(w.region == 'C' ? tr('회화') : '#${w.rank}', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    if (w.rd.isNotEmpty)
                      Expanded(child: KoReadingText(w.rd, maxLines: 1, textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, color: AppColors.sumiLight))),
                  ],
                ),
                const SizedBox(height: 2),
                _Art(word: w.word, size: art),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown, child: Text(w.word, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.sumi))),
                if (w.ko.isNotEmpty) Text(w.ko, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.sumiLight)),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 단어 그림(있으면). 공유 그림 목록의 순위는 절벽 순위와 달라 단어로만 찾는다.
class _Art extends StatelessWidget {
  final String word;
  final double size;
  const _Art({required this.word, required this.size});

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
        future: ArtService.instance.urlFor(word),
        builder: (context, snap) {
          final url = snap.data;
          if (url == null) return SizedBox(width: size, height: size);
          return ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.25),
            child: Container(
              width: size,
              height: size,
              color: AppColors.washiDeep,
              child: Image(image: artProvider(url), fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
            ),
          );
        },
      );
}

class CliffWord {
  final int rank;
  final String word;
  final String region; // R1~R5 · C(회화 단어)
  final String ko;
  String rd = '';
  CliffWord({required this.rank, required this.word, required this.region, required this.ko});
}

class _Region {
  final String label;
  final Color color;
  const _Region(this.label, this.color);
}
