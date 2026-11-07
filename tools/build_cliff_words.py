"""절벽 단어 화면 데이터 — 2026-11-07(일본어앱 tools/freq/conv_words.py 의 포르투갈어판).
  python3 tools/build_cliff_words.py
  → assets/data/freq/cliff_pt_PT.csv   유럽판 절벽 순위 1~2,000(rank,word,cum_pct,region,ko)
  → assets/data/freq/conv_words_pt.json 회화 레마 중 2,000위 밖이면서 단어표에 있는 것({words:[{word,ko,n}]}, 등장 횟수순)
순위·구간은 data/cliff/pt_PT_top5000_lemma.csv(판별 재산정). lang_pt_top.csv 의 rank 는 PT·BR 을 합친 그림 목록 순서라 절벽 순위로 쓰지 않는다.
뜻은 lang_pt_top.csv 에 있는 것만 붙인다(새로 쓰지 않음, 없으면 빈칸)."""
import collections
import csv
import glob
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CAP = 2000
FREQ = ROOT / 'assets/data/freq'

ko = {r['word']: r['ko'].strip() for r in csv.DictReader(open(FREQ / 'lang_pt_top.csv', encoding='utf-8-sig'))}
rows = list(csv.DictReader(open(ROOT / 'data/cliff/pt_PT_top5000_lemma.csv', encoding='utf-8-sig')))
top = rows[:CAP]
with open(FREQ / 'cliff_pt_PT.csv', 'w', encoding='utf-8', newline='') as f:
    w = csv.writer(f, lineterminator='\n')
    w.writerow(['rank', 'word', 'cum_pct', 'region', 'ko'])
    for r in top:
        w.writerow([r['rank'], r['lemma'], r['cum_pct'], r['level'], ko.get(r['lemma'], '')])

inside = {r['lemma'] for r in top}
n = collections.Counter()
for p in glob.glob(str(ROOT / 'assets/data/dialogues/*.json')):
    for ep in json.load(open(p, encoding='utf-8')).get('episodes', []):
        for t in ep.get('turns', []):
            for l in t.get('lemmas', []):
                if l[1] not in inside and ko.get(l[1]):
                    n[l[1]] += 1
words = [{'word': b, 'ko': ko[b], 'n': c} for b, c in n.most_common()]
json.dump({'_meta': '회화 레마 중 절벽 단어표(2,000위) 밖이면서 단어표에 있는 것 · tools/build_cliff_words.py', 'words': words},
          open(FREQ / 'conv_words_pt.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
print(len(top), 'with ko', sum(1 for r in top if ko.get(r['lemma'])), 'conv', len(words))
