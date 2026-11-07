import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/dialogue_service.dart';
import '../services/learner_prefs.dart';
import '../services/word_lookup.dart';
import 'lemma_chips.dart';

/// 문장을 (시작, 끝, 레마) 토막으로 — 글자 경계에서만 잡는다(ser 가 「serviço」 안에서 잡히지 않게).
List<(int, int, Lemma)> lemmaSpans(String text, List<Lemma> lemmas) {
  final out = <(int, int, Lemma)>[];
  var pos = 0;
  for (final l in lemmas) {
    if (l.surface.isEmpty) continue;
    final esc = l.surface.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (m) => '\\${m[0]}');
    final re = RegExp('(?<![\\p{L}])$esc(?![\\p{L}])', unicode: true, caseSensitive: false);
    final m = re.allMatches(text, pos).firstOrNull;
    if (m == null) continue;
    out.add((m.start, m.end, l));
    pos = m.end;
  }
  return out;
}

/// 회화 문장을 레마(내용어) 단위로 쪼개 **탭하면 단어창**(일본어앱 `SelectableJaText` 의 포르투갈어판, 2026-11-07).
/// 단어장에 있는 레마만 밑줄 + 탭. 문장은 `{name}` 을 채운 뒤 표면형을 앞에서부터 차례로 찾는다.
class LemmaText extends StatefulWidget {
  final DialogueTurn turn;
  final TextStyle style;
  const LemmaText(this.turn, {super.key, required this.style});

  @override
  State<LemmaText> createState() => _LemmaTextState();
}

class _LemmaTextState extends State<LemmaText> {
  Map<String, WordEntry> _found = const {};
  final List<TapGestureRecognizer> _taps = [];

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  @override
  void didUpdateWidget(LemmaText old) {
    super.didUpdateWidget(old);
    if (!identical(old.turn, widget.turn)) _lookup();
  }

  Future<void> _lookup() async {
    final m = await WordLookup.instance.byLemmas(widget.turn.lemmas.map((l) => l.base));
    if (mounted) setState(() => _found = m);
  }

  void _clear() {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final text = LearnerPrefs.fill(widget.turn.tl);
    final spans = <InlineSpan>[];
    var i = 0;
    for (final (s, e, l) in lemmaSpans(text, widget.turn.lemmas)) {
      final w = _found[l.base];
      if (w == null) continue;
      if (s > i) spans.add(TextSpan(text: text.substring(i, s)));
      final tap = TapGestureRecognizer()..onTap = () => showWordSheet(context, w);
      _taps.add(tap);
      spans.add(TextSpan(
        text: text.substring(s, e),
        recognizer: tap,
        style: const TextStyle(decoration: TextDecoration.underline, decorationColor: AppColors.ai, decorationThickness: 1.4),
      ));
      i = e;
    }
    if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
