#!/usr/bin/env python3
"""장면 컷 요청문(11-22, 일본어앱 수준 「장면 컷 10」) — 태국어앱 *_scene_prompt.md 와 같은 꼴, 편마다 남·여 학습자판.
  python3 tools/grok/scene_prompts.py → data/review/scene/<편>[_f]_prompt.md (컷 4장, 첨부 = data/review/art/chars_pt_v1.jpg)
고른 10편: 마주 보는 장면 + 시트에 있는 인물만(Fernanda·Marta 는 시트에 없어 뺐다)."""
import json
from pathlib import Path
R = Path(__file__).resolve().parents[2]
EPS = ['r0_culture_a1', 'r0_life_a2', 'r0_love_a3', 'r1_culture_a1', 'r1_friends_a1', 'r1_life_a3', 'r1_love_a1', 'r1_love_a4', 'r1_travel_a1', 'r5_love_b1']
SHEET = {'ines': '1번 Inês(짙은 갈색 긴 웨이브 반묶음·눈웃음)', 'beatriz': '2번 Beatriz(햇볕에 밝아진 갈색 곱슬 하이포니·큰 웃음)',
         'tiago': '3번 Tiago(검은 짧은 곱슬머리·수염·느긋한 인상)', 'duarte': '4번 Duarte(밝은 갈색 사이드파트·또렷한 눈매·가장 큰 키)'}
LEARNER = {'male': '시트 5번 학습자(남) — 아줄레주 블루 후드티, 국적이 드러나지 않는 중립적 생김새',
           'female': '시트 6번 학습자(여) — 검은 단발 보브, 남색 자켓 안 아줄레주 블루 티, 국적이 드러나지 않는 중립적 생김새'}


def main():
    out = R / 'data/review/scene'; out.mkdir(parents=True, exist_ok=True)
    for g in ('male', 'female'):
        d = json.load(open(R / f'assets/data/pt-PT/dialogues/{g}.json', encoding='utf-8'))
        E = {e['id']: e for e in (d if isinstance(d, list) else d['episodes'])}
        for ep in EPS:
            e = E[ep]; T = e['turns']; n = len(T)
            cuts = [T[round(i * n / 4):round((i + 1) * n / 4)] for i in range(4)]
            who = ', '.join(f'{k} = {SHEET[v]}' for k, v in e['cast'].items())
            L = [f"[{ep}{'-F' if g == 'female' else ''}] 포르투갈어(리스본) 학습 앱 회화 「{e['title']}」의 장면 컷 4장을 그려 주세요.",
                 f"장면: {e['scene'].replace('{name}', '학습자')}",
                 f"A = {LEARNER[g]}, {who}.",
                 '첨부한 캐릭터 시트(6인)의 인물만 등장합니다(점토·펠트 인형 톤, 둥근 얼굴, 따뜻한 조명, 파스텔 배경). 얼굴·머리·옷은 시트와 똑같이(다른 장면에서도 같은 인물로 보여야 함).',
                 '규칙: ① 그림 안에 글자·말풍선·자막을 절대 넣지 않습니다(말풍선은 앱이 얹습니다) ② 각 컷은 3:2 가로(1168×784), 인물이 크게 ③ 컷마다 그 순간의 표정·몸짓으로 대사의 감정을 보여 주세요 ④ 배경은 리스본(빵집·카페·전차·골목·바닷가 등 장면대로)이되 간판 글자는 없게 ⑤ 실존 인물·브랜드 금지 ⑥ 컷 4장을 한 번에 그려 주세요(cut1~cut4 순서, 같은 인물·같은 옷).',
                 '', '컷 구성(대사는 참고용 — 그림에 쓰지 마세요):']
            for i, c in enumerate(cuts, 1):
                L.append(f"cut{i} (턴 {c[0]['num']}~{c[-1]['num']}): " + ' / '.join(f"{t['speaker']}: {t['ko'].replace('{name}', '학습자')}" for t in c))
            (out / f"{ep}{'_f' if g == 'female' else ''}_prompt.md").write_text('\n'.join(L) + '\n', encoding='utf-8')
    print('요청문', 2 * len(EPS))


if __name__ == '__main__':
    main()
