import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';
import '../services/word_lookup.dart';

/// 문장의 내용어(레마) 칩 — 단어장에 있는 말은 누르면 단어 시트, 없는 말은 회색(사용자 지시 2026-11-04 "문장 레마별로 단어장이랑 연결").
/// 같은 기본형은 한 번만. 단어장에 없는 레마 목록은 uk 세션이 채운다(`data/review/write/missing_lemmas.csv`).
class LemmaChips extends StatelessWidget {
  final DialogueTurn turn;
  final bool compact;
  const LemmaChips({super.key, required this.turn, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final lemmas = [for (final l in turn.lemmas) if (seen.add(l.base)) l];
    if (lemmas.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<Map<String, WordEntry>>(
      key: ValueKey('${turn.num}:${turn.tl}'),
      future: WordLookup.instance.byLemmas(lemmas.map((l) => l.base)),
      builder: (context, snap) {
        final found = snap.data ?? const {};
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final l in lemmas)
              _Chip(
                label: l.base,
                gloss: found[l.base]?.gloss,
                compact: compact,
                onTap: found[l.base] == null ? null : () => showWordSheet(context, found[l.base]!),
              ),
            if (snap.connectionState == ConnectionState.done && found.isEmpty)
              Padding(padding: const EdgeInsets.only(top: 2), child: Text(tr('단어장에 없는 말'), style: const TextStyle(fontSize: 10, color: AppColors.muted))),
          ],
        );
      },
    );
  }
}

/// 단어 시트 — 단어·독음·뜻·듣기(단어장 화면이 따로 없는 동안의 작은 시트).
Future<void> showWordSheet(BuildContext context, WordEntry e) => showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.washi,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(24, 4, 24, 24 + bottomInset(c)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (e.icon.isNotEmpty) ...[Text(e.icon, style: const TextStyle(fontSize: 30)), const SizedBox(width: 10)],
            Expanded(child: Text(e.word, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.beni))),
            IconButton(onPressed: () => TtsService.instance.speak(e.word), icon: const Icon(Icons.volume_up, color: AppColors.beni, size: 28)),
          ]),
          if (e.rd.isNotEmpty) Text(e.rd, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          const SizedBox(height: 8),
          Text(e.ko, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.sumi)),
          if (e.rank != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(trf('빈도 {0}위', [e.rank]), style: const TextStyle(fontSize: 11, color: AppColors.muted))),
        ]),
      ),
    );

class _Chip extends StatelessWidget {
  final String label;
  final String? gloss;
  final bool compact;
  final VoidCallback? onTap;
  const _Chip({required this.label, this.gloss, this.compact = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 3 : 4),
        decoration: BoxDecoration(
          color: on ? AppColors.washi : AppColors.washiDeep,
          border: Border.all(color: on ? AppColors.beni.withValues(alpha: 0.7) : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: compact ? 12 : 13.5, fontWeight: FontWeight.w800, color: on ? AppColors.sumi : AppColors.muted)),
          if (gloss != null && gloss!.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(gloss!.split(RegExp(r'[,;·/(]')).first.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 10 : 11, color: AppColors.sumiLight)),
          ],
        ]),
      ),
    );
  }
}
