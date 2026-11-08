// 문자와 발음 확인용 스크린샷 — 2026-11-08. 실행: python3 tools/pane_shots.py <UDID> <출력폴더> integration_test/pt_sounds_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:portuguese_universe/screens/pt_sounds_screen.dart';

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

  Future<void> shot(WidgetTester t, String n) async {
    await wait(t, 1500);
    // ignore: avoid_print
    print('SHOT:$n');
    await wait(t, 2500);
  }

  testWidgets('sounds', (t) async {
    await t.pumpWidget(const MaterialApp(home: PtSoundsScreen()));
    await wait(t, 1500);
    await shot(t, '50_alphabet');
    await t.tap(find.text('비모음 8'));
    await wait(t, 800);
    await t.tap(find.text('ão'));
    await wait(t, 2500);
    await shot(t, '51_sheet_ao');
  });
}
