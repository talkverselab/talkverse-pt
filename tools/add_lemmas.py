#!/usr/bin/env python3
"""편 JSON 의 턴마다 `lemmas`(내용어 [표면형, 기본형, 읽기]) 를 채운다 — 문장 레마 ↔ 단어장 연결(사용자 지시 2026-11-04).
포르투갈어판: spaCy pt_core_news_sm 으로 명사·동사·형용사·부사만(기능어·고유명사·기호 제외), 접어 결합(dá-me·fazê-lo)은
tools/pt_cliff.py 와 같은 규칙으로 떼어 원형을 잡는다. 읽기(한글 독음)는 단어 단위 독음 데이터가 없어 비워 둔다.
단어장(assets/data/vocab/travel_words.json + DB 빈도 단어)에 없는 레마는 절벽 순위(data/cliff/pt_PT_top5000_lemma.csv)로 정렬해
data/review/write/missing_lemmas.csv 로 낸다(uk 세션에 넘겨 단어·그림 제작).
  <spaCy venv>/bin/python tools/add_lemmas.py"""
import csv, glob, json, re, sys
from collections import Counter
from pathlib import Path
import spacy

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'tools'))
nlp = spacy.load('pt_core_news_sm', disable=['parser', 'ner'])
KEEP = {'NOUN', 'VERB', 'ADJ', 'ADV'}
SKIP = {'não', 'sim', 'muito', 'mais', 'já', 'também', 'bem', 'aqui', 'ali', 'hoje', 'então', 'só',
        'me', 'te', 'se', 'lhe', 'lhes', 'nos', 'vos', 'lo', 'la', 'los', 'las'}  # 기능어에 가까운 부사 + 떼어 낸 접어(대명사)
VAR = re.compile(r'\{[a-z_]+\}')
# 작은 모델의 원형 오류 고침표(표면형 소문자 → 기본형). 새 편을 넣을 때 출력(표면형·기본형)을 훑어 보태 둔다.
LEMMA_FIX = {'boa': 'bom', 'comemos': 'comer', 'dias': 'dia', 'escreve': 'escrever', 'escrevo': 'escrever', 'levamos': 'levar', 'levo': 'levar',
             'mostro': 'mostrar', 'podíamos': 'poder', 'vens': 'vir', 'venho': 'vir', 'vemo': 'ver', 'és': 'ser', 'estás': 'estar',
             'pratico': 'praticar', 'moras': 'morar', 'gosto': 'gostar', 'foi': 'ser', 'combinado': 'combinar'}
# 모델이 기능어·고유명사로 잘못 보는 동사 — 표면형이 이 표에 있으면 품사와 상관없이 내용어로 센다
FORCE = {'venho', 'vemo', 'escrevo', 'pratico', 'moras', 'estás', 'és', 'foi', 'gosto'}
CL = r"(?:me|te|se|lhe|lhes|nos|vos|o|a|os|as|lo|la|los|las|no|na|nas)"
ACC = str.maketrans('áâêéíóô', 'aaeeioo')

def split_clitics(s):
    s = re.sub(rf"\b(\w+)-({CL})-(ei|ás|á|emos|eis|ão|ia|ias|íamos|íeis|iam)\b", lambda m: f"{m.group(1)}{m.group(3)} {m.group(2)}", s, flags=re.I)
    s = re.sub(r"\b(\w*[áâêéíóô])-(l[oa]s?)\b", lambda m: f"{m.group(1)[:-1]}{m.group(1)[-1].translate(ACC)}r {m.group(2)[1:]}", s, flags=re.I)
    return re.sub(rf"\b(\w+)-({CL})\b", r"\1 \2", s, flags=re.I)

vocab = set()
try:
    vj = json.load(open(ROOT / 'assets/data/vocab/travel_words.json', encoding='utf-8'))
    for th in vj.get('themes', []):
        for sec in th.get('sections', []):
            for w in sec.get('words', []):
                vocab.add(str(w.get('tx', '')).strip().lower())
except FileNotFoundError:
    pass
rank = {}
try:
    for r in csv.DictReader(open(ROOT / 'data/cliff/pt_PT_top5000_lemma.csv', encoding='utf-8')):
        rank.setdefault(r['lemma'], int(r['rank']))
except FileNotFoundError:
    pass

miss, ex, tot, hit = Counter(), {}, 0, 0
for f in sorted(glob.glob(str(ROOT / 'assets/data/dialogues/*.json'))):
    if Path(f).name.startswith('_'):
        continue
    d = json.load(open(f, encoding='utf-8'))
    ch = False
    for ep in d.get('episodes', []):
        for t in ep.get('turns', []):
            text = VAR.sub(' ', t.get('es') or t.get('tl') or '')
            out = []
            for tok in nlp(split_clitics(text)):
                low = tok.text.lower()
                if not tok.text.isalpha() or (tok.pos_ not in KEEP and low not in FORCE):
                    continue
                base = LEMMA_FIX.get(low) or (tok.lemma_.lower() if tok.lemma_ else low)
                if base in SKIP or len(base) < 2:
                    continue
                out.append([tok.text, base, ''])
                tot += 1
                if base in vocab or tok.text.lower() in vocab:
                    hit += 1
                else:
                    miss[base] += 1
                    ex.setdefault(base, text.strip())
            if t.get('lemmas') != out:
                t['lemmas'] = out
                ch = True
    if ch:
        open(f, 'w', encoding='utf-8').write(json.dumps(d, ensure_ascii=False, indent=2) + '\n')
with open(ROOT / 'data/review/write/missing_lemmas.csv', 'w', encoding='utf-8', newline='') as fo:
    w = csv.writer(fo)
    w.writerow(['lemma', 'cliff_rank', 'count', 'example'])
    for b, n in sorted(miss.items(), key=lambda kv: (rank.get(kv[0], 10**6), -kv[1])):
        w.writerow([b, rank.get(b, ''), n, ex[b]])
print(f'내용어 {tot} · 단어장 있음 {hit / max(tot, 1):.0%} · 없는 레마 {len(miss)} → data/review/write/missing_lemmas.csv')
