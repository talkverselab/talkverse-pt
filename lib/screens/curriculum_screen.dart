import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/curriculum_service.dart';
import '../services/dialogue_audio.dart';
import '../services/dialogue_service.dart';
import '../widgets/spanish_decor.dart';

/// 토크버스 커리큘럼(`~/talkverse/CURRICULUM_SPEC.md`) — 레벨 고르기 → 코스(고른 편) → 편마다 연습 → 코스 시험 80%.
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});
  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  final _ds = DialogueService.instance;
  final _cs = CurriculumService.instance;
  bool _ready = false;
  bool _pickLevel = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _ds.ensureLoaded();
    await _cs.load();
    if (mounted) setState(() => _ready = true);
  }

  CurriculumState get _s => _cs.state;

  Future<void> _push(Widget w) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.calDeep,
      appBar: AppBar(title: Text(tr('토크버스 커리큘럼'))),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : (_s.level == null || _pickLevel)
              ? _levelPicker()
              : _courseHome(),
    );
  }

  // ── 레벨 고르기 ──
  Widget _levelPicker() {
    final ls = _cs.levels(_ds);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
      children: [
        Text(tr('회화 레벨을 고르세요'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.tinta)),
        const SizedBox(height: 4),
        Text(tr('처음이면 가장 낮은 레벨부터 권합니다. 레벨의 편을 모두 통과하면 다음 레벨이 열립니다.'),
            style: const TextStyle(fontSize: 12.5, color: AppColors.tintaLight)),
        const SizedBox(height: 12),
        for (final (i, l) in ls.indexed)
          Builder(builder: (context) {
            final open = _cs.unlocked(_ds, l);
            final eps = _ds.list(region: l);
            final passed = eps.where((d) => _s.passedDialogues.contains(d.id)).length;
            return Card(
              elevation: 0,
              color: AppColors.cal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.gualda)),
              child: ListTile(
                enabled: open,
                leading: Icon(open ? Icons.flag_outlined : Icons.lock_outline, color: open ? AppColors.beni : AppColors.gualdaDeep),
                title: Text(tr(DialogueService.levelKo[l] ?? l), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(trf('{0}편 중 {1}편 통과', [eps.length, passed]) + (i == 0 && _s.level == null ? ' · ${tr('추천')}' : '')),
                trailing: l == _s.level ? const Icon(Icons.check_circle, color: AppColors.lusa) : null,
                onTap: () async {
                  _s.level = l;
                  await _cs.save();
                  setState(() => _pickLevel = false);
                },
              ),
            );
          }),
      ],
    );
  }

  // ── 코스 화면 ──
  Widget _courseHome() {
    final t = _cs.today;
    _s.rollDay(t);
    final c = _s.course;
    final due = _s.dueReviews(t);
    final newLeft = c == null ? 0 : c.dialogueIds.where((id) => !c.practiced.contains(id)).length;
    final newToday = (_s.newGoal - _s.newDone).clamp(0, newLeft);
    final total = _s.newGoal + _s.reviewDone + due.length;
    final done = _s.newDone.clamp(0, _s.newGoal) + _s.reviewDone;
    final dailyDone = _s.streakLastDay == t;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
      children: [
        _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(dailyDone ? tr('오늘 분량 끝') : trf('오늘: 복습 {0} · 새 편 {1}', [due.length, newToday]),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.tinta)),
            ),
            if (_s.streakCount > 0) Text('🔥 ${trf('{0}일 연속', [_s.streakCount])}', style: const TextStyle(fontSize: 12.5, color: AppColors.er)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                value: dailyDone ? 1 : (total == 0 ? 0 : done / total), minHeight: 8, color: AppColors.lusa, backgroundColor: AppColors.gualda),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final g in kDailyGoals.keys)
              ChoiceChip(
                label: Text(_goalLabel(g), style: const TextStyle(fontSize: 12)),
                selected: _s.dailyGoal == g,
                onSelected: (_) async {
                  _s.dailyGoal = g;
                  await _cs.save();
                  setState(() {});
                },
              ),
          ]),
          if (due.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.replay),
                label: Text(trf('복습 {0}개 하기', [due.length])),
                onPressed: () => _push(_ReviewScreen(items: due)),
              ),
            ),
          ],
        ])),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Text(tr(DialogueService.levelKo[_s.level] ?? _s.level!),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.beniDeep)),
          ),
          TextButton(onPressed: () => setState(() => _pickLevel = true), child: Text(tr('레벨 바꾸기'))),
        ]),
        if (c == null || c.passed) ...[
          if (c != null && c.passed)
            _box(Text(trf('코스 통과! 시험 {0}%', [c.examScores.last]), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.lusa))),
          const SizedBox(height: 8),
          if (_levelAllPassed())
            _box(Text(tr('이 레벨의 편을 모두 통과했습니다. 레벨 바꾸기에서 다음 레벨을 고르세요.'), style: const TextStyle(color: AppColors.tinta)))
          else
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(c == null ? tr('코스 만들기') : tr('다음 코스 만들기')),
              onPressed: () => _push(_CourseBuilder(level: _s.level!)),
            ),
        ] else
          ..._courseBody(c),
      ],
    );
  }

  bool _levelAllPassed() => _ds.list(region: _s.level).every((d) => _s.passedDialogues.contains(d.id));

  List<Widget> _courseBody(Course c) {
    final eps = [for (final id in c.dialogueIds) _ds.byId(id)].whereType<Dialogue>().toList();
    return [
      for (final d in eps)
        Card(
          elevation: 0,
          color: AppColors.cal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.gualda)),
          child: ListTile(
            leading: Text(d.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(c.practiced.contains(d.id) ? tr('연습 끝') : tr('연습 전')),
            trailing: Icon(c.practiced.contains(d.id) ? Icons.check_circle : Icons.play_circle_outline,
                color: c.practiced.contains(d.id) ? AppColors.lusa : AppColors.beni),
            onTap: () => _push(_PracticeScreen(dialogue: d)),
          ),
        ),
      const SizedBox(height: 8),
      if (c.examScores.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(trf('지난 시험 {0}% — 80% 이상이면 통과. 틀린 편만 다시 연습하세요.', [c.examScores.last]),
              style: const TextStyle(fontSize: 12.5, color: AppColors.er)),
        ),
      FilledButton.icon(
        icon: const Icon(Icons.school_outlined),
        label: Text(c.allPracticed ? tr('코스 시험 보기') : trf('코스 시험 (연습 {0}/{1})', [c.practiced.length, c.dialogueIds.length])),
        onPressed: c.allPracticed ? () => _push(_ExamScreen(dialogues: eps)) : null,
      ),
      const SizedBox(height: 4),
      TextButton(onPressed: () => _push(_CourseBuilder(level: _s.level!)), child: Text(tr('새 코스로 바꾸기'))),
    ];
  }

  Widget _box(Widget child) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.cal, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gualda)),
        child: child,
      );
}

String _goalLabel(String g) => switch (g) {
      'light' => tr('가볍게 · 새 편 1'),
      'focus' => tr('집중 · 새 편 3'),
      _ => tr('보통 · 새 편 2'),
    };

/// 홈 위 커리큘럼 카드 — 「오늘: 복습 N · 새 편 N」 + 진행 막대(§6).
class CurriculumHomeCard extends StatefulWidget {
  final VoidCallback onOpen;
  const CurriculumHomeCard({super.key, required this.onOpen});
  @override
  State<CurriculumHomeCard> createState() => _CurriculumHomeCardState();
}

class _CurriculumHomeCardState extends State<CurriculumHomeCard> {
  @override
  void initState() {
    super.initState();
    CurriculumService.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: CurriculumService.instance.revision,
      builder: (context, _, _) {
        final s = CurriculumService.instance.state;
        final t = dayKey(DateTime.now());
        s.rollDay(t);
        final c = s.course;
        final due = s.dueReviews(t).length;
        final newLeft = c == null || c.passed ? 0 : c.dialogueIds.where((id) => !c.practiced.contains(id)).length;
        final newToday = (s.newGoal - s.newDone).clamp(0, newLeft);
        final total = s.newDone.clamp(0, s.newGoal) + s.reviewDone + due + newToday;
        final done = s.newDone.clamp(0, s.newGoal) + s.reviewDone;
        final finished = s.streakLastDay == t;
        final line = s.level == null
            ? tr('레벨을 고르고 다이얼로그로 코스를 만드세요')
            : finished
                ? '${tr('오늘 분량 끝')} · 🔥 ${trf('{0}일 연속', [s.streakCount])}'
                : trf('오늘: 복습 {0} · 새 편 {1}', [due, newToday]);
        return InkWell(
          onTap: widget.onOpen,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.cal, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gualda)),
            child: Row(children: [
              const TileBadge(text: '🎯', size: 44, color: AppColors.beniDeep),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('토크버스 커리큘럼'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.tinta)),
                  const SizedBox(height: 2),
                  Text(line, style: const TextStyle(fontSize: 12, color: AppColors.tintaLight)),
                  if (s.level != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                          value: finished ? 1 : (total == 0 ? 0 : done / total),
                          minHeight: 5,
                          color: AppColors.lusa,
                          backgroundColor: AppColors.gualda),
                    ),
                  ],
                ]),
              ),
              const Icon(Icons.chevron_right, color: AppColors.gualdaDeep),
            ]),
          ),
        );
      },
    );
  }
}

// ── 코스 만들기: 3·5·10 편 고르기 ──
class _CourseBuilder extends StatefulWidget {
  final String level;
  const _CourseBuilder({required this.level});
  @override
  State<_CourseBuilder> createState() => _CourseBuilderState();
}

class _CourseBuilderState extends State<_CourseBuilder> {
  final _cs = CurriculumService.instance;
  int _n = 5;
  final _picked = <String>[];
  bool _confirm = false;

  List<Dialogue> get _eps => DialogueService.instance.list(region: widget.level);

  @override
  Widget build(BuildContext context) {
    final s = _cs.state;
    final passed = s.passedDialogues.toSet();
    final active = s.course != null && !s.course!.passed;
    return Scaffold(
      backgroundColor: AppColors.calDeep,
      appBar: AppBar(title: Text(tr('코스 만들기'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        children: [
          Text(tr('몇 편으로 할까요?'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: [
            for (final n in const [3, 5, 10])
              ChoiceChip(
                label: Text(trf('{0}편', [n])),
                selected: _n == n,
                onSelected: (_) => setState(() {
                  _n = n;
                  if (_picked.length > n) _picked.removeRange(n, _picked.length);
                }),
              ),
            ActionChip(
              avatar: const Icon(Icons.auto_awesome, size: 16),
              label: Text(tr('추천으로 채우기')),
              onPressed: () => setState(() {
                final r = recommend(_eps, passed, _n, keep: _picked);
                _picked
                  ..clear()
                  ..addAll(r);
              }),
            ),
          ]),
          const SizedBox(height: 8),
          Text(trf('{0}/{1} 고름', [_picked.length, _n]), style: const TextStyle(fontSize: 12.5, color: AppColors.tintaLight)),
          const SizedBox(height: 4),
          for (final d in _eps)
            CheckboxListTile(
              dense: true,
              value: _picked.contains(d.id),
              onChanged: (v) => setState(() {
                if (v == true && _picked.length < _n) {
                  _picked.add(d.id);
                } else {
                  _picked.remove(d.id);
                }
              }),
              secondary: Text(d.emoji, style: const TextStyle(fontSize: 20)),
              title: Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('${tr(DialogueService.islandKo[d.island] ?? d.island)}${passed.contains(d.id) ? ' · ${tr('통과')}' : ''}'),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
        child: _confirm
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                Text(tr('진행 중인 코스를 버리고 새 코스를 시작할까요?'), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() => _confirm = false), child: Text(tr('취소')))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(onPressed: _start, child: Text(tr('새 코스 시작')))),
                ]),
              ])
            : FilledButton(
                onPressed: _picked.isEmpty ? null : () => active ? setState(() => _confirm = true) : _start(),
                child: Text(trf('{0}편으로 코스 시작', [_picked.length])),
              ),
      ),
    );
  }

  Future<void> _start() async {
    _cs.state.course = Course(id: 'c${DateTime.now().millisecondsSinceEpoch}', dialogueIds: [..._picked]);
    await _cs.save();
    if (mounted) Navigator.of(context).pop();
  }
}

// ── 편 연습: 듣기·읽기(줄마다 뜻) + 따라 말하기(줄 반복) → 확인 문제 ──
class _PracticeScreen extends StatefulWidget {
  final Dialogue dialogue;
  const _PracticeScreen({required this.dialogue});
  @override
  State<_PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<_PracticeScreen> {
  final _showKo = <int>{};
  int? _playing;
  bool _playAll = false;

  @override
  void dispose() {
    DialogueAudio.instance.stop();
    super.dispose();
  }

  Future<void> _play(DialogueTurn t) async {
    setState(() => _playing = t.num);
    await speakTurn(widget.dialogue, t);
    if (mounted && _playing == t.num) setState(() => _playing = null);
  }

  Future<void> _playAllTurns() async {
    if (_playAll) {
      _playAll = false;
      await DialogueAudio.instance.stop();
      setState(() => _playing = null);
      return;
    }
    setState(() => _playAll = true);
    for (final t in widget.dialogue.turns) {
      if (!mounted || !_playAll) break;
      await _play(t);
    }
    if (mounted) setState(() => _playAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dialogue;
    return Scaffold(
      backgroundColor: AppColors.calDeep,
      appBar: AppBar(title: Text(d.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        children: [
          Text(tr('줄을 누르면 다시 듣고(따라 말하기), 「뜻」으로 한국어를 봅니다.'), style: const TextStyle(fontSize: 12.5, color: AppColors.tintaLight)),
          const SizedBox(height: 8),
          for (final t in d.turns)
            Card(
              elevation: 0,
              color: _playing == t.num ? AppColors.gualdaBright.withValues(alpha: 0.35) : AppColors.cal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.gualda)),
              child: InkWell(
                onTap: () => _play(t),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                        width: 56,
                        child: Text(d.speakerName(t.speaker),
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.beni, fontWeight: FontWeight.w700))),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(ttsTextShown(t.tl), style: const TextStyle(fontSize: 15.5, color: AppColors.tinta)),
                        if (t.rd.isNotEmpty) Text(t.rd, style: const TextStyle(fontSize: 12, color: AppColors.gualdaDeep)),
                        if (_showKo.contains(t.num)) Text(t.ko, style: const TextStyle(fontSize: 13, color: AppColors.oliva)),
                      ]),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _showKo.contains(t.num) ? _showKo.remove(t.num) : _showKo.add(t.num)),
                      child: Text(tr('뜻')),
                    ),
                  ]),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset(context)),
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(_playAll ? Icons.stop : Icons.play_arrow),
              label: Text(_playAll ? tr('멈춤') : tr('전체 듣기')),
              onPressed: _playAllTurns,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.quiz_outlined),
              label: Text(tr('확인 문제')),
              onPressed: () async {
                _playAll = false;
                await DialogueAudio.instance.stop();
                if (!context.mounted) return;
                final pool = DialogueService.instance.list(region: d.region).where((o) => o.id != d.id).toList();
                final qs = questionsFor(d, pool: pool);
                await Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => _QuizScreen(
                    title: d.title,
                    questions: qs,
                    onDone: (wrong, correct) =>
                        CurriculumService.instance.finishPractice(d, qs, {for (final q in wrong) q.lineId}),
                  ),
                ));
              },
            ),
          ),
        ]),
      ),
    );
  }
}

String ttsTextShown(String tl) => tl.replaceAll('{name}', '…');

// ── 복습 ──
class _ReviewScreen extends StatelessWidget {
  final List<ReviewItem> items;
  const _ReviewScreen({required this.items});

  @override
  Widget build(BuildContext context) {
    final ds = DialogueService.instance;
    final qs = <CurQuestion>[];
    final skip = <String>[];
    for (final r in items) {
      final p = r.lineId.split('#');
      final d = ds.byId(p.first);
      final num = int.tryParse(p.length > 1 ? p[1] : '');
      if (d == null || num == null) {
        skip.add(r.lineId);
        continue;
      }
      final pool = ds.list(region: d.region).where((o) => o.id != d.id).toList();
      final q = questionsFor(d, pool: pool, onlyTurns: [num], seed: DateTime.now().day + num);
      if (q.isEmpty) {
        skip.add(r.lineId);
      } else {
        qs.add(q.first);
      }
    }
    return _QuizScreen(
      title: tr('복습'),
      questions: qs,
      onDone: (wrong, correct) {
        final wrongIds = {for (final q in wrong) q.lineId};
        // 회화 원고가 바뀌어 사라진 줄은 맞힌 것으로 넘겨 대기열에서 빠지게 한다
        return CurriculumService.instance.answerReviews({
          for (final q in qs) q.lineId: !wrongIds.contains(q.lineId),
          for (final id in skip) id: true,
        });
      },
    );
  }
}

// ── 코스 시험 ──
class _ExamScreen extends StatelessWidget {
  final List<Dialogue> dialogues;
  const _ExamScreen({required this.dialogues});

  @override
  Widget build(BuildContext context) {
    final per = examPerDialogue(dialogues.length);
    final seed = DateTime.now().millisecondsSinceEpoch;
    final qs = <CurQuestion>[
      for (final d in dialogues) ...questionsFor(d, max: per, pool: dialogues.where((o) => o.id != d.id).toList(), seed: seed + d.id.hashCode),
    ]..shuffle();
    return _QuizScreen(
      title: tr('코스 시험'),
      questions: qs,
      exam: true,
      onDone: (wrong, correct) =>
          CurriculumService.instance.finishExam(correct, qs.length, {for (final q in wrong) q.dialogueId}),
    );
  }
}

/// 4지선다 문제 풀이 — 연습·복습·시험 공용. 끝나면 [onDone](틀린 문제, 정답 수) 를 부르고 결과를 보인다.
class _QuizScreen extends StatefulWidget {
  final String title;
  final List<CurQuestion> questions;
  final bool exam;
  final Future<Object?> Function(List<CurQuestion> wrong, int correct) onDone;
  const _QuizScreen({required this.title, required this.questions, required this.onDone, this.exam = false});
  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> {
  int _i = 0;
  int? _chosen;
  int _correct = 0;
  final _wrong = <CurQuestion>[];
  bool _finished = false;
  bool? _passed;

  List<CurQuestion> get _qs => widget.questions;

  Future<void> _next() async {
    if (_i + 1 < _qs.length) {
      setState(() {
        _i++;
        _chosen = null;
      });
      return;
    }
    final r = await widget.onDone(_wrong, _correct);
    if (mounted) {
      setState(() {
        _finished = true;
        _passed = r is bool ? r : null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (_qs.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _next());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.calDeep,
      appBar: AppBar(title: Text(widget.title)),
      body: _finished || _qs.isEmpty ? _result() : _question(),
    );
  }

  Widget _result() {
    final total = _qs.length;
    final pct = scorePercent(_correct, total);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(total == 0 ? tr('끝') : '$pct%', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.beniDeep)),
          const SizedBox(height: 6),
          if (total > 0) Text(trf('{0}문제 중 {1}개 정답', [total, _correct])),
          const SizedBox(height: 10),
          if (widget.exam)
            Text(_passed == true ? tr('통과! 코스를 마쳤습니다.') : tr('80% 미만 — 틀린 편만 다시 연습한 뒤 다시 시험을 봅니다.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, color: _passed == true ? AppColors.lusa : AppColors.er))
          else if (_wrong.isNotEmpty)
            Text(tr('틀린 줄은 내일 복습에 나옵니다.'), style: const TextStyle(color: AppColors.tintaLight)),
          const SizedBox(height: 18),
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('돌아가기'))),
        ]),
      ),
    );
  }

  Widget _question() {
    final q = _qs[_i];
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
      children: [
        LinearProgressIndicator(value: (_i + 1) / _qs.length, color: AppColors.beni, backgroundColor: AppColors.gualda),
        const SizedBox(height: 6),
        Text('${_i + 1} / ${_qs.length} · ${q.kind == 'blank' ? tr('빈칸에 들어갈 낱말') : tr('알맞은 뜻')}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.tintaLight)),
        const SizedBox(height: 14),
        Text(q.prompt, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.tinta)),
        if (q.hint.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(q.hint, style: const TextStyle(fontSize: 13, color: AppColors.gualdaDeep)),
        ],
        const SizedBox(height: 18),
        for (final (k, c) in q.choices.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                backgroundColor: _chosen == null
                    ? AppColors.cal
                    : k == q.answer
                        ? AppColors.lusa.withValues(alpha: 0.18)
                        : k == _chosen
                            ? AppColors.fem.withValues(alpha: 0.14)
                            : AppColors.cal,
              ),
              onPressed: _chosen != null
                  ? null
                  : () => setState(() {
                        _chosen = k;
                        if (k == q.answer) {
                          _correct++;
                        } else {
                          _wrong.add(q);
                        }
                      }),
              child: Text(c, style: const TextStyle(fontSize: 15, color: AppColors.tinta)),
            ),
          ),
        if (_chosen != null)
          FilledButton(onPressed: _next, child: Text(_i + 1 < _qs.length ? tr('다음') : tr('결과 보기'))),
      ],
    );
  }
}
