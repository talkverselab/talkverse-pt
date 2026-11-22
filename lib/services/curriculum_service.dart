import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show ValueNotifier;

import '../core/prefs.dart';
import 'dialogue_service.dart';

/// 토크버스 커리큘럼 — 전 언어 공통 기준 `~/talkverse/CURRICULUM_SPEC.md`(2026-11-22).
/// 회화 레벨(R0~R5)에서 다이얼로그를 골라 코스를 만들고 → 편마다 연습·확인 문제 → 간격 반복 복습(1·3·7일)
/// → 코스 시험 80% 이상이면 통과. 하루 목표(새 편 1·2·3 + 복습). 기기 저장, 키 `curriculum_v1`(전 언어 같게).
///
/// 저장 모양(§7): `{level, dailyGoal, course:{id, dialogueIds[], practiced[], examScores[], passedAt},
/// passedDialogues[], review:[{lineId, due, step}], streak:{count, lastDay}}` + 하루 진행 `today:{day, newDone, reviewDone}`.
/// 날짜는 기기 현지 날짜 `yyyy-mm-dd`. lineId = `<편 id>#<턴 번호>`.

const kCurriculumKey = 'curriculum_v1';
const kCurriculumLevels = ['R0', 'R1', 'R2', 'R3', 'R4', 'R5'];
const kReviewIntervals = [1, 3, 7]; // 간격 반복(일)
const kPassPercent = 80;
const kDailyGoals = {'light': 1, 'normal': 2, 'focus': 3};
const kReviewDailyCap = 20; // 하루 복습 상한(밀린 복습이 끝없이 쌓여 보이지 않게)

String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
DateTime _parseDay(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

String addDays(String day, int n) {
  final d = _parseDay(day);
  return dayKey(DateTime(d.year, d.month, d.day + n));
}

/// 점수 = 정답 수 / 문제 수, 소수점 버림(§5).
int scorePercent(int correct, int total) => total <= 0 ? 0 : (correct * 100) ~/ total;
bool isPass(int correct, int total) => scorePercent(correct, total) >= kPassPercent;

class ReviewItem {
  final String lineId;
  String due;
  int step;
  ReviewItem(this.lineId, this.due, this.step);
  Map<String, dynamic> toJson() => {'lineId': lineId, 'due': due, 'step': step};
  factory ReviewItem.fromJson(Map<String, dynamic> j) =>
      ReviewItem('${j['lineId']}', '${j['due']}', (j['step'] as num?)?.toInt() ?? 0);

  /// 복습 답 반영: 맞히면 다음 간격, 틀리면 1일로. 7일 간격을 맞히면 졸업(true 반환 = 대기열에서 뺀다).
  bool answer(bool correct, String today) {
    if (!correct) {
      step = 0;
      due = addDays(today, kReviewIntervals[0]);
      return false;
    }
    if (step >= kReviewIntervals.length - 1) return true;
    step++;
    due = addDays(today, kReviewIntervals[step]);
    return false;
  }
}

class Course {
  final String id;
  final List<String> dialogueIds;
  final List<String> practiced;
  final List<int> examScores;
  String? passedAt;
  Course({required this.id, required this.dialogueIds, List<String>? practiced, List<int>? examScores, this.passedAt})
      : practiced = practiced ?? [],
        examScores = examScores ?? [];
  bool get allPracticed => dialogueIds.every(practiced.contains);
  bool get passed => passedAt != null;
  Map<String, dynamic> toJson() =>
      {'id': id, 'dialogueIds': dialogueIds, 'practiced': practiced, 'examScores': examScores, 'passedAt': passedAt};
  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: '${j['id']}',
        dialogueIds: [for (final e in (j['dialogueIds'] as List? ?? const [])) '$e'],
        practiced: [for (final e in (j['practiced'] as List? ?? const [])) '$e'],
        examScores: [for (final e in (j['examScores'] as List? ?? const [])) (e as num).toInt()],
        passedAt: j['passedAt'] as String?,
      );
}

class CurriculumState {
  String? level;
  String dailyGoal;
  Course? course;
  final List<String> passedDialogues;
  final List<ReviewItem> review;
  int streakCount;
  String? streakLastDay;
  String todayDay;
  int newDone;
  int reviewDone;

  CurriculumState({
    this.level,
    this.dailyGoal = 'normal',
    this.course,
    List<String>? passedDialogues,
    List<ReviewItem>? review,
    this.streakCount = 0,
    this.streakLastDay,
    this.todayDay = '',
    this.newDone = 0,
    this.reviewDone = 0,
  })  : passedDialogues = passedDialogues ?? [],
        review = review ?? [];

  Map<String, dynamic> toJson() => {
        'level': level,
        'dailyGoal': dailyGoal,
        'course': course?.toJson(),
        'passedDialogues': passedDialogues,
        'review': [for (final r in review) r.toJson()],
        'streak': {'count': streakCount, 'lastDay': streakLastDay},
        'today': {'day': todayDay, 'newDone': newDone, 'reviewDone': reviewDone},
      };

  factory CurriculumState.fromJson(Map<String, dynamic> j) {
    final s = (j['streak'] as Map?) ?? const {};
    final t = (j['today'] as Map?) ?? const {};
    return CurriculumState(
      level: j['level'] as String?,
      dailyGoal: kDailyGoals.containsKey(j['dailyGoal']) ? j['dailyGoal'] as String : 'normal',
      course: j['course'] is Map ? Course.fromJson((j['course'] as Map).cast<String, dynamic>()) : null,
      passedDialogues: [for (final e in (j['passedDialogues'] as List? ?? const [])) '$e'],
      review: [for (final e in (j['review'] as List? ?? const [])) ReviewItem.fromJson((e as Map).cast<String, dynamic>())],
      streakCount: (s['count'] as num?)?.toInt() ?? 0,
      streakLastDay: s['lastDay'] as String?,
      todayDay: '${t['day'] ?? ''}',
      newDone: (t['newDone'] as num?)?.toInt() ?? 0,
      reviewDone: (t['reviewDone'] as num?)?.toInt() ?? 0,
    );
  }

  int get newGoal => kDailyGoals[dailyGoal] ?? 2;

  /// 날이 바뀌었으면 하루 진행을 0 으로.
  void rollDay(String today) {
    if (todayDay == today) return;
    todayDay = today;
    newDone = 0;
    reviewDone = 0;
  }

  List<ReviewItem> dueReviews(String today) {
    final due = review.where((r) => r.due.compareTo(today) <= 0).toList()..sort((a, b) => a.due.compareTo(b.due));
    return due.take(kReviewDailyCap).toList();
  }

  /// 오늘 분량 끝 = 새 편 목표를 채웠고(또는 남은 연습 편이 없고) 남은 복습이 없다.
  bool dailyDone(String today, {required bool noNewLeft}) =>
      (newDone >= newGoal || noNewLeft) && dueReviews(today).isEmpty && (newDone + reviewDone) > 0;

  /// 오늘 분량을 다 했을 때 연속 일수 갱신(하루 한 번만 오른다).
  void markDailyDone(String today) {
    if (streakLastDay == today) return;
    streakCount = (streakLastDay != null && addDays(streakLastDay!, 1) == today) ? streakCount + 1 : 1;
    streakLastDay = today;
  }

  /// 연습한 편의 줄을 복습 대기열에 넣는다(이미 있으면 그대로). 틀린 줄은 1일 뒤로 되돌린다.
  void enqueueLines(Iterable<String> lineIds, Set<String> wrong, String today) {
    for (final id in lineIds) {
      final ex = review.where((r) => r.lineId == id).firstOrNull;
      if (ex == null) {
        review.add(ReviewItem(id, addDays(today, kReviewIntervals[0]), 0));
      } else if (wrong.contains(id)) {
        ex.step = 0;
        ex.due = addDays(today, kReviewIntervals[0]);
      }
    }
  }

  void answerReview(String lineId, bool correct, String today) {
    final r = review.where((r) => r.lineId == lineId).firstOrNull;
    if (r == null) return;
    if (r.answer(correct, today)) review.remove(r);
  }

  /// 코스 시험 결과(§5): 80% 이상이면 통과 → 편들을 통과 목록에. 미만이면 틀린 편만 다시 연습하게 연습 표시를 지운다.
  bool applyExam(int correct, int total, Set<String> wrongDialogues, String today) {
    final c = course;
    if (c == null) return false;
    c.examScores.add(scorePercent(correct, total));
    if (isPass(correct, total)) {
      c.passedAt = today;
      for (final id in c.dialogueIds) {
        if (!passedDialogues.contains(id)) passedDialogues.add(id);
      }
      return true;
    }
    c.practiced.removeWhere(wrongDialogues.contains);
    return false;
  }
}

/// 문제 하나 — 4지선다. lineId 는 복습 대기열 열쇠, dialogueId 는 시험에서 틀린 편을 찾을 때.
class CurQuestion {
  final String dialogueId;
  final String lineId;
  final String kind; // meaning · blank
  final String prompt; // 보여 줄 글(포르투갈어 또는 빈칸 문장)
  final String hint; // 아래 보조 글(뜻)
  final List<String> choices;
  final int answer;
  const CurQuestion({
    required this.dialogueId,
    required this.lineId,
    required this.kind,
    required this.prompt,
    required this.hint,
    required this.choices,
    required this.answer,
  });
}

final _wordRe = RegExp(r"[A-Za-zÀ-ÿ]+(?:-[A-Za-zÀ-ÿ]+)*");
String _shown(String tl) => tl.replaceAll('{name}', '…').replaceAll(RegExp(r'\([^)]*\)'), '').trim();

/// 그 편의 줄로 문제 만들기(§3): 뜻 고르기 · 빈칸 낱말 고르기를 번갈아. 오답은 같은 편 → 다른 편 순으로 채운다.
List<CurQuestion> questionsFor(Dialogue d, {int max = 10, List<Dialogue> pool = const [], int? seed, List<int>? onlyTurns}) {
  final rnd = Random(seed ?? d.id.hashCode);
  var turns = d.turns.where((t) => t.ko.trim().isNotEmpty && t.tl.trim().isNotEmpty).toList();
  if (onlyTurns != null) turns = turns.where((t) => onlyTurns.contains(t.num)).toList();
  if (turns.length > max) {
    turns.shuffle(rnd);
    turns = turns.take(max).toList()..sort((a, b) => a.num.compareTo(b.num));
  }
  final otherKo = <String>{
    for (final t in d.turns) t.ko.trim(),
    for (final o in pool) for (final t in o.turns.take(6)) t.ko.trim(),
  }..removeWhere((e) => e.isEmpty);
  final otherWords = <String>{
    for (final t in d.turns) ..._wordRe.allMatches(_shown(t.tl)).map((m) => m.group(0)!).where((w) => w.length > 2),
    for (final o in pool) for (final t in o.turns.take(4)) ..._wordRe.allMatches(_shown(t.tl)).map((m) => m.group(0)!).where((w) => w.length > 2),
  };
  final out = <CurQuestion>[];
  for (var i = 0; i < turns.length; i++) {
    final t = turns[i];
    final lineId = '${d.id}#${t.num}';
    final shown = _shown(t.tl);
    final ms = _wordRe.allMatches(shown).where((m) => m.group(0)!.length > 2).toList();
    if (i.isOdd && ms.isNotEmpty) {
      final m = ms[rnd.nextInt(ms.length)];
      final target = m.group(0)!;
      final wrong = (otherWords.where((w) => w.toLowerCase() != target.toLowerCase()).toList()..shuffle(rnd)).take(3).toList();
      if (wrong.length == 3) {
        final choices = [target, ...wrong]..shuffle(rnd);
        out.add(CurQuestion(
          dialogueId: d.id,
          lineId: lineId,
          kind: 'blank',
          prompt: shown.replaceRange(m.start, m.end, '____'),
          hint: t.ko,
          choices: choices,
          answer: choices.indexOf(target),
        ));
        continue;
      }
    }
    final wrong = (otherKo.where((k) => k != t.ko.trim()).toList()..shuffle(rnd)).take(3).toList();
    if (wrong.length < 3) continue;
    final choices = [t.ko.trim(), ...wrong]..shuffle(rnd);
    out.add(CurQuestion(
      dialogueId: d.id,
      lineId: lineId,
      kind: 'meaning',
      prompt: shown,
      hint: t.rd,
      choices: choices,
      answer: choices.indexOf(t.ko.trim()),
    ));
  }
  return out;
}

/// 코스 시험 문제 수(§5): 편당 최소 3, 전체 최대 30 — 30 을 편 수로 나눠 편당 개수(3~10).
int examPerDialogue(int dialogues) => dialogues <= 0 ? 0 : (30 ~/ dialogues).clamp(3, 10);

/// 「추천으로 채우기」: 아직 통과하지 않은 편에서 주제가 겹치지 않게 돌아가며 고른다.
List<String> recommend(List<Dialogue> level, Set<String> passed, int n, {List<String> keep = const []}) {
  final picked = [...keep];
  final left = level.where((d) => !passed.contains(d.id) && !picked.contains(d.id)).toList();
  final byIsland = <String, List<Dialogue>>{};
  for (final d in left) {
    byIsland.putIfAbsent(d.island, () => []).add(d);
  }
  final used = {for (final id in picked) level.where((d) => d.id == id).firstOrNull?.island};
  while (picked.length < n && byIsland.values.any((l) => l.isNotEmpty)) {
    final keys = byIsland.keys.where((k) => byIsland[k]!.isNotEmpty).toList()
      ..sort((a, b) => (used.contains(a) ? 1 : 0).compareTo(used.contains(b) ? 1 : 0));
    final k = keys.first;
    picked.add(byIsland[k]!.removeAt(0).id);
    if (used.length >= byIsland.length) used.clear();
    used.add(k);
  }
  return picked;
}

/// 저장소 — 기기 SharedPreferences(`pt_` 접두 래퍼) 의 JSON 한 칸.
class CurriculumService {
  CurriculumService._();
  static final CurriculumService instance = CurriculumService._();

  CurriculumState state = CurriculumState();
  final ValueNotifier<int> revision = ValueNotifier(0);
  bool _loaded = false;

  Future<CurriculumState> load() async {
    if (_loaded) return state;
    final raw = (await Prefs.getInstance()).getString(kCurriculumKey);
    if (raw != null) {
      try {
        state = CurriculumState.fromJson(json.decode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    _loaded = true;
    state.rollDay(dayKey(DateTime.now()));
    return state;
  }

  Future<void> save() async {
    await (await Prefs.getInstance()).setString(kCurriculumKey, json.encode(state.toJson()));
    revision.value++;
  }

  String get today => dayKey(DateTime.now());

  /// 회화 데이터에 편이 있는 레벨만(R0~R5 순).
  List<String> levels(DialogueService ds) => [for (final l in kCurriculumLevels) if (ds.count(l) > 0) l];

  /// 레벨이 열렸나: 맨 앞 레벨 · 지금 레벨 · 앞 레벨 편을 모두 통과한 레벨.
  bool unlocked(DialogueService ds, String level) {
    final ls = levels(ds);
    final i = ls.indexOf(level);
    if (i <= 0 || level == state.level) return true;
    final prev = ds.list(region: ls[i - 1]).map((d) => d.id);
    return prev.every(state.passedDialogues.contains);
  }

  /// 편 하나 연습(확인 문제) 끝.
  Future<void> finishPractice(Dialogue d, List<CurQuestion> qs, Set<String> wrongLines) async {
    final t = today;
    state.rollDay(t);
    final c = state.course;
    if (c != null && c.dialogueIds.contains(d.id) && !c.practiced.contains(d.id)) {
      c.practiced.add(d.id);
      state.newDone++;
    }
    state.enqueueLines([for (final turn in d.turns) '${d.id}#${turn.num}'], wrongLines, t);
    _checkDaily(t);
    await save();
  }

  Future<void> answerReviews(Map<String, bool> results) async {
    final t = today;
    state.rollDay(t);
    results.forEach((id, ok) => state.answerReview(id, ok, t));
    state.reviewDone += results.length;
    _checkDaily(t);
    await save();
  }

  Future<bool> finishExam(int correct, int total, Set<String> wrongDialogues) async {
    final ok = state.applyExam(correct, total, wrongDialogues, today);
    await save();
    return ok;
  }

  void _checkDaily(String t) {
    final c = state.course;
    final noNewLeft = c == null || c.allPracticed;
    if (state.dailyDone(t, noNewLeft: noNewLeft)) state.markDailyDone(t);
  }
}
