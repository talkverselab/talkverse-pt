#!/usr/bin/env python3
"""언어감각 익히기 10급 초안(11-22, uk 전달 「막힌 것 각자 판단대로 완료」) — Claude 는 장면·흐름·넣을 말만, 대사는 Grok(「빠른」).
  python3 tools/grok/sense_specs_1122.py skel    → data/review/grok/sense/<L>.txt (뼈대)
  python3 tools/grok/sense_specs_1122.py apply   → data/review/grok/out/sense_<L>.md 를 읽어 assets/data/grammar/sense_course.json
줄 형식(Grok 답): `누구 | 포르투갈어 | 한국어` — 핵심 낱말은 양쪽에 `{낱말|번호}` 로 같은 번호(1·2). 독음은 tools/rd_pt.py 가 만든다."""
import json, re, sys
from pathlib import Path
R = Path(__file__).resolve().parents[2]

# (id, 제목, 안내 한 줄, 장면, 상대, [(누구, 흐름, 넣을 말)] × 10)
S = [
 ('L1', '성과 수 맞추기 (o/a · -s)', '일부러 규칙을 설명하지 않았어요. 대화를 통째로 외우면 o·a·s 가 저절로 맞춰져요.',
  '빵집. 학습자가 점원에게 빵과 케이크를 하나씩, 여러 개씩 주문한다.', '점원',
  [('점원','손님을 맞으며 무엇을 원하는지 묻는다','bom dia'),('나','빵 하나를 달라고 한다','um pão'),('점원','빵을 몇 개 원하는지 되묻는다','quantos pães'),('나','빵 두 개로 바꾼다','dois pães'),('점원','케이크도 있다고 권한다','uma tarte, nova'),('나','케이크가 예쁘다며 두 조각을 달라고 한다','duas tartes, bonitas'),('점원','빵은 따뜻하고 케이크는 차갑다고 알려 준다','quentes, fria'),('나','따뜻한 빵이 좋다고 한다','pão quente'),('점원','전부 해서 얼마인지 말한다','tudo'),('나','고맙다며 인사한다','obrigado / obrigada 피하기 — até logo')]),
 ('L2', 'ser 와 estar', '「~이다」가 둘이에요. 늘 그런 것과 지금 그런 것 — 대화로 감을 잡아요.',
  '카페. 친구 Inês 가 오늘 피곤해 보이는 학습자에게 말을 건다.', 'Inês',
  [('Inês','학습자가 오늘 피곤해 보인다고 한다','estás cansado → 학습자 성별 낱말 피하기: pareces'),('나','원래는 아침형 인간인데 오늘만 그렇다고 한다','sou, estou'),('Inês','자기는 늘 저녁형이라고 한다','sou'),('나','커피가 차갑다고 불평한다','está fria'),('Inês','이 카페 커피는 원래 맛있다고 한다','é bom'),('나','카페가 어디 있는지, 집에서 가까운지 묻는다','é perto'),('Inês','지금은 사람이 많아서 시끄럽다고 한다','está cheio'),('나','Inês 가 오늘 기분이 좋아 보인다고 한다','estás contente'),('Inês','시험이 끝나서 그렇다고 한다','está acabado'),('나','다음엔 조용한 곳에 가자고 한다','é calmo')]),
 ('L3', 'tu 와 o senhor', '같은 말을 친구에게, 처음 보는 어른에게 — 동사 끝이 바뀌는 걸 들어 보세요.',
  '전차 정류장. 학습자가 친구 Tiago 에게, 이어서 옆의 할머니(Dona Fernanda)에게 같은 걸 묻는다.', 'Tiago / Fernanda',
  [('나','Tiago 에게 28번 전차를 아는지 묻는다','sabes'),('Tiago','모른다며 할머니께 여쭤보라고 한다','pergunta'),('나','할머니께 공손하게 같은 걸 여쭌다','a senhora sabe'),('Fernanda','안다며 곧 온다고 한다','sei, vem já'),('나','할머니께 어디 가시는지 여쭌다','vai'),('Fernanda','시장에 간다며 학습자는 어디 가는지 되묻는다','e o senhor? → 학습자 성별: {o senhor|a senhora}'),('나','친구와 성에 간다고 한다','vamos'),('Tiago','학습자에게 표를 가졌는지 묻는다','tens'),('나','할머니께 표를 어디서 사는지 여쭌다','compra'),('Fernanda','전차 안에서 산다며 웃는다','compra-se')]),
 ('L4', 'estar a + 원형 (지금 하는 중)', '「지금 ~하고 있어」는 estar a + 원형. 전화 대화로 익혀요.',
  '전화. 친구 Duarte 가 저녁 약속에 늦는 학습자에게 전화한다.', 'Duarte',
  [('Duarte','지금 뭐 하고 있냐고 묻는다','estás a fazer'),('나','지금 버스를 기다리고 있다고 한다','estou à espera'),('Duarte','자기는 벌써 식당에서 먹고 있다고 한다','estou a comer'),('나','버스가 지금 오고 있다고 한다','está a chegar'),('Duarte','다른 친구들도 기다리고 있다고 한다','estão a esperar'),('나','지금 뛰고 있다고 한다','estou a correr'),('Duarte','비가 오고 있냐고 묻는다','está a chover'),('나','조금 오고 있다고 한다','está a chover um bocado'),('Duarte','웨이터가 자꾸 쳐다보고 있다고 농담한다','está a olhar'),('나','지금 들어가고 있다며 끊는다','estou a entrar')]),
 ('L5', '완료과거 — 했다', '어제 한 일 이야기. -ei · -aste · -ou 소리가 반복돼요.',
  '월요일 아침 사무실 앞. 동료 Beatriz 와 주말에 한 일을 이야기한다.', 'Beatriz',
  [('Beatriz','주말에 뭐 했냐고 묻는다','fizeste'),('나','신트라에 갔다고 한다','fui'),('Beatriz','누구랑 갔냐고 묻는다','foste'),('나','친구랑 기차로 갔다고 한다','fomos'),('Beatriz','뭘 먹었냐고 묻는다','comeste'),('나','유명한 과자를 먹었다고 한다','comi travesseiros'),('Beatriz','자기는 집에서 잠만 잤다고 한다','dormi'),('나','몇 시간 잤냐고 묻는다','dormiste'),('Beatriz','열두 시간 잤다며 웃는다','doze horas'),('나','그래서 오늘 기분이 좋아 보인다고 한다','dormiste bem')]),
 ('L6', '반과거 — 하곤 했다', '어릴 때 늘 하던 일은 반과거. -ava · -ia 가 들려요.',
  '할머니 Fernanda 의 집. 옛날 사진을 보며 어릴 적 이야기를 듣는다.', 'Fernanda',
  [('나','사진 속 아이가 누구냐고 여쭌다','é a senhora'),('Fernanda','어릴 때 자기라며 이 동네에 살았다고 한다','vivia'),('나','그때 뭘 하고 놀았는지 여쭌다','brincava'),('Fernanda','매일 길에서 공놀이를 했다고 한다','jogávamos'),('나','학교는 멀었는지 여쭌다','era longe'),('Fernanda','걸어서 다녔다고 한다','ia a pé'),('나','어릴 때 자기는 게임만 했다고 한다','jogava'),('Fernanda','그때는 텔레비전도 없었다고 한다','não havia'),('나','그럼 저녁엔 뭘 하셨는지 여쭌다','faziam'),('Fernanda','가족이 다 같이 노래를 불렀다고 한다','cantávamos')]),
 ('L7', '접어 붙이기 (diz-me · não me diz)', '「나에게·그것을」 같은 짧은 말이 동사 뒤에 붙었다가, 부정문에선 앞으로 와요.',
  '집. 룸메이트 Tiago 가 학습자의 열쇠를 찾고 있다.', 'Tiago',
  [('Tiago','열쇠를 봤는지 말해 달라고 한다','diz-me'),('나','못 봤다며 Tiago 가 어제 가져갔다고 한다','levaste-a'),('Tiago','자기는 안 가져갔다고 한다','não a levei'),('나','소파 밑을 보라고 한다','vê'),('Tiago','찾았다며 학습자에게 준다','encontrei-a, dou-ta → R1 수준: dou-te'),('나','고맙다며 내일 돌려주겠다고 한다','devolvo-a'),('Tiago','잃어버리지 말라고 한다','não a percas → 접속법 피하기: não a deixes'),('나','걱정 말라고, 가방에 넣는다고 한다','ponho-a'),('Tiago','내일 전화해 달라고 한다','liga-me'),('나','아침에 전화하겠다고 한다','ligo-te')]),
 ('L8', '묻고 맞장구치기', 'a sério? · pois · ai é? — 리스본 사람의 맞장구를 대화째 외워요.',
  '점심시간 공원 벤치. 친구 Inês 가 어제 있었던 일을 신나게 이야기한다.', 'Inês',
  [('Inês','어제 대박인 일이 있었다고 운을 뗀다','sabes o que'),('나','뭔데, 하고 묻는다','o quê?'),('Inês','길에서 유명 축구 선수를 봤다고 한다','vi'),('나','진짜냐고 놀란다','a sério?'),('Inês','사진도 찍었다고 한다','tirei'),('나','오, 그래? 하고 맞장구친다','ai é?'),('Inês','근데 사진이 흔들렸다고 한다','ficou tremida'),('나','그렇지 뭐, 하고 웃는다','pois'),('Inês','그래도 사인은 받았다고 한다','autógrafo'),('나','어디 보자고 한다','mostra lá')]),
 ('L9', '접속법 맛보기 (quando quiseres · se calhar)', '굳은 표현부터 — 규칙 없이 덩어리째 쓰면 돼요.',
  '서점. 학습자가 친구 Marta 와 책 선물을 고른다.', 'Marta',
  [('나','어떤 책이 좋을지 묻는다','qual'),('Marta','아마 소설이 좋을 거라고 한다','se calhar'),('나','동생이 좋아할지 모르겠다고 한다','talvez goste'),('Marta','원하면 자기가 골라 주겠다고 한다','se quiseres'),('나','좋다고, 아무 거나 괜찮다고 한다','qualquer'),('Marta','다 고르면 커피 마시러 가자고 한다','quando acabarmos'),('나','동생이 읽기 전에 포장하고 싶다고 한다','antes que'),('Marta','점원에게 포장해 달라고 하자고 한다','peça'),('나','원할 때 언제든 커피 사겠다고 한다','quando quiseres'),('Marta','그럼 지금 가자며 웃는다','vamos já')]),
 ('L10', '미래·조건 (vou fazer · faria)', '「할 거야」는 vou + 원형, 「~할 텐데」는 -ria. 꿈 이야기로 익혀요.',
  '해 질 녘 강가. 친구 Duarte 와 복권에 당첨되면 뭘 할지 이야기한다.', 'Duarte',
  [('Duarte','복권을 샀다며 내일 발표라고 한다','vou ver'),('나','당첨되면 뭘 할 거냐고 묻는다','farias'),('Duarte','배를 사겠다고 한다','compraria'),('나','자기는 세계 여행을 하겠다고 한다','viajaria'),('Duarte','내일은 일단 출근할 거라고 한다','vou trabalhar'),('나','당첨되면 회사를 그만두겠냐고 묻는다','deixarias'),('Duarte','바로 그만두겠다고 한다','deixaria'),('나','그럼 자기도 배에 태워 달라고 한다','levavas-me → levarias'),('Duarte','물론이라며 요리는 학습자 담당이라고 한다','cozinharias'),('나','그럼 내일 같이 결과를 보자고 한다','vamos ver')]),
]

RULES = """=== 규칙(언어감각 외울 대화)
- 리스본 20대가 실제로 쓰는 짧은 구어(pt-PT). 브라질 말 금지. 친구 = tu, 처음 보는 어른 = o senhor / a senhora.
- 한 줄 3~14단어, 한 줄 1~2문장. 이 급의 문법(제목)이 10줄 안에서 여러 인칭·형태로 되풀이되게.
- 학습자(나) 자신을 가리키는 성 변화 낱말(cansado/a, obrigado/a 등)은 쓰지 않는다. 꼭 필요하면 {남|여}.
- 각 줄 핵심 낱말 1~3개를 포르투갈어·한국어 양쪽에 {낱말|번호} 로 같은 번호(1 또는 2)로 표시.
- 실존 작품·브랜드·인물 금지, 12세 이상. 흐름은 방향만 — 더 자연스럽고 재미있으면 바꿔도 된다. 「넣을 말」의 → 뒤는 작성 메모(따르기만, 대사에 쓰지 말 것).
- 답 형식: 머리 줄 그대로 + 10줄 `누구 | 포르투갈어 | 한국어` 만, 코드 블록 하나."""


def skel():
    d = R / 'data/review/grok/sense'; d.mkdir(parents=True, exist_ok=True)
    for i, t, note, scene, cast, L in S:
        assert len(L) == 10, i
        lines = [f'=== sense_{i}', f'title: {t}', f'scene: {scene}', f'cast: 나(학습자), {cast}', '']
        lines += [f'{w} | ___ | ___ | 흐름: {f} · 넣을 말: {k}' for w, f, k in L]
        (d / f'{i}.txt').write_text('\n'.join(lines) + '\n\n' + RULES + '\n', encoding='utf-8')
    print('뼈대', len(S))


MARK = re.compile(r'\{([^|}]+)\|(\d+)\}')


def apply():
    sys.path.insert(0, str(R / 'tools'))
    from rd_pt import rd as reading  # noqa
    levels, bad = [], []
    for i, t, note, scene, cast, L in S:
        f = R / f'data/review/grok/out/sense_{i}.md'
        if not f.exists():
            bad.append(f'{i} 답 없음'); continue
        rows = [[c.strip() for c in ln.split(' | ')] for ln in f.read_text(encoding='utf-8').splitlines() if ' | ' in ln and not ln.startswith(('title', 'scene', 'cast'))]
        rows = [r for r in rows if len(r) >= 3 and r[1] and r[1] != '___']
        if len(rows) != 10:
            bad.append(f'{i} 줄 수 {len(rows)}'); continue
        if [r[0] for r in rows] != [w for w, _, _ in L]:
            bad.append(f'{i} 화자 순서 다름'); continue
        sents = []
        for w, tl, ko in (r[:3] for r in rows):
            if sorted(MARK.findall(tl), key=lambda m: m[1]) and {n for _, n in MARK.findall(tl)} != {n for _, n in MARK.findall(ko)}:
                bad.append(f'{i} 표시 번호 어긋남: {tl}')
            sents.append({'who': w, 'tl': tl, 'rd': reading(MARK.sub(lambda m: m.group(1), tl)), 'ko': ko})
        levels.append({'id': i, 'title': t, 'lessons': [{'id': f'{i}-talk', 'title': t, 'kind': 'memorize', 'video': '', 'note': note, 'sentences': sents}]})
    print('\n'.join('✗ ' + b for b in bad) or '문제 없음')
    if len(levels) == len(S) and not bad:
        out = R / 'assets/data/grammar/sense_course.json'
        old = json.loads(out.read_text(encoding='utf-8')) if out.exists() else {}
        old.update(title='언어감각 익히기', subtitle='정규과정 · 영상 → 대화 통째로 외우기', levels=levels)
        out.write_text(json.dumps(old, ensure_ascii=False, indent=1), encoding='utf-8'); print('넣음', out)


if __name__ == '__main__':
    {'skel': skel, 'apply': apply}[sys.argv[1]]()
