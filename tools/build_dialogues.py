#!/usr/bin/env python3
"""회화 원본(성별 표시 {남|여}) → 판별 파일 + 독음 + 검사 — 2026-11-07.
  python3 tools/build_dialogues.py data/dialogues_src/pt-PT/sample_r1_r4.json
출력 assets/data/pt-PT/dialogues/<male|female>/R<n>/<주제>/<id>.json (CLAUDE.md §9·§10). pubspec 에 넣기 전까지 앱에 묶이지 않는다.
사람이 읽을 판: data/review/write/dialogues_pt_review.md (턴마다 목표어/독음/한국어). 오류가 있으면 종료 코드 1."""
import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'tools'))
from rd_pt import rd  # noqa: E402

# 폴더 R 숫자 = 회화 레벨 = 문법 단계(굴절어 전략 A1, docs/DIALOGUE_RULES_pt.md): 0 소리·짧은 회화 · 1 활용 골격 · 2 챗 실전 · 3 그래머2 · 4 어려운 문법 · 5 어휘 완주
TURNS = {'R0': (6, 8), 'R1': (6, 8), 'R2': (8, 12), 'R3': (12, 16), 'R4': (12, 16), 'R5': (12, 16)}
WORDS = {'R0': (2, 8), 'R1': (3, 10), 'R2': (1, 14), 'R3': (1, 20), 'R4': (1, 20), 'R5': (1, 20)}  # CLAUDE.md §10. 채팅은 R1 하한을 보지 않는다
TWIST = {'chaos', 'slip', 'reveal', 'emotion', 'ignore'}
PICK = re.compile(r'\{([^{}|]*)\|([^{}|]*)\}')


def pick(s, g):
    return PICK.sub(lambda m: m.group(1 if g == 'male' else 2), s)


def words(s):
    return re.findall(r"\{[a-z_]+\}|[^\W\d_]+(?:-[^\W\d_]+)*", s)


errs = []
review = ['# 포르투갈어 회화 초안(유럽판, Claude 초안)\n']
for src in sys.argv[1:]:
    for ep in json.load(open(src, encoding='utf-8')):
        i, reg = ep['id'], ep['region']
        lo, hi = TURNS[reg]
        if not lo <= len(ep['turns']) <= hi:
            errs.append(f"{i}: 턴 {len(ep['turns'])}개(기준 {lo}~{hi})")
        if ep.get('twist_type') not in TWIST or not 1 <= ep.get('twist', 0) <= len(ep['turns']):
            errs.append(f'{i}: 반전 표시')
        if not ep.get('cast') or any(k != 'A' and k not in ep['cast'] for k in ep['speakers']):
            errs.append(f'{i}: cast(화자 → 목소리) 없음')
        if 'twist' not in ep['turns'][ep['twist'] - 1].get('tags', []):
            errs.append(f"{i}: {ep['twist']}턴에 twist 태그 없음")
        for g in ('male', 'female'):
            out = {k: v for k, v in ep.items() if k != 'turns'}
            out.update(variant='pt-PT', learner_gender=g, draft=True, title=pick(ep['title'], g), scene=pick(ep['scene'], g), turns=[])
            for n, t in enumerate(ep['turns'], 1):
                tl = pick(t['tl'], g)
                w = len(words(tl))
                a, b = WORDS[reg]
                if w > b or (w < a and ep['kind'] != 'chat' and not (reg == 'R0' and w >= 1 and n > 1)):
                    errs.append(f'{i} {n}턴: {w}단어 「{tl}」')
                if re.search(r'(?<![,.!?…:]\s)(?<!^)(?<![{|]o\|a\} )(?<!\{O\|A\} )\{name\}', t['tl']):
                    errs.append(f'{i} {n}턴: {{name}} 앞에 성별 관사 {{o|a}} 필요(호격이 아니면)')
                if not (t.get('emotion') or t.get('segs')):
                    errs.append(f'{i} {n}턴: 감정 없음(emotion 또는 segs)')
                r = rd(tl)
                if re.search(r'[a-zA-Zà-ÿ]', re.sub(r'\{[a-z_]+\}', '', r)) and not re.search(r'[A-Z]', tl):
                    errs.append(f'{i} {n}턴: 독음에 로마자 「{r}」')
                row = {**t, 'num': n, 'tl': tl, 'rd': r, 'ko': pick(t['ko'], g), 'note': pick(t['note'], g)}
                if t.get('segs'):
                    row['segs'] = [[x[0]] + [pick(y, g) for y in x[1:]] for x in t['segs']]
                out['turns'].append(row)
            p = ROOT / f"assets/data/pt-PT/dialogues/{g}/{reg}/{ep['island']}/{i}.json"
            p.parent.mkdir(parents=True, exist_ok=True)
            json.dump(out, open(p, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
            if g == 'female':
                continue
            review.append(f"\n## {reg} · {out['title']} {out['emoji']} (`{i}`, 반전 {ep['twist']}턴 {ep['twist_type']})\n\n{out['scene']}\n")
            for t in out['turns']:
                sp = ep['speakers'][t['speaker']]
                diff = '' if '|' not in ep['turns'][t['num'] - 1]['tl'] else f"  \n여성판: {pick(ep['turns'][t['num'] - 1]['tl'], 'female')}"
                review.append(f"**{t['num']}. {sp}** {t['tl']}  \n{t['rd']}  \n{t['ko']}{diff}\n")
Path(ROOT / 'data/review/write/dialogues_pt_review.md').write_text('\n'.join(review), encoding='utf-8')
print('\n'.join(errs) or '검사 통과')
sys.exit(1 if errs else 0)
