import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portuguese_universe/screens/about_screen.dart';
import 'package:portuguese_universe/screens/pt_sounds_screen.dart';
import 'package:portuguese_universe/screens/word_freq_screen.dart';

/// 폰·아이패드 폭에서 화면이 넘치지 않는지(시뮬레이터 없이 확인).
void main() {
  for (final size in const [Size(360, 740), Size(834, 1194)]) {
    testWidgets('앱 소개 ${size.width}', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: AboutScreen()));
      await t.pump();
      expect(find.text('1. 유럽판 기준'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('절벽 단어 ${size.width}', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      // 번들 읽기가 실제로 끝나도록 진짜 시간 안에서 띄운다
      await t.runAsync(() async {
        await t.pumpWidget(const MaterialApp(home: WordFreqScreen()));
        await Future<void>.delayed(const Duration(seconds: 3));
      });
      await t.pump();
      await t.pump();
      expect(find.text('#1-20'), findsOneWidget);
      expect(find.textContaining('(+5)'), findsOneWidget);
      await t.tap(find.textContaining('회화 단어 포함'));
      await t.pump();
      await t.tap(find.text('R1 · 1-55'));
      await t.pump();
      expect(find.text('#1-20'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  for (final size in const [Size(360, 740), Size(834, 1194)]) {
    testWidgets('문자와 발음 ${size.width}', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: PtSoundsScreen()));
      await t.pump();
      expect(find.text('A a'), findsOneWidget);
      for (final chip in ['모음·악센트 8', '비모음 8', '자음 조합 8', '모음 약화 4']) {
        await t.ensureVisible(find.text(chip));
        await t.pump();
        await t.tap(find.text(chip));
        await t.pump();
        expect(t.takeException(), isNull);
      }
      expect(find.text('e → 으'), findsOneWidget);
    });
  }
}
