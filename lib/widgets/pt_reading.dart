import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';

/// 유럽 포르투갈어 한글 독음 표시 — 시안 PT-01 칸 ②(2026-11-03).
/// 독음 문자열만 보고 확실히 알 수 있는 두 소리만 칠한다(데이터는 그대로):
/// - 「쉬」 = 음절 끝·자음 앞 s·z → 옅은 아줄레주 바탕
/// - 「아웅」의 「웅」 = 비모음 ão → 물결 밑줄
/// 약해지는 모음(de → 드)은 독음만으로는 원래 철자를 알 수 없어 칠하지 않는다.
class PtReadingText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const PtReadingText(this.text, {super.key, required this.style});

  static final _mark = RegExp(r'쉬|(?<=아)웅');

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    var i = 0;
    for (final m in _mark.allMatches(text)) {
      if (m.start > i) spans.add(TextSpan(text: text.substring(i, m.start)));
      final s = m.group(0)!;
      spans.add(TextSpan(
        text: s,
        style: s == '쉬'
            ? const TextStyle(backgroundColor: Color(0xFFDCE8F5), color: AppColors.beniDeep)
            : const TextStyle(
                color: AppColors.beniDeep,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.wavy,
                decorationColor: AppColors.beniLight,
              ),
      ));
      i = m.end;
    }
    if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
    return Text.rich(TextSpan(style: style, children: spans));
  }

  /// 범례(독음 칩 옆 ⓘ).
  static Future<void> showLegend(BuildContext context) => showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(tr('독음 표시')),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            PtReadingText(tr('쉬 — 음절 끝 s·z (Lisboa 리쉬보아)'), style: const TextStyle(fontSize: 14, color: AppColors.sumi)),
            const SizedBox(height: 8),
            PtReadingText(tr('아웅 — 콧소리 ão (então 엔따웅)'), style: const TextStyle(fontSize: 14, color: AppColors.sumi)),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('확인')))],
        ),
      );
}
