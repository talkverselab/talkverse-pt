"""회화 음성 공통(포르투갈어): 감정 계획 + 판별 편 JSON → 턴별 남성판·여성판. 한국어앱 tools/tts/ttslib.py 와 같은 구조.
D1 audio_lines 열: text = 포르투갈어 본문, reading = 빈 값, rd = 한글 독음, ko = 한국어 뜻.
계획의 조각 글에는 성별 표시 `{남|여}` 를 그대로 쓴다(data/dialogues_src 와 같음). 소리 낼 글이 없는 턴만 뺀다."""
import glob, json, os, re, sys
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, f'{R}/tools')
from rd_pt import rd as rd_pt  # noqa: E402
V = json.load(open(f'{R}/data/tts/voices.json', encoding='utf-8'))
EP = {os.path.basename(p)[:-5]: p for p in glob.glob(f'{R}/assets/data/pt-PT/dialogues/male/*/*/*.json')}
PICK = re.compile(r'\{([^{}|]*)\|([^{}|]*)\}')
SIL = re.compile(r'[\s….,!?«»]')


def pick(s, g):
    return PICK.sub(lambda m: m.group(1 if g == 'm' else 2), s)


def fill(s, g, key='text'):
    for k, x in V['fill'].items():
        s = s.replace(k, (x.get(g) or x)[key])
    return s


def ep_file(ep, g):
    return EP[ep] if g == 'm' else EP[ep].replace('/male/', '/female/')


def turns(ep):
    P = json.load(open(f'{R}/data/tts/plan/{ep}.json', encoding='utf-8'))
    D = {g: json.load(open(ep_file(ep, g), encoding='utf-8')) for g in 'mf'}
    out = []
    for i, t in enumerate(D['m']['turns']):
        T = P['turns'][str(t['num'])]; row = {'num': t['num'], 'speaker': t['speaker']}
        for g in 'mf':
            x = D[g]['turns'][i]
            segs = [(s[0], fill(pick(s[-1], g), g).strip()) for s in T['segs']]
            segs = [s for s in segs if SIL.sub('', s[1])]
            row[g] = {'voice': ('am' if g == 'm' else 'af') if t['speaker'] == 'A' else P['cast'][t['speaker']],
                      'text': fill(x['tl'], g), 'reading': '', 'rd': fill(x['rd'], g, 'rd'), 'ko': fill(x['ko'], g, 'ko'), 'segs': segs}
        if not row['m']['segs'] or not row['f']['segs']:
            continue
        row['same'] = row['m']['voice'] == row['f']['voice'] and row['m']['segs'] == row['f']['segs']
        out.append(row)
    return out


def seg_files(ep):
    """생성할 조각 [(파일이름, 목소리, 감정, 읽기)] — 두 판이 같으면 c 하나, 다르면 m·f."""
    out = []
    for r in turns(ep):
        for tag in (['c'] if r['same'] else ['m', 'f']):
            x = r['m' if tag == 'c' else tag]
            for i, (emo, text) in enumerate(x['segs']):
                out.append((f"{r['num']:02d}_{i}_{tag}.wav", x['voice'], emo, text))
    return out


def planned():
    return sorted(os.path.basename(p)[:-5] for p in glob.glob(f'{R}/data/tts/plan/*.json') if os.path.basename(p)[:-5] in EP)
