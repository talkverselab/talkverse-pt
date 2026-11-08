#!/usr/bin/env python3
"""굴절 노출 점검 — 편마다 같은 동사·형용사가 몇 가지 형태(인칭·시제·성수)로 나오는지(사용자 지시 2026-11-08, 굴절에 익숙해지게).
  ~/.venvs/pt_nlp/bin/python tools/check_inflection.py   (spaCy pt_core_news_sm + 손 표, 남·여 판 합산)
출력: 레벨 · 편 · 턴 수 · 여러 형태로 나온 동사 수 · 여러 형태로 나온 형용사 수 | 예."""
import glob, json, re, collections, spacy
nlp=spacy.load('pt_core_news_sm')
IRR={}  # 손 표: 자주 틀리는 tu·불규칙 형태
for lem,forms in {'ser':'sou és é somos são era eras éramos eram fui foste foi fomos foram seja sejas','estar':'estou estás está estamos estão estava estavas estávamos estavam estive estiveste esteve tás tá esteja','ter':'tenho tens tem temos têm tinha tinhas tive tiveste teve tenha','ir':'vou vais vai vamos vão ia ias fui foste foi fomos foram vá','fazer':'faço fazes faz fazemos fazem fiz fizeste fez faça','poder':'posso podes pode podemos podem podia pude pôde possa','querer':'quero queres quer queremos querem queria quis quiseste','dizer':'digo dizes diz dizemos dizem disse disseste dissemos diga','vir':'venho vens vem vimos vêm vim vieste veio venha','ver':'vejo vês vê vemos veem vi viste viu veja','dar':'dou dás dá damos dão dei deste deu dê','saber':'sei sabes sabe sabemos sabem sabia soube soubeste saiba','gostar':'gosto gostas gosta gostamos gostam gostei gostaste gostou','ficar':'fico ficas fica ficamos ficam fiquei ficaste ficou','falar':'falo falas fala falamos falam falei falaste falou','chegar':'chego chegas chega chegamos chegam cheguei chegaste chegou','comer':'como comes come comemos comem comi comeste comeu','precisar':'preciso precisas precisa precisamos precisam','achar':'acho achas acha achamos acham achei achaste achou','levar':'levo levas leva levamos levam levei levaste levou'}.items():
    for f in forms.split(): IRR.setdefault(f,lem)
def key(t):
    w=t.text.lower()
    if w in IRR: return IRR[w]
    if t.pos_ in ('VERB','AUX'): return t.lemma_.lower()
    if t.pos_=='ADJ' or (t.pos_=='NOUN' and w.endswith(('ado','ada','ados','adas','ido','ida','idos','idas'))):
        b=re.sub(r'(o|a|os|as)$','',w); return 'ADJ:'+b
    return None
rows=[]
for f in sorted(glob.glob('assets/data/pt-PT/dialogues/male/R*/*/*.json'),key=lambda f:(f.split('/')[-3],f)):
    d=json.load(open(f)); fem=json.load(open(f.replace('/male/','/female/')))
    forms=collections.defaultdict(set)
    for dd in (d,fem):
        for t in dd['turns']:
            for tok in nlp(re.sub(r'\{[a-z_]+\}','Alex',t['tl'])):
                k=key(tok)
                if k: forms[k].add(tok.text.lower())
    multi={k:sorted(v) for k,v in forms.items() if len(v)>=2}
    pers=sum(1 for k in multi if not k.startswith('ADJ:'))
    gen=sum(1 for k in multi if k.startswith('ADJ:'))
    rows.append((d['region'],d['id'],len(d['turns']),pers,gen,'; '.join(f"{k}:{'/'.join(v)}" for k,v in list(multi.items())[:6])))
for r in rows: print(*r[:5],'|',r[5][:150])
