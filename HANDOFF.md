# HANDOFF — talkverse-pt (포르투갈어유니버스) · 2026-11-07

규칙은 `CLAUDE.md`(서명 §1·Zealot §8·판 §9·회화 원칙 §10), 언어앱 공통 절차는 `~/talkverse/LANG_APP_REPLICATE_PROMPT.md`.

## ▶ 다음 세션이 바로 할 일(2026-11-08 세션 종료 시점)
1. **Grok 완전 재작성**(11-09 재개 — **한자 세션 대행 중단**: 자기 크롬을 M4 에서 켜고 `ssh macmini4` 로 `/usr/bin/python3 ~/talkverse-uk/tools/grok_cookie_sync.py 9231 <자기 포트>` 로 쿠키 동기화, 도구는 M6 `~/Hanja/tools/grok_req.py`·`grok_cdp.py` 를 복사해 씀, uk 의 방·9231 탭은 건드리지 않음 — `~/logs/rc/RELAY_grok_20261109.md`, 요청문 작성법 `~/talkverse/GROK_PROMPT_GUIDE.md`): 회화 32편(`data/dialogues_src/pt-PT/*.json`)을 편마다 새 방에서 「모든 줄 새로」 → 리뷰 → `build_dialogues.py`(원본 전부 한 번에) → `make_plan.py` → REVIEW_pt 갱신 요청.
   - **Grok 은 PC 크롬에서(사용자 지시 11-09 "집필 시작 안 한 세션은 PC 에서 시작")**: `~/talkverse-uk/docs/GROK_CHROME_PORTS.md` 표에 빈 포트(예: 9248)를 먼저 적고, PC 에 프로필 `D:\chrome-grok-pt` 로 예약 작업 크롬을 띄운 뒤(헝가리어 `Grok-Chrome-hu-9247` 참고) M4·M6 에서 `ssh -fN -L <포트>:127.0.0.1:<포트> pc` 터널, 쿠키는 M4 에서 `grok_cookie_sync.py 9231 <포트>`.
   - **Grok 모델 = 「전문가」(사용자 지시 11-09)**: 크롬을 켜면 먼저 확인 — `ssh macmini4 '/usr/bin/python3 ~/talkverse-uk/tools/grok_mode.py <포트> --check'`, 아니면 `--check` 없이 실행해 전문가로 바꾼다(화면에서는 입력창 옆 모델 단추).
   - **Grok 프롬프트 최소화(사용자 지시 11-09)**: 규칙은 문서에 한 번만 쓰고, 방 첫 메시지에서 「이후 파일 이름 한 줄만 보낸다」고 약속한 뒤, 이후 채팅은 한 줄씩만 보낸다. 그림이 처음과 달라지면 최초 통과 그림을 기준으로 한다(이미 만든 것은 그대로).
   - 감정 열: 회화를 만들거나 다시 쓸 때 줄마다 emotion/segs 를 넣는다(이미 32편 모두 있음, `tools/tts/make_plan.py`).
2. **앱 연결(전략 문서 단계 A)** `docs/APP_BUILD_STRATEGY_pt.md`: pubspec 에 `assets/data/pt-PT/` 등록, `DialogueService` 를 새 폴더 로더로, 회화 음성 재생(`dialogue_audio.dart` 이식). Android·iOS 함께 올림.
3. **절벽 단어 뜻 373어 채우기**(회화 밖 동결 해제됨): `assets/data/freq/lang_pt_top.csv` 뜻 빈칸 → `tools/build_cliff_words.py` 재실행.
4. **음성 재시험**: 사용자가 실패 원인(억양·발음·감정·목소리)을 아직 답하지 않음. 답 받으면 QA 기준 0.9·어말 s 검사로 1편 재시험(uk 에 순서 요청).
6. 답 없는 사용자 질문: 성별판 형식(A9, 지금 = 판별 파일)·강세 부호(B10, 지금 = 표준 철자) — `docs/DIALOGUE_RULES_pt.md` §D.
- 결정된 것: 레벨 = 문법 단계 R0~R5, 존칭 R3, 넓힌 어휘 상한, 접어 R1/R2/R5, 접속법 R4(굳은 표현 R0) — `docs/GRAMMAR_LEVELS_pt.md`. 굴절 노출 점검 `~/.venvs/pt_nlp/bin/python tools/check_inflection.py`.

## 11-09 가격·스토어·통합 앱
- 가격 확정(b1aa979, uk 작성): 상품 `lang_pt_1m·3m·1y·life`·`all_1y·all_life`, 결제 시트 정가 취소선·규정 표기·약관 링크. 옛 평생 ID 는 복원 때 `lang_pt_life`. 무엇을 잠글지는 사용자 결정 대기.
- 스토어 차별화 `docs/STORE_PRODUCTS.md`(지침 4.3 — 설명 첫 줄·전용 도구 4·실측 숫자·심사 메모·스크린샷 순서). 출시 전에 채울 것(동사 활용 0개·성·수 준비 중·회화 초안·음성)도 거기.
- 통합 앱 연결점(de477f6, `~/talkverse/talkverse-app/EMBED_GUIDE.md`): `lib/embed.dart`(embedInit/embedApp)·`lib/core/embed_env.dart`(assetPath·dataDir)·`lib/core/prefs.dart`(설정 키 `pt_` 접두, 단독 앱 옛 키 한 번 이동)·DB `pt_portuguese_universe`. 패키지 `portuguese_universe`, 콜백 `talkverse.pt://auth`, drift 2.34.4·drift_flutter 0.3.1·sqlite3_flutter_libs 0.6.0+eol. **통합 앱 자체는 uk 담당 — 여기서 고치지 않는다.** 새 코드도 SharedPreferences 대신 `Prefs`, rootBundle·Image.asset 은 `assetPath()`.

## ⛔ 지금 걸려 있는 사용자 지시
- ~~콘텐츠 생성 금지~~ — 2026-11-08 사용자가 회화·회화 밖 모두 해제.
- **아이콘은 talkverse.uk 세션 담당** — mipmap·AppIcon 파일을 직접 고치지 말고 요청.
- **Grok 은 이 세션이 직접**(11-09 한자 세션 대행 중단 — 위 1번 절차).
- **맥미니(M6) 부하**: 시뮬레이터는 쓰고 바로 `xcrun simctl shutdown`, 빌드는 `ps -axo args= | grep -c '^[^ ]*dartvm .*flutter_tools'` 가 3 이상이면 기다렸다가.

## 상태 표
| 항목 | 상태 |
|---|---|
| 캐릭터 시안 ① | **통과**(11-03) — `data/review/art/chars_pt_v1.jpg`, 인물표 `CHARACTERS.md` |
| UX/UI 시안 ② | **통과**(11-03) — 글 `data/review/uxui/sian_pt_01.md`, 그림 `sian_pt_02.jpg`(PT-01 은 캐릭터 미반영으로 다시 그림) |
| 아이패드 빌드 ③ | 코드 `ba4007e`·`b73eec4`, 아이패드 스크린샷 9장 넘침 0·통합 테스트 통과 |
| Android | CI 빌드 **17**(de477f6) · Zealot(11-09) · PC 백업 완료 |
| iOS | TestFlight **빌드 2611091215**(11-09, 가격·통합 앱 연결점 포함, Sign in with Apple 확인) · IPA PC 백업 |
| 로그인·결제 | 코드 `d58eb09`(Talkverse ID client_id `pt`, 상품 `com.talkverse.portugueseUniverse.lifetime`/`lang_pt`) — 잠근 화면은 아직 없음 |
| 절벽(레마) | **판별 재산정 11-03** — pt-PT R1 55·R2 83·R3 217·R4 656(상위 2,500 90.1%) / pt-BR 63·96·243·727, 자국 작품 자막 기준(`data/cliff/README.md`, `tools/pt_cliff.py`). 옛 234·403·1,134 폐기. 사이트 카드 = pt-PT 값 |
| 단어 그림 리스트 | talkversehanja `talkverse_art/words/pt.csv` = 새 레마 순위 2,500(PT·BR 합침, 구간 PT 경계, R5 = 절벽 밖, 340f9b5)·`pt_food.csv`(50), uk 세션이 D1 다시 적재 — 그림은 `GET https://auth.talkverse.uk/art/pt/manifest` |
| 저작권 정리 | 책 이름·책 파서 삭제 + 이력 재작성·강제 push 끝(11-02, 사용자 승인) |

## 11-08 회화 레벨 = 문법 단계 R0~R5(굴절어 전략, `docs/DIALOGUE_RULES_pt.md`)
- **11-08 전편 초안 32편**(제한 해제, Opus): R0 8 · R1 7 · R2 5 · R3 4 · R4 4 · R5 4편, 턴 335, chaos 47%. 원본 `data/dialogues_src/pt-PT/level0~5.json` + `sample_r1_r4.json`. Grok 완전 재작성(11-10 뒤) → 리뷰 → DB·앱 연결 대기.
- 레벨별 한 편씩 6편: R0 `r0_love_c1`(level0.json) · R1~R4 기존 4편(sample_r1_r4.json) · R5 `r5_work_b1`(level5.json). 작성 지시서 `data/dialogues_src/BRIEF_pt.md`. 사용자 검수 통과를 uk 가 전하면 나머지를 이 지시서로 끝까지 쓴다(편 수는 레벨당 핵심 약 50문장).
- 빌드: `python3 tools/build_dialogues.py data/dialogues_src/pt-PT/*.json` 를 **모든 원본을 한 번에** 넘겨 돌린다(리뷰 md 를 넘긴 파일로만 다시 씀).

## 11-07 회화 Claude 초안(사용자 지시: 회화 작성 제한 해제, 굴절어는 레벨별 한 편씩)
- 4편으로 멈춤: R1 `r1_love_a1` · R2 `r2_friends_b1` · R3 `r3_life_b1` · R4 `r4_work_b1`(유럽판, 남·여 판별 파일 8개). R0 은 R1 에서 나누는 구간이라 따로 안 썼다. 브라질판은 아직 없음.
- 원본 `data/dialogues_src/pt-PT/`(성별 표시 `{남|여}`) → `tools/build_dialogues.py` → `assets/data/pt-PT/dialogues/<male|female>/R*/`. 독음 `tools/rd_pt.py`. 읽는 판 `data/review/write/dialogues_pt_review.md`.
- 앞으로 쓰는 회화는 턴마다 `emotion`, 감정이 바뀌면 `segs`([감정, 본문])를 원본에 함께 쓴다(값 16개 = 일본어앱 `data/tts/PLAN_GUIDE.md`, 사용자 지시 11-07). `tools/tts/make_plan.py` 가 원본의 감정으로 `data/tts/plan/` 을 자동 생성한다(손으로 쓰지 않는다). 순서: `build_dialogues.py` → `make_plan.py` → `make_jobs.py`.
- pubspec 에 안 넣어 앱에는 아직 없음. 다음 단계: Grok 재작성(11-10 이후, 편 1개씩) → 리뷰 → `lemmas`(spaCy) → 앱 연결(`DialogueService` 는 아직 L1.json 만 읽음). 조연 Dona Fernanda·Marta 는 그림 기준이 없다.

## 11-07 회화 음성(4편 102줄, 약 6분)
- R2 `audio/pt/…`·D1 `audio_lines`(lang `pt`) 올림, 목록 `data/tts/audio_pt.json`, 리뷰 `data/review/REVIEW_pt.html` → uk 세션에 갱신 요청함. 도구 `tools/tts/`, 작업 폴더 `~/tts_work/pt`, 받아쓰기 venv `~/.venvs/tts_zh`.
- 조각 85개 중 84개 통과. r2_friends_b1 3턴 남성판 「O quê?!」(`03_0_m`)는 세 번 재생성해도 길이 기준 초과·받아쓰기 「Ok.」 — 가장 나은 판으로 올렸다. 유럽판 억양은 사람이 듣고 판단해야 한다.
- 앱 재생 코드(`dialogue_audio.dart` 등)는 아직 없다. 회화 새 구조를 앱에 연결할 때 함께.

## 11-08 「문자와 발음」 기초 메뉴(공통 프롬프터 §5-3)
- `lib/screens/pt_sounds_screen.dart` · `lib/widgets/pt_sound_sheet.dart` · 데이터 `lib/services/pt_phonetics.dart`(알파벳 26 · 모음·악센트 8 · 비모음 8 · 자음 조합 8 · 모음 약화 4). 조음 그림 `assets/images/ipa/places_of_articulation.png` 는 임시(출처 표기 없음, 출시 전 공용 Grok 그림으로 교체).

## 11-07 단어·메뉴 개편(`1032064`, 일본어앱 `docs/MENU_WORDS_2026-11-07.md` 이식)
- 절벽 단어: 유럽판 절벽 순위 2,000위, 20어 단원·타일, 「회화 단어 포함(+5)」. 데이터 `tools/build_cliff_words.py` → `cliff_pt_PT.csv`·`conv_words_pt.json`. **`lang_pt_top.csv` 의 rank 는 PT·BR 합친 그림 목록 순서 — 절벽 순위로 쓰지 말 것.**
- 상위 2,000어 중 373어는 뜻 없음(단어만 표시) — 콘텐츠 금지가 풀리면 채운다. 레마는 사용자 지시(11-07)로 그대로 둔다.
- 앱 소개(`about_screen.dart`, 2번 칸 = 브라질판 표), 메뉴 기초→문법→회화→단어→참고, 「문장 말하기」, 회화 노트·앱 업데이트 타일 제거(코드 `update_screen.dart` 는 남음), 프로필 정리·학습 기록 초기화(회화·동사).
- 문장 레마 탭(`lib/widgets/lemma_text.dart`), 독음 전역 토글 `KoReadingPrefs` 기본 미표시·켤 때 안내.
- 아직 안 본 것: 실제 화면 스크린샷 — iOS 재개 뒤 `integration_test/menu_words_test.dart` + `tools/pane_shots.py`. 그 다음 `tools/ios_release.sh` → TestFlight, uk 세션에 한 줄 답.

## 11-04~05 일본어앱 변경 이식(`ee8e5a1`·`ce9c53c`·`aa4b02d`·`91be624`)
- 대사는 그림 아래 띠(오버레이 말풍선 없음), 카드 앞면 한국어, 턴 `lemmas` + 레마 칩(`tools/add_lemmas.py`, 고침표 `LEMMA_FIX`), 빈도 단어 2,505어(`assets/data/freq/lang_pt_top.csv`, uk 세션 작성) — 레마 93개 전부 연결.
- 시작 때 그림 기기 내려받기(`lib/services/content_sync.dart`·`lib/screens/sync_screen.dart`, 929장·약 24MB), `assets/data/version.json` db=4, 이름 없으면 묻기, `<편id>_f` 컷 먼저.
- **DB 다시 채워도 학습 기록 유지**(`SeedLoader` 가 (레벨·편·턴 번호)로 되붙임, `test/seed_progress_test.dart`). 데이터를 바꾸면 version.json 번호만 올린다.
- 아직 없음: 여자 학습자 컷·조연 캐릭터 시트(⑦⑧ 의 그림) — Grok 대기 해제 뒤. 코드는 준비됨.
- 빌드 대기 수는 `ps -axo args= | grep -c '^[^ ]*dartvm .*flutter_tools'` 로 센다(`pgrep -f flutter_tools.snapshot` 은 대기 명령까지 세어 서로 기다리게 된다).

## 이번에 만든 것(③)
- 넓은 화면(가로 720+): 레일 + 왼쪽 탭 | 오른쪽 칸(`lib/core/pane.dart`), 폰은 하단 탭·세로 고정(`main.dart` `_setOrientations`).
- 회화 리더(`lib/widgets/episode_play_pane.dart`) — 장면 컷(지금은 공유 단어 그림 → 이모지)·말풍선·캡션·대화 스크립트·재생/속도/자막 칩·편 끝 연출, 그림 카드(`dialogue_card_screen.dart`), 회화 홈(`dialogue_screen.dart`).
- 포르투갈어 칸: 독음의 「쉬」(어말 s·z)·「아웅」(비모음 ão) 표시 + ⓘ 범례(`lib/widgets/pt_reading.dart`), 자막 줄 끝 「Portugal ▾」 칩(브라질판 준비 중 안내).
- 「나」 성과 데스크(진행 탭), 학습자 이름·성별(프로필), 홈 메뉴 「회화」→ 새 리더 · 옛 화면 「회화 노트」.
- 데이터는 그대로 — 초안 `assets/data/dialogues/L1.json` 을 `lib/services/dialogue_service.dart` 가 읽어 변환.
- 화면 문구 스페인어 잔재 정리(Olá!·INICIANTE 1·Minjun & Inês·Progresso·Dia 1).
- 스크린샷 흐름: `integration_test/dialogue_pane_test.dart` + `tools/pane_shots.py`(아이패드 시뮬레이터 「pt-shots iPad Pro 11」 3F293F2F-E008-495C-AE42-B1AC2CF6F5C5, 쓴 뒤 shutdown).

## 사용자가 할 일
1. **평생 이용권으로 무엇을 열지** 결정(예: R2 이상 회화·단어, 브라질판) — 정해지기 전에는 잠그지 않는다.
2. 스토어 인앱 상품 등록(iOS `com.talkverse.portugueseUniverse.lifetime`, Play `lang_pt`), 데모 계정에 lang `pt` 이용권 부여는 talkverse.uk 세션에 요청.

## 다음 할 일(지시가 오면)
- 동사 활용 시트(시안 PT-01 칸 ①) — `assets/data/grammar/verbs_core.json` 이 비어 있어 미구현. 콘텐츠 금지가 풀리면 동사 데이터와 함께.
- 회화: R1~R4 재태그·성별판(남·여 파일)·pt-PT/pt-BR 폴더·반전 턴·검수(공통 원칙 https://talkverse.uk/talkverse/dialogue-rules/). 지금 초안은 남성 학습자·유럽판뿐.
- 절벽 말뭉치 한계: 자국 작품 수가 적고(PT 181편·BR 115편), pt-BR 은 브라질판 전용 자막 묶음이 아니라 포르투갈어 묶음 안의 브라질 제작 작품 — 더 정확히 하려면 브라질판 묶음을 받아 분류부터.
- 공용 사전 원본 `talkverse/_update_kit/l10n/l10n_dict.dart` 에 이 앱에서 추가한 로그인·리더 문구를 옮길지(다른 앱 세션과 겹치지 않을 때).
- 작업 트리에 줄바꿈(CRLF)만 다른 파일이 남아 있다 — `git add -A` 금지, 바꾼 파일만 경로로.
