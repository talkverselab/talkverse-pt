#!/usr/bin/env python3
"""회화 원본의 감정 → 음성 감정 계획 자동 생성(사용자 지시 2026-11-07, 감정을 손으로 다시 적지 않는다).
  python3 tools/tts/make_plan.py [data/dialogues_src/pt-PT/*.json]   없으면 그 폴더 전부 → data/tts/plan/<편id>.json
원본 턴: `emotion`(턴 전체 한 감정) 또는 `segs`([감정, 본문] 또는 [감정, 본문, 읽기] — 감정이 바뀌는 곳에서 나눔), 편: `cast`(화자 → 목소리).
감정은 voices.json 의 emotions 만 허용. 인용 부호·이모지는 소리 내지 않게 읽기 칸에서 뺀다. 그 뒤는 make_jobs.py 가 (목소리, 감정) 참고 음성으로 생성한다."""
import glob, json, os, re, sys
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
V = json.load(open(f'{R}/data/tts/voices.json', encoding='utf-8'))
MUTE = re.compile(r'[«»\U0001F300-\U0001FAFF]')


def seg(s):
    """[감정, 본문(, 읽기)] → 읽기가 본문과 다를 때만 세 칸."""
    read = MUTE.sub('', s[-1]).strip()
    return [s[0], s[1]] if read == s[1] else [s[0], s[1], read]


def main():
    srcs = sys.argv[1:] or sorted(glob.glob(f'{R}/data/dialogues_src/pt-PT/*.json'))
    errs, n = [], 0
    for src in srcs:
        for ep in json.load(open(src, encoding='utf-8')):
            P = {'ep': ep['id'], 'cast': ep.get('cast', {}), 'turns': {}}
            for k in ep['speakers']:
                if k != 'A' and P['cast'].get(k) not in V['voices']:
                    errs.append(f"{ep['id']}: cast {k}")
            for i, t in enumerate(ep['turns'], 1):
                segs = t.get('segs') or ([[t['emotion'], t['tl']]] if t.get('emotion') else None)
                if not segs:
                    errs.append(f"{ep['id']} {i}턴: 감정 없음"); continue
                for s in segs:
                    if s[0] not in V['emotions']:
                        errs.append(f"{ep['id']} {i}턴: 감정 {s[0]}")
                P['turns'][str(i)] = {'segs': [seg(s) for s in segs]}
            if len({s[0] for T in P['turns'].values() for s in T['segs']}) == 1:
                errs.append(f"{ep['id']}: 감정이 한 가지뿐")
            json.dump(P, open(f"{R}/data/tts/plan/{ep['id']}.json", 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
            n += 1
    print(f'계획 {n}편', *errs, sep='\n')
    sys.exit(1 if errs else 0)


if __name__ == '__main__':
    main()
