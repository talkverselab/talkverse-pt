import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portuguese_universe/screens/curriculum_screen.dart';
import 'package:portuguese_universe/services/curriculum_service.dart';
import 'package:portuguese_universe/services/dialogue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Dialogue _d(String id, String island, int n) => Dialogue.fromJson({
      'id': id,
      'region': 'R1',
      'island': island,
      'turns': [
        for (var i = 1; i <= n; i++) {'num': i, 'speaker': i.isOdd ? 'A' : 'B', 'tl': 'Frase$id$i', 'ko': '뜻$id$i'}
      ],
    });

void main() {
  group('점수 80% 경계', () {
    test('소수점 버림', () {
      expect(scorePercent(7, 9), 77);
      expect(scorePercent(2, 3), 66);
      expect(scorePercent(0, 0), 0);
    });
    test('80% 이상만 통과', () {
      expect(isPass(8, 10), isTrue);
      expect(isPass(79, 100), isFalse);
      expect(isPass(4, 5), isTrue);
      expect(isPass(23, 29), isFalse); // 79.3 → 79
      expect(isPass(24, 30), isTrue);
    });
    test('시험 기록 — 통과면 편 통과, 아니면 틀린 편 연습 다시', () {
      final st = CurriculumState(course: Course('c', ['a', 'b'], practiced: ['a', 'b']));
      expect(st.recordExam(7, 10, {'b'}, '2026-11-22'), isFalse);
      expect(st.course!.practiced, ['a']);
      expect(st.passedDialogues, isEmpty);
      st.course!.practiced.add('b');
      expect(st.recordExam(8, 10, {}, '2026-11-23'), isTrue);
      expect(st.course!.passedAt, '2026-11-23');
      expect(st.passedDialogues, ['a', 'b']);
      expect(st.course!.examScores, [70, 80]);
    });
  });

  group('간격 반복 날짜', () {
    test('1일 → 3일 → 7일 → 졸업', () {
      final st = CurriculumState();
      st.enqueue('x#1', '2026-11-22');
      expect(st.review.single.due, '2026-11-23');
      st.grade('x#1', true, '2026-11-23');
      expect(st.review.single.due, '2026-11-26');
      st.grade('x#1', true, '2026-11-26');
      expect(st.review.single.due, '2026-12-03');
      st.grade('x#1', true, '2026-12-03');
      expect(st.review, isEmpty);
    });
    test('틀리면 1일 뒤 처음 간격으로', () {
      final st = CurriculumState();
      st.enqueue('x#1', '2026-11-22');
      st.grade('x#1', true, '2026-11-23');
      st.grade('x#1', false, '2026-11-26');
      expect(st.review.single.step, 0);
      expect(st.review.single.due, '2026-11-27');
    });
    test('달·해 넘김', () {
      expect(addDays('2026-12-30', 3), '2027-01-02');
      expect(addDays('2028-02-28', 1), '2028-02-29');
    });
  });

  group('하루 분량·연속', () {
    test('새 편 목표를 채우고 복습이 없으면 끝, 연속 일수', () {
      final st = CurriculumState(dailyGoal: 1, course: Course('c', ['a', 'b']));
      expect(st.dayDone('2026-11-22'), isFalse);
      st.markPracticed('a', [1, 2], '2026-11-22');
      expect(st.dayDone('2026-11-22'), isTrue);
      expect(st.streakShown('2026-11-22'), 1);
      // 다음 날: 복습 2줄 + 새 편 1
      expect(st.dueReview('2026-11-23').length, 2);
      st.grade('a#1', true, '2026-11-23');
      st.grade('a#2', true, '2026-11-23');
      st.markPracticed('b', [1], '2026-11-23');
      expect(st.todayReview, 2);
      expect(st.streakShown('2026-11-23'), 2);
      expect(st.streakShown('2026-11-25'), 0);
    });
    test('저장 형식 왕복', () {
      final st = CurriculumState(level: 'R1', course: Course('c', ['a']));
      st.markPracticed('a', [1], '2026-11-22');
      final back = CurriculumState.fromJson(st.toJson());
      expect(back.toJson(), st.toJson());
      expect(st.toJson().keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
    });
  });

  group('문제·추천', () {
    test('편마다 줄 수만큼, 최대 10, 보기 4개 중 정답 1', () {
      final a = _d('a', 'friends', 12), b = _d('b', 'life', 4);
      final qs = buildQuestions(a, limit: 10, pool: [b]);
      expect(qs.length, 10);
      for (final q in qs) {
        expect(q.choices.length, 4);
        expect(q.choices.toSet().length, 4);
        expect(q.choices[q.answer], '뜻a${q.turn}');
      }
      expect(buildQuestions(b, limit: 10, pool: [a]).length, 4);
    });
    test('시험 문제 수: 편당 최소 3, 전체 최대 30', () {
      expect(examPerDialogue(3), 10);
      expect(examPerDialogue(5), 6);
      expect(examPerDialogue(10), 3);
    });
    test('추천 = 안 한 편, 주제 겹치지 않게', () {
      final list = [_d('f1', 'friends', 2), _d('f2', 'friends', 2), _d('l1', 'life', 2), _d('w1', 'work', 2)];
      final r = recommend(list, {'l1'}, {}, 3);
      expect(r, ['f1', 'w1', 'f2']);
    });
  });

  testWidgets('시험 화면 — 고르고 결과까지', (t) async {
    final a = _d('a', 'friends', 5);
    final qs = buildQuestions(a, limit: 2);
    await t.pumpWidget(MaterialApp(home: CurriculumQuizScreen(title: 'T', questions: qs, mode: QuizMode.exam)));
    for (var i = 0; i < 2; i++) {
      await t.tap(find.text(qs[i].choices[qs[i].answer]));
      await t.pump();
      await t.tap(find.byType(FilledButton).last);
      await t.pump();
    }
    expect(find.textContaining('100'), findsOneWidget);
  });

  test('포르투갈어 실제 회화 65편 — 문제 4지선다·보기 중복 없음', () {
    for (final g in ['male', 'female']) {
      final list = jsonDecode(File('assets/data/pt-PT/dialogues/$g.json').readAsStringSync()) as List;
      final ds = [for (final e in list) Dialogue.fromJson(e as Map<String, dynamic>)];
      expect(ds.length, 65);
      for (final d in ds) {
        final qs = buildQuestions(d, limit: 10, pool: ds.where((o) => o.region == d.region && o.id != d.id).toList());
        expect(qs, isNotEmpty, reason: d.id);
        for (final q in qs) {
          expect(q.choices.toSet().length, 4, reason: '${q.lineId} ${q.choices}');
          expect(q.answer, inInclusiveRange(0, 3));
        }
      }
    }
  });

  for (final size in const [Size(360, 740), Size(834, 1194)]) {
    testWidgets('커리큘럼 첫 화면 넘침 없음 ${size.width}', (t) async {
      SharedPreferences.setMockInitialValues({});
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.runAsync(() async {
        await t.pumpWidget(const MaterialApp(home: CurriculumScreen()));
        await Future<void>.delayed(const Duration(seconds: 3));
      });
      await t.pump();
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('코스 고르기 칩 줄 — 300·360·744 폭에서 넘치지 않음', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(300, 900);
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: CurriculumScreen()));
    for (var i = 0; i < 10; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await t.pump();
    }
    expect(find.text('단계를 골라요'), findsOneWidget);
    await t.tap(find.text('1단계'));
    for (var i = 0; i < 3; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump();
    }
    await t.tap(find.text('추천으로 채우기'));
    await t.pump();
    expect(find.text('5/5편으로 코스 시작'), findsOneWidget);
    for (final w in [300.0, 360.0, 744.0]) {
      t.view.physicalSize = Size(w, 900);
      await t.pump();
      expect(t.takeException(), isNull);
    }
  });

  group('§12 단계(1~5) — 서버 JSON·앱 안 기본값', () {
    final svc = CurriculumService.instance;
    final eps = [for (final e in jsonDecode(File('assets/data/pt-PT/dialogues/male.json').readAsStringSync()) as List) Dialogue.fromJson(e as Map<String, dynamic>)];
    tearDown(() => svc.applyPlan(const {'rev': 0, 'stages': []}));

    test('앱 안 기본 JSON: 단계 5개, 편 id 가 모두 앱 회화에 있다, 기본 대응 R0+R1→1 …', () {
      final j = jsonDecode(File('assets/curriculum_pt.json').readAsStringSync()) as Map<String, dynamic>;
      final ids = {for (final d in eps) d.id};
      final stages = j['stages'] as List;
      expect(stages.length, 5);
      final region = {for (final d in eps) d.id: d.region};
      const m = {'R0': 1, 'R1': 1, 'R2': 2, 'R3': 3, 'R4': 4, 'R5': 5};
      for (final st in stages) {
        for (final id in st['dialogueIds'] as List) {
          expect(ids, contains(id));
          expect(m[region[id]], st['n']);
        }
      }
      expect((j['prep'] as List), isEmpty);
    });

    test('앱에 없는 편 id 는 건너뛰고, 편이 0개인 단계는 숨김, 다음 단계', () {
      svc.applyPlan({
        'rev': 2,
        'stages': [
          {'n': 1, 'title': '1단계', 'dialogueIds': ['없는편', eps.first.id]},
          {'n': 2, 'title': '2단계', 'dialogueIds': ['없는편2']},
          {'n': 3, 'title': '3단계', 'dialogueIds': [eps.last.id], 'pick': [3, 5]},
        ]
      });
      expect(svc.stageMode, isTrue);
      // 시험에선 DialogueService 를 읽지 않으므로 byId 가 비어 있을 수 있다 — 목록 키는 편이 있는 단계만
      final keys = svc.levelKeys;
      expect(keys.contains('2'), isFalse);
      expect(svc.pickOptions('3'), [3, 5]);
      expect(svc.levelTitle('1'), '1단계');
    });

    test('옛 R 값·숫자 단계 저장 왕복', () {
      final st = CurriculumState(level: '3');
      final back = CurriculumState.fromJson(jsonDecode(jsonEncode(st.toJson())) as Map);
      expect(jsonDecode(jsonEncode(st.toJson()))['level'], 3);
      expect(back.level, '3');
      expect(CurriculumService.rToStage['R0'], '1');
      expect(CurriculumService.rToStage['R2'], '2');
    });

    test('서버 rev 가 더 높을 때만 바꿔 쓴다, 실패·빈 단계면 그대로', () async {
      SharedPreferences.setMockInitialValues({});
      svc.applyPlan({'rev': 1, 'stages': [{'n': 1, 'title': '1단계', 'dialogueIds': []}]});
      expect(await svc.refreshPlan(fetch: (_) async => null), isFalse);
      expect(await svc.refreshPlan(fetch: (_) async => jsonEncode({'rev': 1, 'stages': [{'n': 9}]})), isFalse);
      expect(await svc.refreshPlan(fetch: (_) async => jsonEncode({'rev': 5, 'stages': []})), isFalse);
      expect(await svc.refreshPlan(fetch: (_) async => jsonEncode({'rev': 5, 'stages': [{'n': 1, 'title': '서버 1단계', 'dialogueIds': []}]})), isTrue);
      expect(svc.planRev, 5);
      expect(svc.levelTitle('1'), '서버 1단계');
    });

    test('계획이 없으면 옛 동작(회화 레벨)', () {
      svc.applyPlan(const {'rev': 0, 'stages': []});
      expect(svc.stageMode, isFalse);
      expect(svc.levelTitle('R1'), DialogueService.levelKo['R1']);
    });
  });
}
