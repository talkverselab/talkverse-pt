# 포르투갈어(유럽판) 회화 Claude 초안 작성 지시 — 2026-11-08 (하위 에이전트용)

흐름: Claude 초안(지금) → Grok 이 초안을 참고해 문장을 완전히 다시 씀(11-10 이후) → DB. 지금은 초안만.
읽을 것: `~/talkverse/INFLECTED_LANG_STRATEGY.md` §A·§B, `docs/DIALOGUE_RULES_pt.md`, `CHARACTERS.md`, `CLAUDE.md` §10(말투·독음 표), 형식 예시 `data/dialogues_src/pt-PT/sample_r1_r4.json`(이미 쓴 4편 — 겹치지 않게).

## 레벨(폴더 R 숫자 = 문법 단계)과 어휘 상한(유럽판 절벽 순위 `data/cliff/pt_PT_top5000_lemma.csv`)
| 레벨 | 문법 | 말투 | 어휘 상한 | 턴 | 턴 길이 |
|---|---|---|---|---|---|
| R0 소리·짧은 회화 | 인사·짧은 덩어리, 문법 설명 없음 | 반말(친구·채팅·연인)만 | 83위 + 표현 풀 | 6~8 | 2~8 단어(2턴부터 1단어 허용) |
| R1 활용 골격 | 단수 eu·tu·ele/ela 현재, estar a, 완료과거 조금, 관사·성 일치 | 반말만 | 217위 | 6~8 | 3~10 |
| R2 챗 실전 | 채팅 말투, 단수, 완료과거·반과거 | 반말만 | 656위 | 8~12 | ≤14 |
| R3 그래머2 | 복수(nós·vocês·eles) + 존칭 o senhor/a senhora(3인칭 단수 동사) 해금, 새 단어 거의 없음 | 가게·관공서·낯선 사이 가능 | 656위 | 12~16 | ≤20 |
| R4 어려운 문법 | 접속법·인칭 부정사·미래·조건법을 "씨앗"으로 | 상황대로 | 656위 + 편당 3개 | 12~16 | ≤20 |
| R5 어휘 완주 | 새 문법 없음, 어휘 657~2,000위를 자연스럽게 | 상황대로 | 2,000위 | 12~16 | ≤20 |
상한 밖 낱말은 편당 1개(R4 3개)까지, 그 턴 note 에 뜻. 표현 풀·고유명사·{name} 은 세지 않는다.

## 문법 배치(사용자 결정 2026-11-08, `docs/GRAMMAR_LEVELS_pt.md`)
- 접어: 동사 뒤(diz-me)는 R1 부터, 동사 앞(não me·que te)은 R0~R1 에선 굳은 덩어리만 → R2 부터 규칙, 동사 사이 끼움(dir-te-ei)은 R5 에서만 드물게.
- 접속법·미래 접속법·인칭 부정사: 규칙으로는 R4 에서만. 굳은 표현(desculpe·se calhar·vá lá·quando quiseres·como quiseres)은 R0 부터 덩어리로 허용.
- 존칭 o senhor/a senhora: R3 부터. 어휘 상한은 위 표 그대로.

## 굴절에 익숙해지게(사용자 지시 2026-11-08 — 가장 중요)
- 한 편 안에서 **같은 동사·형용사가 여러 인칭·시제·성수로 되풀이**되게 쓴다. 예: A 「Estou cansad{o|a}.」 → B 「Tu estás? Eu também estou.」 → 「Ela está pior.」, 「Gostas? — Gosto! O Duarte também gosta.」, 「Fui ontem. — Foste? Ele foi também.」. 묻고 답하기·되묻기·제3자에게 옮기기가 자연스러운 장치다.
- 목표(편당, 남·여 판 합산 `~/.venvs/pt_nlp/bin/python tools/check_inflection.py`): R0 2개 이상 · R1 4개 이상(eu·tu·ele/ela 세 인칭이 다 나오는 동사 1개 이상, 성 일치 형용사 1개 이상) · R2 4 · R3 5(복수 형태 포함) · R4·R5 4.
- 어휘: 절벽구간(많이 쓰이는) 단어를 먼저 쓰되 절대 기준은 아니다. **재미와 자연스러움이 먼저**이고, 되풀이가 억지스러우면 줄인다.

## 쓰는 법(굴절어 전략 §B 요약)
- 최우선: 포르투갈 사람이 실제로 많이 쓰는 짧은 구어 표현을 편마다 2개 이상. 표현 풀: pois · pois é · então · olha · ó · pá · epá · fixe · bué · giro · tá bem · está bem · pronto · vá lá · ya · sei lá · se calhar · de certeza · claro · afinal · mesmo · ainda bem · que chatice · não faz mal · tudo bem? · até já · um bocado · tás a ver? · percebes? · a sério? · nem pensar · quer dizer · coitado/a · ora essa · estou-me nas tintas(R4+) · desenrascar(R3+).
- 유럽판 말: tu + 2인칭 동사, estar a + 원형(진행), 접어는 동사 뒤(chamo-me), pequeno-almoço·autocarro·telemóvel·casa de banho·comboio·bica·galão·fino·Multibanco. 브라질 말(você 반말·gerúndio·ônibus·celular·trem) 금지.
- SNS·1:1 채팅·데이팅앱 장면 많이. 채팅 편은 kind "chat", 턴에 "ui":"bubble","at":"21:03", 읽씹은 "read":false.
- 편마다 반전 1회: twist(턴 번호) + twist_type(chaos·slip·reveal·emotion·ignore), 그 턴 tags 에 "twist". 이 레벨 묶음에서 chaos 가 30% 이상. 연애·플러팅 편은 심쿵 한 줄(웃음 킥과 다른 턴), 여성이 먼저 다가가는 편을 더 많이.
- 금지: 교과서체·번역투·설명 대사·다짐/감사 마무리·정리된 AI 말투. 실존 인물·작품·브랜드·출처 금지. 수위 12+, 술·질투는 flags.
- A = 학습자: "{name}" 만(국적·도시 고정 금지). B·C = 고정 인물 Inês(다정·장난)·Beatriz(서퍼·말 빠름·계획 바꿈)·Tiago(느긋한 바리스타·기타)·Duarte(룸메이트·직진·축구광), R3 이상 조연 Dona Fernanda(50대 여성)·Marta(40대 여성 상사). 남성 조연이 필요하면 Tiago·Duarte 를 쓴다.
- 성별: 학습자 성별로 바뀌는 낱말은 {남|여} 로 한 벌에 쓴다(예: obrigad{o|a}, cansad{o|a}, est{e|a} jovem). ko·note 도 같은 표시 가능.
- 감정 열(필수): 턴마다 "emotion" 하나, 한 턴에서 감정이 바뀌면 "segs":[[감정, 본문 조각], …](이으면 tl 과 같아야 함, 조각은 4글자 이상). 값 16개: neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle. neutral 만 쓰지 말 것 — 점원 polite, 받아치기 tsukkomi, 심쿵 gentle·shy. 숫자는 seg 세 번째 칸에 글로 읽기(예: ["polite","Número 147?","Número cento e quarenta e sete?"]).
- 편 메타: id "r<레벨>_<주제>_<a|b|c><n>"(주제 = friends·love·life·travel·work·culture·study, a 짧은·b 긴·c 채팅), region "R<레벨>", island, kind(short/long/chat/survival), purpose[], domain[], title(한국어), emoji, scene(한국어 한 줄), speakers{"A":"{name}","B":…}, cast{"B":"ines"…}(목소리: ines beatriz duarte tiago fernanda marta), register(casual/chat/polite/mixed), twist, twist_type, flags[], goal(한국어), expressions[].
- 턴: {"speaker","tl"(포르투갈어),"ko"(자연스러운 한국어, 같은 말투),"note"("x = 뜻" 한 줄),"tags":[…],"emotion" 또는 "segs"}. rd 는 쓰지 않는다(빌더가 만든다).

## 할 일
1. 맡은 레벨의 편을 `data/dialogues_src/pt-PT/level<N>.json`(JSON 배열)에 쓴다.
2. `python3 tools/build_dialogues.py data/dialogues_src/pt-PT/level<N>.json` 이 「검사 통과」가 될 때까지 고친다. 출력된 독음을 훑어 이상한 낱말이 있으면 보고만(rd_pt.py 는 고치지 말 것).
3. 다른 파일은 고치지 말고, 커밋·push 하지 말 것. 끝나면 편 목록(id·제목·반전 종류)과 상한 밖 낱말을 짧게 보고.
