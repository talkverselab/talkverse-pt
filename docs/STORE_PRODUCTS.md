# 스토어 상품·차별화 — 포르투갈어유니버스 (2026-11-09)

출시는 **Talkverse 통합 앱 하나**(com.talkverse.app)로 한다(uk 공지). 이 앱은 통합 앱 안의 포르투갈어 패키지(`portuguese_universe`)이자 개발·시험용 단독 앱(Zealot·TestFlight)이다. 가격 = `~/talkverse/PRICING.md`(사용자 확정 2026-11-09)의 앱 정가 / 앱 할인가. **등록은 사용자가** App Store Connect·Google Play Console 에서 한다.

## 1. 상품

| 상품 ID | 이름(한국어 표시) | 종류 | 기간 | 앱 정가 | 스토어 판매가(할인가) |
|---|---|---|---|---|---|
| `lang_pt_1m` | 포르투갈어 1개월 | 자동 갱신 구독 | 1개월 | 5,500 | **3,900** |
| `lang_pt_3m` | 포르투갈어 3개월 | 자동 갱신 구독 | 3개월 | 12,900 | **9,000** |
| `lang_pt_1y` | 포르투갈어 1년 | 자동 갱신 구독 | 1년 | 28,500 | **19,900** |
| `lang_pt_life` | 포르투갈어 평생 이용권(서비스 운영 기간 동안) | 비소모성 | — | 69,900 | **49,000** |
| `all_1y` | 종합 패키지 1년 — 모든 언어 | 자동 갱신 구독 | 1년 | 112,900 | **79,000** |
| `all_life` | 종합 패키지 평생 — 모든 언어(서비스 운영 기간 동안) | 비소모성 | — | 469,000 | **329,000** |

- 결제 시트는 정가를 취소선, 스토어 가격을 크게(`lib/screens/paywall_screen.dart`, 가격표는 `Purchase.configure`). 앱 안에서 사이트 가격을 안내·유도하지 않는다.
- 옛 평생 상품 `com.talkverse.portugueseUniverse.lifetime`·`lang_pt` 는 판매 중지, 복원 때 `lang_pt_life` 로 인정(`lib/data/purchase.dart` `_legacy`).
- 약관 https://talkverse.uk/terms/ · 개인정보처리방침 https://talkverse.uk/talkverse/pt/privacy/
- 통합 앱에서는 공용 결제가 스토어 스트림을 듣고 이 언어 상품을 패키지로 넘긴다(EMBED_GUIDE 5단계). `all_*` 의 인정 방식은 uk 가 정한다.
- **아직 잠근 기능이 없다** — 무료/유료 경계(굴절어 전략 A10: 레벨 0 + 매핑표 + 코어 + 라임 + 레벨 1 묶음 1~2 무료, 라임 직후 페이월)는 사용자 결정 대기.

## 2. 차별화(애플 지침 4.3 대비, `~/talkverse/STORE_DIFFERENTIATION.md`)

### 스토어 설명 첫 줄(안)
> 철자대로 읽었는데 안 들린다면 — 유럽 포르투갈어는 강세 없는 모음이 사라지고(telefone 「뜰르포느」) 음절 끝 s 가 「쉬」가 됩니다. 이 소리 규칙과 콧소리 모음(ão·ãe·õe)을 한국어 소리와 견주며, 포르투갈 사람이 자주 쓰는 말부터 배웁니다.

### 포르투갈어 전용 학습 도구(지금 앱에 있는 것만)
1. **문자와 발음** — 알파벳 26 · 모음·악센트 8(열린 é/ó·닫힌 ê/ô, avó/avô) · 비모음 8(ão·ãe·õe·em…) · 자음 조합 8(ch·lh·nh·rr·ç·qu…) · **모음 약화 4**(e → 으, o → 우, 강세 자리). 칸을 누르면 1초 뒤 예시 낱말 재생, IPA, 소리 나는 곳, 한국어 소리와 비교.
2. **유럽판 한글 독음** — 회화 문장마다 유럽판 발음 규칙(어말 s 「쉬」·모음 약화·n/l/s 뒤 r 「ㅎ」)으로 만든 독음, 「쉬」·「아웅」 표시와 범례. 기본은 꺼짐(켜면 「힘들어도 독음을 보지 않고 익혀보세요」).
3. **절벽 단어** — 포르투갈에서 만든 영화·드라마 대사를 기본형으로 센 순위: 55단어로 55%, 83단어 60%, 217단어 70%, 656단어 80%(2,000위 누적 88.5%). 브라질판 기준(63·96·243·727)도 앱 소개에 따로. 20어 단원 타일.
4. **회화 리더** — 문장 속 밑줄 낱말을 누르면 기본형(동사 원형) 단어창. 장면 그림 아래 대사 띠, 그림 카드(앞면 한국어).

### 출시 전에 채울 것(지금은 없음 — 설명에 쓰지 않는다)
- 회화 32편(굴절어 전략 레벨 0~5, 남·여 학습자판, 굴절 반복, 감정 열)은 Claude 초안 — Grok 재작성(11-09~)·사용자 통과 뒤 앱 연결. 지금 앱 회화는 9월 초안 5편.
- 회화 음성: 시험 4편 102줄은 사용자 청취에서 실패 → 재시험 대기. 장면 컷 없음.
- 「동사 활용」은 데이터가 거의 없고(`verbs_core.json`), 「성·수」는 준비 중 화면 — 출시 전에 채우거나 뺀다(지침 2.1).
- 접어 위치(diz-me / não me diz)·ser/estar 를 보여 주는 문법 장치는 설계만(`docs/GRAMMAR_LEVELS_pt.md`).

### 실측 숫자(출시 때 다시 확인)
- 절벽(pt-PT): R1 55 · R2 83 · R3 217 · R4 656 레마, 2,000위 누적 88.5%(181편·97만 토큰). pt-BR 63 · 96 · 243 · 727.
- 회화: 앱 5편 / 초안 32편·335턴. 음성 줄: 0(출시 판 기준).

### 심사 메모 문단(영문, [N] 은 출시 판 숫자로)
> This app is one of a family of language-specific apps by Universal Talking Lab (Talkverse). Each app is built from scratch for one target language for Korean speakers and is NOT a re-skin: the European Portuguese app has its own script & pronunciation module (26 letters, open/closed accented vowels, 8 nasal vowels such as ão/ãe/õe, digraphs ch/lh/nh/rr, and the unstressed-vowel reduction rules of European Portuguese), its own grammar tools (clitic placement, ser/estar, estar a + infinitive), [N] original conversation episodes with recorded audio written for this language in separate male/female learner versions, and a vocabulary list measured from a European Portuguese conversation corpus (55 / 83 / 217 / 656 lemmas cover 55 / 60 / 70 / 80 %). Content, curriculum and UI flows differ between apps; we keep them separate because learners search for and buy one language at a time.

### 스크린샷 순서(고유 화면 먼저)
1. 문자와 발음 — 비모음 격자(ão·ãe·õe) + 발음 시트(IPA·한국어 비교)
2. 문자와 발음 — 모음 약화(telefone 뜰르포느) 또는 회화 리더 독음 「쉬」·「아웅」 표시
3. 절벽 단어 — 55/83/217/656 표와 20어 단원 타일
4. 회화 리더 — 밑줄 낱말 탭 단어창
5. 결제 시트(정가 취소선·할인가) — 마지막. 홈·프로필로 시작하지 않는다.
