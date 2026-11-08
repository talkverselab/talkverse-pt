import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/pt_phonetics.dart';
import '../services/tts_service.dart';
import '../widgets/pt_sound_sheet.dart';

/// 문자와 발음 — 유럽 포르투갈어 알파벳·악센트·비모음·자음 조합·모음 약화(일본어앱 「50음도와 발음」 구조, 2026-11-08).
/// 묶음 칩 + 격자 + 한글 독음 토글. 칸 탭 → 발음 시트(1초 뒤 자동 재생).
class PtSoundsScreen extends StatefulWidget {
  const PtSoundsScreen({super.key});
  @override
  State<PtSoundsScreen> createState() => _PtSoundsScreenState();
}

class _PtSoundsScreenState extends State<PtSoundsScreen> {
  int _g = 0;
  bool _rd = true;
  static const _colors = [AppColors.beni, AppColors.beniLight, AppColors.matcha, AppColors.ai, AppColors.kinDeep];

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = kPtSoundGroups[_g];
    final color = _colors[_g % _colors.length];
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('문자와 발음'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(tr('탭하면 발음·IPA 상세'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 2)),
        ]),
        actions: [
          IconButton(
            tooltip: tr('한글 독음'),
            icon: Text('한', style: TextStyle(fontWeight: FontWeight.w900, color: _rd ? AppColors.beni : AppColors.sumiLight)),
            onPressed: () => setState(() => _rd = !_rd),
          ),
        ],
      ),
      body: Column(children: [
        Container(
          color: AppColors.washiDeep,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: SizedBox(
            height: 32,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (var i = 0; i < kPtSoundGroups.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _g = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _g == i ? _colors[i % _colors.length] : AppColors.washi,
                        border: Border.all(color: _colors[i % _colors.length], width: _g == i ? 1.5 : 0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${tr(kPtSoundGroups[i].name)} ${kPtSoundGroups[i].items.length}',
                          style: TextStyle(color: _g == i ? AppColors.washi : _colors[i % _colors.length], fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(g.note, style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final cols = (c.maxWidth / 96).floor().clamp(3, 7);
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 24 + bottomInset(context)),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.95),
              itemCount: g.items.length,
              itemBuilder: (context, i) {
                final s = g.items[i];
                return InkWell(
                  onTap: () => showPtSoundSheet(context, s, color),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.washi,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.7)),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(1, 2))],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      FittedBox(fit: BoxFit.scaleDown, child: Text(s.label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.sumi))),
                      if (_rd && s.rd.isNotEmpty)
                        Text(s.rd, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                      if (s.ipa.isNotEmpty)
                        Text('[${s.ipa}]', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.sumiLight)),
                    ]),
                  ),
                );
              },
            );
          }),
        ),
      ]),
    );
  }
}
