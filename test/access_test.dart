import 'package:flutter_test/flutter_test.dart';
import 'package:portuguese_universe/data/access.dart';
import 'package:portuguese_universe/data/entitlement.dart';
import 'package:portuguese_universe/services/curriculum_service.dart';
import 'package:portuguese_universe/services/dialogue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 이용권 잠금 경계(PAYWALL_SPEC §2·§5): 1단계 열림 · 2단계 잠김 · 이용권 있으면 열림.
void main() {
  final svc = CurriculumService.instance;
  Dialogue d(String region) => Dialogue.fromJson({'id': 'x_$region', 'region': region, 'turns': []});

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Entitlement.set(false);
    svc.applyPlan({
      'rev': 2,
      'freeSteps': 2,
      'freeSenseLevels': 1,
      'stages': [
        {'n': 1, 'title': '1단계', 'dialogueIds': [], 'free': true},
        {'n': 2, 'title': '2단계', 'dialogueIds': [], 'free': false},
        {'n': 3, 'title': '3단계', 'dialogueIds': []}, // free 없음 → 1단계만 무료
      ],
    });
  });
  tearDown(() => svc.applyPlan(const {'rev': 0, 'stages': []}));

  test('이용권 없음: 1단계·R0·R1·문법 1~2·언어감각 1급만 열림', () {
    expect(Access.stageOpen('1'), isTrue);
    expect(Access.stageOpen('2'), isFalse);
    expect(Access.stageOpen('3'), isFalse);
    expect(Access.dialogueOpen(d('R0')), isTrue);
    expect(Access.dialogueOpen(d('R1')), isTrue);
    expect(Access.dialogueOpen(d('L1')), isTrue);
    expect(Access.dialogueOpen(d('R2')), isFalse);
    expect(Access.dialogueOpen(d('R5')), isFalse);
    expect(Access.grammarStepOpen(2), isTrue);
    expect(Access.grammarStepOpen(3), isFalse);
    expect(Access.senseLevelOpen(1), isTrue);
    expect(Access.senseLevelOpen(2), isFalse);
  });

  test('서버 값이 무료 한도를 바꾼다', () {
    svc.applyPlan({
      'rev': 3,
      'freeSteps': 4,
      'freeSenseLevels': 3,
      'stages': [
        {'n': 1, 'dialogueIds': []},
        {'n': 2, 'dialogueIds': [], 'free': true},
      ],
    });
    expect(Access.stageOpen('2'), isTrue);
    expect(Access.grammarStepOpen(4), isTrue);
    expect(Access.senseLevelOpen(3), isTrue);
    expect(Access.senseLevelOpen(4), isFalse);
  });

  test('이용권 있으면 모두 열림', () async {
    await Entitlement.set(true);
    expect(Access.stageOpen('2'), isTrue);
    expect(Access.dialogueOpen(d('R4')), isTrue);
    expect(Access.grammarStepOpen(10), isTrue);
    expect(Access.senseLevelOpen(10), isTrue);
    await Entitlement.set(false);
  });

  test('단계 JSON 이 없으면(옛 R 모드) R0·R1 만 무료', () {
    svc.applyPlan(const {'rev': 0, 'stages': []});
    expect(Access.stageOpen('R1'), isTrue);
    expect(Access.stageOpen('R2'), isFalse);
  });
}
