#!/usr/bin/env python3
"""회화 원본 JSON ↔ Grok 재작성용 편별 글(2026-11-09).
  python3 tools/grok/pt_dialogue_txt.py export            원본 전부 → data/review/grok/src/<id>.txt
  python3 tools/grok/pt_dialogue_txt.py import [id ...]   data/review/grok/out/<id>.md → 원본 JSON 에 대사·뜻·감정·태그만 바꿔 넣음
턴 줄 = `A | 포르투갈어 | 한국어 | note | emotion=x(+y…) | tags=a,b`. 감정이 둘 이상이면 문장마다 하나(+ 로 이음) → segs.
줄 수·화자 순서가 원본과 다르면 그 편은 넣지 않고 알린다. 채팅 칸(ui·at·read·stamp)은 원본 것을 그대로 둔다."""
import glob
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = sorted(glob.glob(str(ROOT / 'data/dialogues_src/pt-PT/*.json')))
TXT = ROOT / 'data/review/grok/src'
OUT = ROOT / 'data/review/grok/out'
EMO = set('neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle'.split())
SENT = re.compile(r'(?<=[.!?…»])\s+(?=\S)')


def sentences(tl):
    out = []
    for s in SENT.split(tl):
        if out and not re.search(r'[^\W\d_]', s):  # 이모지·기호만 남은 조각은 앞 문장에 붙인다
            out[-1] += ' ' + s
        elif s.strip():
            out.append(s)
    return out


def export():
    TXT.mkdir(parents=True, exist_ok=True)
    n = 0
    for f in SRC:
        for ep in json.load(open(f, encoding='utf-8')):
            others = ', '.join(f'{k}: {v}' for k, v in ep['speakers'].items() if k != 'A')
            L = [f"=== {ep['id']}", f"level: {ep['region']}", f"kind: {ep['kind']}", f"title: {ep['title']}",
                 f"emoji: {ep['emoji']}", f"scene: {ep['scene']}", f"cast: {others}", f"register: {ep['register']}",
                 f"twist: {ep['twist']} {ep['twist_type']}", f"goal: {ep['goal']}", f"expressions: {'; '.join(ep['expressions'])}"]
            for t in ep['turns']:
                emo = '+'.join(s[0] for s in t['segs']) if t.get('segs') else t['emotion']
                say, tl = '', t['tl']
                if t.get('segs'):
                    tl = ' // '.join(x[1].strip() for x in t['segs'])
                    if any(len(x) > 2 for x in t['segs']):
                        say = ' | say=' + ' // '.join((x[2] if len(x) > 2 else x[1]).strip() for x in t['segs'])
                L.append(f"{t['speaker']} | {tl} | {t['ko']} | {t['note']} | emotion={emo} | tags={','.join(t.get('tags', []))}{say}")
            (TXT / f"{ep['id']}.txt").write_text('\n'.join(L) + '\n', encoding='utf-8')
            n += 1
    print(f'{n}편 → {TXT}')


def parse(text):
    m = re.search(r'```[a-z]*\n(.*?)```', text, re.S)
    body = m.group(1) if m else text
    head, turns = {}, []
    for line in body.splitlines():
        line = line.strip()
        if not line or line.startswith('==='):
            continue
        if re.match(r'^[A-D]\s*\|', line):
            c = [x.strip() for x in re.split(r'\s\|\s', line)]  # {o|a} 의 | 는 공백이 없어 칸 구분이 아님
            if len(c) < 5:
                raise ValueError('칸 부족: ' + line)
            kv = {}
            for x in c[4:]:
                if '=' in x:
                    k, v = x.split('=', 1)
                    kv[k.strip()] = v.strip()
            turns.append({'speaker': c[0], 'tl': c[1], 'ko': c[2], 'note': c[3], 'emo': kv.get('emotion', ''), 'tags': kv.get('tags', ''), 'say': kv.get('say', '')})
        elif ':' in line:
            k, v = line.split(':', 1)
            head[k.strip()] = v.strip()
    return head, turns


def apply(ep, head, turns):
    old = ep['turns']
    if [t['speaker'] for t in turns] != [t['speaker'] for t in old]:
        return f"줄 수·화자 순서 다름({len(turns)}줄 / 원본 {len(old)}줄)"
    for k in ('title', 'scene', 'emoji'):
        if head.get(k):
            ep[k] = head[k]
    for o, t in zip(old, turns):
        emos = [e.strip() for e in t['emo'].split('+') if e.strip()]
        bad = [e for e in emos if e not in EMO]
        if not emos or bad:
            return f"감정 값 이상 「{t['emo']}」"
        parts = [x.strip() for x in t['tl'].split('//')]
        says = [x.strip() for x in t['say'].split('//')] if t['say'] else []
        if len(parts) != len(emos) or (says and len(says) != len(parts)):
            return f"감정 {len(emos)}개 ↔ // 조각 {len(parts)}개(say {len(says)}) 「{t['tl']}」"
        o['tl'], o['ko'], o['note'] = ' '.join(parts), re.sub(r'\s*//\s*', ' ', t['ko']), re.sub(r'\s*//\s*', ' ', t['note'])
        o['tags'] = [x.strip() for x in t['tags'].split(',') if x.strip()]
        o.pop('segs', None)
        o.pop('emotion', None)
        if len(parts) == 1 and not says:
            o['emotion'] = emos[0]
        else:
            o['segs'] = [[e, (' ' if k else '') + x] + ([says[k]] if says and says[k] != x else []) for k, (e, x) in enumerate(zip(emos, parts))]
    tw = old[ep['twist'] - 1]
    if 'twist' not in tw['tags']:
        tw['tags'].append('twist')
    for i, o in enumerate(old, 1):
        if i != ep['twist'] and 'twist' in o['tags']:
            o['tags'].remove('twist')
    return None


def dump(eps):
    J = lambda v: json.dumps(v, ensure_ascii=False)  # noqa: E731
    out = []
    for ep in eps:
        head = [f'"{k}":{J(v)}' for k, v in ep.items() if k != 'turns']
        turns = ',\n'.join('   ' + J(t) for t in ep['turns'])
        out.append(' {' + ',\n  '.join(head) + ',\n  "turns":[\n' + turns + '\n  ]}')
    return '[\n' + ',\n'.join(out) + '\n]\n'


def do_import(ids):
    done = []
    for f in SRC:
        eps = json.load(open(f, encoding='utf-8'))
        changed = False
        for ep in eps:
            p = OUT / f"{ep['id']}.md"
            if (ids and ep['id'] not in ids) or not p.exists():
                continue
            try:
                head, turns = parse(p.read_text(encoding='utf-8'))
                err = apply(ep, head, turns)
            except Exception as e:  # noqa: BLE001
                err = str(e)
            if err:
                print(f"✗ {ep['id']}: {err}")
            else:
                changed = True
                done.append(ep['id'])
        if changed:
            Path(f).write_text(dump(eps), encoding='utf-8')
    print(f'넣음 {len(done)}편: {" ".join(done)}')


if __name__ == '__main__':
    if sys.argv[1:2] == ['export']:
        export()
    elif sys.argv[1:2] == ['import']:
        do_import(set(sys.argv[2:]))
    else:
        print(__doc__)
