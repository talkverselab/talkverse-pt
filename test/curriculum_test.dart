import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portuguese_universe/screens/curriculum_screen.dart';
import 'package:portuguese_universe/services/curriculum_service.dart';
import 'package:portuguese_universe/services/dialogue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 토크버스 커리큘럼(CURRICULUM_SPEC.md) — 80% 경계, 간격 반복 날짜, 시험·복습 흐름.
void main() {
  group('점수 80% 경계', () {
    test('소수점 버림', () {
      expect(scorePercent(8, 10), 80);
      expect(isPass(8, 10), isTrue);
      expect(scorePercent(7, 9), 77);
      expect(isPass(7, 9), isFalse);
      expect(scorePercent(23, 29), 79); // 79.3 → 79, 불통
      expect(isPass(23, 29), isFalse);
      expect(isPass(24, 30), isTrue);
      expect(scorePercent(0, 0), 0);
    });
  });

  group('간격 반복 1·3·7일', () {
    test('맞히면 다음 간격, 틀리면 1일, 7일 맞히면 졸업', () {
      final r = ReviewItem('d#1', '2026-11-23', 0);
      expect(r.answer(true, '2026-11-23'), isFalse);
      expect((r.step, r.due), (1, '2026-11-26'));
      expect(r.answer(true, '2026-11-26'), isFalse);
      expect((r.step, r.due), (2, '2026-12-03'));
      expect(r.answer(false, '2026-12-03'), isFalse);
      expect((r.step, r.due), (0, '2026-12-04'));
      r.step = 2;
      expect(r.answer(true, '2026-12-10'), isTrue);
    });
    test('월·해 넘김', () {
      expect(addDays('2026-12-31', 1), '2027-01-01');
      expect(addDays('2027-02-27', 3), '2027-03-02');
    });
    test('연습한 줄은 1일 뒤 대기열, 틀린 줄은 1일로 되돌림', () {
      final s = CurriculumState();
      s.enqueueLines(['a#1', 'a#2'], {}, '2026-11-22');
      expect(s.review.map((r) => r.due), ['2026-11-23', '2026-11-23']);
      s.answerReview('a#1', true, '2026-11-23');
      expect(s.review.first.due, '2026-11-26');
      s.enqueueLines(['a#1'], {'a#1'}, '2026-11-24');
      expect((s.review.first.step, s.review.first.due), (0, '2026-11-25'));
      expect(s.dueReviews('2026-11-23').map((r) => r.lineId), ['a#2']);
    });
  });

  group('코스 시험·하루 분량', () {
    test('80% 이상 통과, 미만이면 틀린 편만 연습 해제', () {
      final s = CurriculumState(course: Course(id: 'c', dialogueIds: ['a', 'b'], practiced: ['a', 'b']));
      expect(s.applyExam(5, 10, {'b'}, '2026-11-22'), isFalse);
      expect(s.course!.practiced, ['a']);
      expect(s.course!.examScores, [50]);
      s.course!.practiced.add('b');
      expect(s.applyExam(8, 10, {'a'}, '2026-11-23'), isTrue);
      expect(s.passedDialogues, ['a', 'b']);
      expect(s.course!.passedAt, '2026-11-23');
    });
    test('연속 일수', () {
      final s = CurriculumState();
      s.markDailyDone('2026-11-22');
      s.markDailyDone('2026-11-22');
      s.markDailyDone('2026-11-23');
      expect(s.streakCount, 2);
      s.markDailyDone('2026-11-25');
      expect(s.streakCount, 1);
    });
    test('시험 문제 수: 편당 3 이상, 전체 30 이하', () {
      for (final n in [3, 5, 10]) {
        expect(examPerDialogue(n) >= 3, isTrue);
        expect(examPerDialogue(n) * n <= 30, isTrue);
      }
    });
    test('저장 모양 왕복', () {
      final s = CurriculumState(level: 'R1', course: Course(id: 'c', dialogueIds: ['a']));
      s.enqueueLines(['a#1'], {}, '2026-11-22');
      final j = jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>;
      expect(j.keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
      final back = CurriculumState.fromJson(j);
      expect((back.level, back.review.single.lineId), ('R1', 'a#1'));
      expect(back.course!.dialogueIds, ['a']);
    });
  });

  test('실제 회화 묶음으로 문제 만들기·추천', () {
    final list = jsonDecode(File('assets/data/pt-PT/dialogues/male.json').readAsStringSync()) as List;
    final ds = [for (final e in list) Dialogue.fromJson(e as Map<String, dynamic>)];
    for (final d in ds) {
      final qs = questionsFor(d, pool: ds.where((o) => o.region == d.region && o.id != d.id).toList());
      expect(qs, isNotEmpty, reason: d.id);
      expect(qs.length <= 10, isTrue);
      for (final q in qs) {
        expect(q.choices.length, 4);
        expect(q.choices.toSet().length, 4, reason: '${q.lineId} ${q.choices}');
        expect(q.answer, inInclusiveRange(0, 3));
        if (q.kind == 'blank') expect(q.prompt.contains('____'), isTrue, reason: q.prompt);
      }
    }
    final r1 = ds.where((d) => d.region == 'R1').toList();
    final pick = recommend(r1, {}, 5);
    expect(pick.length, 5);
    expect(pick.toSet().length, 5);
    final islands = pick.map((id) => r1.firstWhere((d) => d.id == id).island).toSet();
    expect(islands.length, greaterThanOrEqualTo(3));
  });

  for (final size in const [Size(360, 740), Size(834, 1194)]) {
    testWidgets('커리큘럼 화면 ${size.width}', (t) async {
      SharedPreferences.setMockInitialValues({});
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.runAsync(() async {
        await t.pumpWidget(const MaterialApp(home: CurriculumScreen()));
        await Future<void>.delayed(const Duration(seconds: 3));
      });
      await t.pump();
      expect(find.text('회화 레벨을 고르세요'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
