import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/pt_phonetics.dart';
import '../services/tts_service.dart';

/// 글자 탭 → 발음 상세 시트(일본어앱 kana_sound_sheet 이식). 열리면 1초 뒤 자동 재생, 다시 듣기·IPA·소리 나는 곳·한국어 비교.
/// 조음 위치 그림은 임시(출시 전 공용 그림으로 교체).
Future<void> showPtSoundSheet(BuildContext context, PtSound s, Color color) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.washi,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _Sheet(s: s, color: color),
    );

class _Sheet extends StatefulWidget {
  final PtSound s;
  final Color color;
  const _Sheet({required this.s, required this.color});
  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  Timer? _auto;
  bool _chart = false;

  @override
  void initState() {
    super.initState();
    _auto = Timer(const Duration(seconds: 1), _play);
  }

  void _play() => TtsService.instance.speak(widget.s.speak);

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s, c = widget.color;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => SafeArea(
        top: false,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset(context)),
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                constraints: const BoxConstraints(minWidth: 84),
                height: 84,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
                child: FittedBox(child: Text(s.label, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.washi))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (s.rd.isNotEmpty) Text(s.rd, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c)),
                  if (s.ipa.isNotEmpty) Text('IPA [${s.ipa}]', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                ]),
              ),
              IconButton(iconSize: 44, color: c, tooltip: tr('다시 듣기'), icon: const Icon(Icons.play_circle_fill), onPressed: _play),
            ]),
            const SizedBox(height: 14),
            _box(tr('🔊 예시'), '${s.example}\n${s.exampleKo}', c),
            const SizedBox(height: 12),
            _box(tr('👄 소리 나는 곳 · 입모양'), s.place, c),
            if (s.consonant) ...[
              InkWell(
                onTap: () => setState(() => _chart = !_chart),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Icon(_chart ? Icons.expand_less : Icons.expand_more, size: 18, color: c),
                    Text(tr('자음 조음 위치 그림 보기'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
                  ]),
                ),
              ),
              if (_chart)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(color: Colors.white, padding: const EdgeInsets.all(8), child: Image.asset('assets/images/ipa/places_of_articulation.png', fit: BoxFit.contain)),
                ),
            ],
            const SizedBox(height: 12),
            _box(tr('🇰🇷 한국어와 비교'), trf('비슷한 소리: {0}\n\n{1}', [s.korSim, s.korDiff]), c),
          ],
        ),
      ),
    );
  }

  Widget _box(String title, String body, Color c) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.35))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.sumi)),
        ]),
      );
}
