"""포르투갈어 절벽(레마) — 판별(PT=포르투갈 제작, BR=브라질 제작) 자국 작품 자막.
방법(스페인어·독일어앱과 같은 원칙):
- 작품(tconst)마다 가장 큰 자막 파일 1개(같은 작품 중복 집계 방지).
- 접어 결합을 떼어 원형으로: dá-me → dá me, fazê-lo → fazer o, dar-te-ei → darei te.
- spaCy pt_core_news_sm 으로 레마+품사. 문장부호·숫자·기호 제외.
- 가짜 원형 제외: 레마가 사전(빈도 사전 zipf ≥ 1.5)에 없으면 표면형이 있으면 표면형, 둘 다 없으면 분자·분모 모두에서 뺀다.
- 단위 = 레마(품사 합침). 참고로 레마+품사 경계도 낸다.
사용: python pt_cliff.py <코퍼스 폴더> <출력 폴더>
"""
import os, re, sys, glob, csv, time, collections, html
import spacy
from wordfreq import zipf_frequency

SRC, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
nlp = spacy.load('pt_core_news_sm', disable=['parser', 'ner'])
nlp.max_length = 3_000_000

CL = r"(?:me|te|se|lhe|lhes|nos|vos|o|a|os|as|lo|la|los|las|no|na|nas)"
FUT = r"(?:ei|ás|á|emos|eis|ão|ia|ias|íamos|íeis|iam)"
ACC = str.maketrans('áâêéíóô', 'aaeeioo')

def split_clitics(s):
    # 메소클리시스: dar-te-ei → darei te
    s = re.sub(rf"\b(\w+)-({CL})-({FUT})\b", lambda m: f"{m.group(1)}{m.group(3)} {m.group(2)}", s, flags=re.I)
    # -lo/-la 형: fazê-lo → fazer o (악센트 모음 + r 복원)
    def lo(m):
        v, c = m.group(1), m.group(2)
        last = v[-1].translate(ACC)
        return f"{v[:-1]}{last}r {c[1:]}"
    s = re.sub(r"\b(\w*[áâêéíóô])-(l[oa]s?)\b", lo, s, flags=re.I)
    # 일반 접어: dá-me → dá me
    s = re.sub(rf"\b(\w+)-({CL})\b", r"\1 \2", s, flags=re.I)
    return s

def text_of(path):
    raw = open(path, encoding='utf-8', errors='ignore').read()
    raw = re.sub(r"<[^>]+>", "\n", raw)
    lines = [html.unescape(l).strip() for l in raw.split("\n")]
    return "\n".join(l for l in lines if l and not l.startswith('-->'))

# 전치사+관사·지시사 축약형(전치사로 태그된 것만) → 두 원형
CONTR = {}
for prep, forms in {'de': {'do':'o','da':'o','dos':'o','das':'o','dum':'um','duma':'um','duns':'um','dumas':'um','deste':'este','desta':'este','destes':'este','destas':'este','desse':'esse','dessa':'esse','desses':'esse','dessas':'esse','daquele':'aquele','daquela':'aquele','daqueles':'aquele','daquelas':'aquele','disto':'isto','disso':'isso','daquilo':'aquilo','dele':'ele','dela':'ele','deles':'ele','delas':'ele','daqui':'aqui','dali':'ali','daí':'aí'},
                    'em': {'no':'o','na':'o','nos':'o','nas':'o','num':'um','numa':'um','nuns':'um','numas':'um','neste':'este','nesta':'este','nestes':'este','nestas':'este','nesse':'esse','nessa':'esse','nesses':'esse','nessas':'esse','naquele':'aquele','naquela':'aquele','naqueles':'aquele','naquelas':'aquele','nisto':'isto','nisso':'isso','naquilo':'aquilo','nele':'ele','nela':'ele','neles':'ele','nelas':'ele'},
                    'a': {'ao':'o','aos':'o','à':'o','às':'o','àquele':'aquele','àquela':'aquele','àquilo':'aquilo'},
                    'por': {'pelo':'o','pela':'o','pelos':'o','pelas':'o'}}.items():
    for k, v in forms.items():
        CONTR[k] = (prep, v)

valid_cache = {}
def valid(w):
    if w not in valid_cache:
        valid_cache[w] = re.fullmatch(r"[a-záàâãéêíóôõúüç]+(?:-[a-záàâãéêíóôõúüç]+)*", w) is not None and zipf_frequency(w, 'pt') >= 1.5
    return valid_cache[w]

def pick_files(root):
    out = []
    for work in glob.glob(os.path.join(root, '*', '*')):
        fs = glob.glob(os.path.join(work, '*.xml'))
        if fs:
            out.append(max(fs, key=os.path.getsize))
    return sorted(out)

def bounds(counter, total):
    rank = counter.most_common()
    res, cum, i, marks = {}, 0, 0, [(55, 'R1'), (60, 'R2'), (70, 'R3'), (80, 'R4')]
    for i, (w, c) in enumerate(rank, 1):
        cum += c
        for pct, lab in marks:
            if lab not in res and cum / total * 100 >= pct:
                res[lab] = (i, w)
        if i == 2500:
            res['cov2500'] = cum / total * 100
    if 'cov2500' not in res:
        res['cov2500'] = cum / total * 100
    return res, rank

report = []
for v in ('PT', 'BR'):
    t0 = time.time()
    files = pick_files(os.path.join(SRC, v))
    lem, lempos, sample = collections.Counter(), collections.Counter(), collections.defaultdict(collections.Counter)
    raw_tok = dropped = 0
    texts = (split_clitics(text_of(f)) for f in files)
    for doc in nlp.pipe(texts, batch_size=8):
        for t in doc:
            if t.pos_ in ('PUNCT', 'SYM', 'NUM', 'SPACE', 'X') or not any(ch.isalpha() for ch in t.text):
                continue
            raw_tok += 1
            surf = t.text.lower()
            if surf in CONTR and t.pos_ in ('ADP', 'DET'):
                for part, ppos in zip(CONTR[surf], ('ADP', 'DET' if CONTR[surf][1] in ('o', 'um', 'este', 'esse', 'aquele') else 'PRON')):
                    lem[part] += 1; lempos[(part, ppos)] += 1; sample[part][ppos] += 1
                raw_tok += 1
                continue
            l = surf if t.pos_ == 'PROPN' else t.lemma_.lower()
            if not valid(l):
                if valid(surf):
                    l = surf
                else:
                    dropped += 1
                    continue
            lem[l] += 1
            lempos[(l, t.pos_)] += 1
            sample[l][t.pos_] += 1
    N = sum(lem.values())
    b, rank = bounds(lem, N)
    bp, _ = bounds(collections.Counter({f"{k[0]}\t{k[1]}": c for k, c in lempos.items()}), N)
    with open(os.path.join(OUT, f'pt_{v}_top5000_lemma.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f); w.writerow(['rank', 'lemma', 'pos', 'count', 'pct', 'cum_pct', 'level'])
        cum = 0
        for i, (l, c) in enumerate(rank[:5000], 1):
            cum += c
            lv = next((lab for lab in ('R1', 'R2', 'R3', 'R4') if i <= b.get(lab, (10**9,))[0]), 'R5')
            w.writerow([i, l, sample[l].most_common(1)[0][0], c, f"{c/N*100:.4f}", f"{cum/N*100:.2f}", lv])
    line = (f"{v}: 작품 {len(files)}편 · 토큰 {raw_tok:,}(가짜 원형으로 뺀 {dropped:,} 제외 후 {N:,}) · 레마 {len(lem):,}종 · "
            f"R1 {b['R1'][0]}({b['R1'][1]}) · R2 {b['R2'][0]} · R3 {b['R3'][0]} · R4 {b.get('R4',('미도달',))[0]} · "
            f"상위 2,500 {b['cov2500']:.1f}% | 레마+품사: R1 {bp['R1'][0]} · R2 {bp['R2'][0]} · R3 {bp['R3'][0]} · R4 {bp.get('R4',('미도달',))[0]} · "
            f"{time.time()-t0:.0f}s")
    print(line, flush=True)
    report.append(line)
open(os.path.join(OUT, 'pt_cliff_summary.txt'), 'w', encoding='utf-8').write("\n".join(report) + "\n")
