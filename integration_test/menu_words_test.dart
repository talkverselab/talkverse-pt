// 단어·메뉴 개편 확인용 스크린샷 — 2026-11-07.
// 실행: python3 tools/pane_shots.py <아이패드 UDID> <출력폴더> integration_test/menu_words_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:portuguese_universe/core/l10n.dart';
import 'package:portuguese_universe/data/db/app_database.dart';
import 'package:portuguese_universe/data/db/seed_loader.dart';
import 'package:portuguese_universe/data/entitlement.dart';
import 'package:portuguese_universe/main.dart';
import 'package:portuguese_universe/services/achievement_service.dart';
import 'package:portuguese_universe/services/ko_reading.dart';
import 'package:portuguese_universe/services/learner_prefs.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(WidgetTester t, int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name) async {
    await wait(t, 2000);
    // ignore: avoid_print
    print('SHOT:$name');
    await wait(t, 3000);
  }

  testWidgets('menu + words', timeout: const Timeout(Duration(minutes: 10)), (t) async {
    appDb = AppDatabase();
    await SeedLoader(appDb).seedIfNeeded();
    await KoReadingPrefs.load();
    await AppLangPrefs.load();
    await Entitlement.load();
    await LearnerPrefs.load();
    await AchievementService.instance.load();
    await t.pumpWidget(const PortugueseUniverseApp());
    await wait(t, 3000);
    await shot(t, '40_home_menu');

    await t.scrollUntilVisible(find.text('절벽 단어'), 200, scrollable: find.byType(Scrollable).first);
    await wait(t, 500);
    await t.tap(find.text('절벽 단어').first);
    await wait(t, 2500);
    await shot(t, '41_cliff_words');
    await t.tap(find.textContaining('회화 단어 포함'));
    await wait(t, 800);
    await t.tap(find.text('회화').last);
    await wait(t, 800);
    await shot(t, '42_cliff_conv');

    await t.tap(find.text('앱 소개').first);
    await wait(t, 1500);
    await shot(t, '43_about');

    await t.tap(find.text('프로필').first);
    await wait(t, 1500);
    await shot(t, '44_profile');
  });
}
