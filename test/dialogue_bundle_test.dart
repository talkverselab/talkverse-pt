import 'package:flutter_test/flutter_test.dart';
import 'package:portuguese_universe/services/dialogue_service.dart';
import 'package:portuguese_universe/services/learner_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 단계 A(2026-11-09): 새 회화 묶음(assets/data/pt-PT/dialogues/<성별>.json)이 레벨 0~5 로 읽히고, 성별을 바꾸면 그 판으로 다시 읽힌다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('레벨 0~5 회화 + 옛 이야기, 성별판 전환', () async {
    final svc = DialogueService.instance;
    await LearnerPrefs.setGender('male');
    await svc.ensureLoaded();
    expect(svc.regions.take(6), ['R0', 'R1', 'R2', 'R3', 'R4', 'R5']);
    expect(svc.regions, contains('L1'));
    final m = svc.byId('r1_love_a1')!;
    expect(m.turns.first.tl, contains('sozinho'));
    expect(m.turns.every((t) => t.rd.isNotEmpty), isTrue);
    expect(m.genders['B'], 'female');
    expect(svc.byId('r1_life_a1')!.genders['B'], 'male'); // Duarte
    expect(m.twist, greaterThan(0));

    await LearnerPrefs.setGender('female');
    await svc.ensureLoaded();
    expect(svc.byId('r1_love_a1')!.turns.first.tl, contains('sozinha'));
    expect(svc.all.where((d) => d.region != 'L1').length, 32);
  });
}
