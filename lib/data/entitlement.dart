import 'package:flutter/material.dart';
import '../core/prefs.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';

/// 무료/유료 구분 — Talkverse ID 이용권(lang 'pt', auth.talkverse.uk) 또는 이 기기에서 산·복원한 평생 이용권(스토어).
/// `premium` = 기기 제작용 스위치 OR 계정 이용권 OR 스토어 구매 (한자 앱과 같은 방식, 2026-11-02).
/// 아직 잠근 화면은 없다 — 무엇을 유료로 둘지는 사용자 결정 대기(HANDOFF.md).
class Entitlement {
  Entitlement._();
  static const lang = 'pt';
  static bool _local = false;
  static bool get premium => _local || Account.has(lang) || Purchase.owns(lang);

  static Future<void> load() async => _local = (await Prefs.getInstance()).getBool('premium') ?? false;
  static Future<void> set(bool v) async {
    _local = v;
    (await Prefs.getInstance()).setBool('premium', v);
  }

  /// 잠금 안내 + 평생 이용권 구매·복원 시트.
  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}
