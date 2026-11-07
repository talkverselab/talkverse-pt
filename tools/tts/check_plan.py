#!/usr/bin/python3
"""감정 계획 검사(포르투갈어). python3 tools/tts/check_plan.py [편id...] — 조각을 이으면 그 턴 본문과 같은지, 목소리·감정이 있는지."""
import json, re, sys
import ttslib as L
norm = lambda s: re.sub(r'[\s….,!?«»👀😂]', '', s)
ids = sys.argv[1:] or L.planned()
bad = 0
for ep in ids:
    P = json.load(open(f'{L.R}/data/tts/plan/{ep}.json', encoding='utf-8'))
    errs = []
    for g in 'mf':
        D = json.load(open(L.ep_file(ep, g), encoding='utf-8'))
        for k in D['speakers']:
            if k != 'A' and P['cast'].get(k) not in L.V['voices']:
                errs.append(f'cast {k}')
        for t in D['turns']:
            segs = P['turns'][str(t['num'])]['segs']
            got = L.pick(''.join(s[1] for s in segs), g)
            if norm(got) != norm(t['tl']):
                errs.append(f"턴 {t['num']} {g}: {got} / {t['tl']}")
            for s in segs:
                if s[0] not in L.V['emotions']:
                    errs.append(f"턴 {t['num']} 감정 {s[0]}")
    if errs:
        bad += 1; print(ep, *errs[:8], sep='\n  ')
print('검사', len(ids), '문제', bad)
