import 'package:flutter/material.dart';

import '../services/curriculum_service.dart';
import '../services/dialogue_service.dart';
import 'entitlement.dart';

/// 무료/유료 범위(~/talkverse/PAYWALL_SPEC.md, 2026-11-23 uk 의 정함 — 사용자 「1 2 모두 진행」).
/// 무료 = 커리큘럼 1단계 · 회화 R0·R1(옛 이야기 L1 포함) · 글자/발음/단어 기본 · 문법 1~2스텝 · 언어감각 1급.
/// 그 밖은 이용권(lang_pt_* 또는 all_*). 한도는 서버 커리큘럼 JSON(단계 free · freeSteps · freeSenseLevels)이 정하고, 없으면 위 기본.
/// 잠긴 곳은 숨기지 않고 자물쇠 → 결제 화면(애플 3.1.1·2.1).
class Access {
  Access._();

  static const freeRegions = {'R0', 'R1', 'L1'};

  static bool get premium => Entitlement.premium;

  static bool dialogueFree(Dialogue d) => freeRegions.contains(d.region);
  static bool dialogueOpen(Dialogue d) => premium || dialogueFree(d);

  /// 커리큘럼 단계(또는 옛 R 레벨) 키.
  static bool stageFree(String key) => CurriculumService.instance.stageFree(key);
  static bool stageOpen(String key) => premium || stageFree(key);

  /// 문법 스텝 번호(1부터).
  static bool grammarStepOpen(int step) => premium || step <= CurriculumService.instance.freeSteps;

  /// 언어감각 급 순번(1부터).
  static bool senseLevelOpen(int level) => premium || level <= CurriculumService.instance.freeSenseLevels;

  /// 잠겨 있으면 결제 화면을 띄우고, 닫은 뒤 열렸는지 돌려준다.
  static Future<bool> unlock(BuildContext context, bool open) async {
    if (open) return true;
    await Entitlement.showPaywall(context);
    return premium;
  }
}

/// 잠긴 항목 옆 자물쇠.
class LockIcon extends StatelessWidget {
  final double size;
  const LockIcon({super.key, this.size = 18});
  @override
  Widget build(BuildContext context) => Icon(Icons.lock_outline, size: size, color: const Color(0xFF8A94A6));
}
