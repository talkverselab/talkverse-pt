# 포르투갈어유니버스 — 앱 구축 전략 (2026-11-08)

바탕: `~/talkverse/INFLECTED_LANG_STRATEGY.md`(사용자 결정 ✔ 11항목) → 이 앱 옮김 `docs/DIALOGUE_RULES_pt.md`(A-빈칸 표·4편 점검·사용자 확인 3건) · `CLAUDE.md` §1·§8·§9·§10 · `HANDOFF.md`(11-07 상태). 구조 참고 = 일본어앱(`~/talkverse/ja` `dialogue_service.dart`·`dialogue_audio.dart`), 러시아어 `~/talkverse/ru/R0_R4_PLAN.md`.
이 문서는 **계획**이다. 지금 걸린 제한 = 회화는 레벨별 한 편(11-08 R0~R5 6편, 사용자 검수 대기) · 회화 밖 콘텐츠 동결 · 사용자 확인 대기 3건(§D-1 존칭 위치, §D-2 성별판 형식, §D-3 강세 부호). 아래 ⛔ = 동결·대기에 막힘, ⚙ = 지금 해도 되는 코드·도구 작업.

## 0. 한 장 요약 — 결정을 이 앱에 놓으면

| 레벨(= 문법 단계) | 이름 | 어휘 상한(pt-PT 절벽) | 문장(핵심:변형) | 무료/유료 | 지금 있는 편 |
|---|---|---|---|---|---|
| 0 | 소리·짧은 회화 | R1 55 | 짧은 회화 2~3편(카드 없음, 로마자) | 무료 | `r0_love_c1`(11-08) |
| 1 | 활용 골격(관사·성수·ser/estar·현재·완료과거·estar a) | R1 55 | 500 = 50+450, 10묶음 | 묶음 1~2 무료 → **라임 직후 페이월** → 3~10 유료 | `r1_love_a1` |
| 2 | 챗 실전 | R2 83 | 500 | 유료 첫 구간 | `r2_friends_b1` |
| 3 | 그래머2(복수 nós/vocês/eles · 존칭) | R2 83(새 단어 0) | 500(1 의 핵심 50 을 갈아끼움) | 유료 | — (`r3_life_b1` 은 존칭·접속법 → 4 쪽) |
| 4 | 어려운 문법(접속법·인칭 부정사·미래·조건법) | R3 217 → R4 656 | 500 | 유료 | `r4_work_b1`(+ r3 재배치) |
| 5 | 어휘 완주(문법 신규 0) | R5 657~2,000 | 500(v2.0 에 나머지) | 유료 | `r5_work_b1`(11-08) |

- **레벨 번호 ≠ 단어 메뉴 R1~R5.** 단어 메뉴(`word_freq_screen.dart` `kCliffsPt`)는 절벽 tier 그대로 둔다. 회화 레벨은 「레벨 0~5」로 부르고 앱 소개(`about_screen.dart`)에 한 문단 추가: "회화 레벨은 문법 단계, 단어 구간 R1~R5 는 빈도 절벽 — 번호가 달라요".
- 변형 450 = 「뺑뺑이」 카드: 같은 묶음 패턴에 lemma 만 바꾼 문장. 회화 리더가 아니라 **문장 카드**(`sentence_flashcard_screen.dart` 확장) 에서 흘려보낸다.
- 단수 우선(A3): 레벨 1·2 회화·카드는 eu·tu·ele/ela 만. 검사기가 1인칭 복수·2인칭 복수 어미(-mos·-m) 를 레벨 1·2 에서 오류로 잡는다.

> ⚠ 어휘 상한이 회화 작성 지시서(`data/dialogues_src/BRIEF_pt.md`: 레벨 0 = 83위, 1 = 217위, 2·3 = 656위)와 다르다. 위 표는 절벽 tier 를 그대로 대응시킨 안이다. 55·83어만으로는 회화가 거의 불가능해 지시서는 한 단계 넓게 잡았다 — 사용자 검수 때 한쪽으로 정한다.

## 1. 데이터 배치 (판 × 성별 × 레벨)

```
assets/data/
  version.json                 db 번호(SeedLoader) + 이 문서의 단계마다 +1
  pt-PT/                       유럽판 (지금 초안 전부)
    dialogues/{male,female}/R<레벨>/<주제>/<편id>.json   ← build_dialogues.py 산출(이미 있음, pubspec 미등록)
    cards/R<레벨>/<묶음>.json   변형 450 카드 {tl, rd, ko, morph_tags, core_slot}     ⛔ 동결
    core.json                   코어 40 + 활용 매핑표(무료)                         ⛔ 동결
    rhyme.json                  라임/후렴(화자 = Talkverse 외계인)                   ⛔ 시트 대기
  pt-BR/  같은 구조(비어 있음 — §6)
  dialogues/L1.json            옛 초안 5편 — 레벨 0 재태그 뒤 삭제 또는 pt-PT/…/R0 으로 이동
```

- 폴더의 R 숫자 = **회화 레벨**(A1·B14). 지금 `assets/data/pt-PT/dialogues/*/R3/life/r3_life_b1.json` 은 레벨 재배치 대상(⛔ 사용자 지시 뒤 폴더 이동 + `region` 값 수정).
- 편 메타는 지금 산출물 그대로(`id·region·island·kind·purpose·domain·title·scene·speakers·register·twist·twist_type·flags·expressions·cast·variant·learner_gender·draft`) + 추가 `level_stage`(묶음 번호, 레벨 1 만) · `free: true/false`.
- 턴 = `{num, speaker, tl, rd, ko, note, tags, emotion, segs?, lemmas?, morph_tags?}`. 성별은 **파일 분리**(§D-2 대기 — `tl_f` 방식으로 바뀌면 `build_dialogues.py` 가 두 파일 대신 한 파일에 `tl_f·rd_f·ko_f` 를 내도록 출력부만 바꾼다. 원본 `data/dialogues_src/pt-PT/*.json` 의 `{남|여}` 표기는 어느 쪽이든 그대로).
- DB: `Turns` 표에 `level`(지금 'L1') 과 `variety`(지금 'es_ES' 기본값 — 템플릿 잔재) 가 이미 있다. 열 추가 없이 `variety` 에 `pt-PT`/`pt-BR`, `level` 에 `R0`~`R5` 를 넣고 `episodeId` 에 편id. `UserProgress` 는 turnId 참조이므로 **SeedLoader 의 (레벨·편·턴 번호) 되붙임**(`test/seed_progress_test.dart`)에 `variety`·`learner_gender` 를 키에 더해야 남·여/판 전환 때 기록이 섞이지 않는다.

## 2. 단계별 계획

### 단계 A — 새 회화 구조 연결 + 음성 재생 (⚙ 지금 가능, 콘텐츠 작성 없음) · 약 3~4일

목표: 11-07 초안 4편(남·여 8파일)이 앱에서 보이고, 서버에 올라간 음성 102줄이 재생된다.

| 할 일 | 파일 |
|---|---|
| pubspec `assets:` 에 `assets/data/pt-PT/dialogues/` 추가(하위 폴더는 Flutter 가 한 단계만 묶으니 `AssetManifest` 로 열람) | `pubspec.yaml` |
| 로더를 일본어앱 방식으로: `AssetManifest.loadFromAssetBundle` → `assets/data/<판>/dialogues/<성별>/R*/...` 만 읽기, L1.json 은 `R0` 로 매핑해 유지 | `lib/services/dialogue_service.dart`(지금 `_load()` 는 L1.json 하나) |
| `Dialogue` 에 `variant·learnerGender·kind·twist·expressions·free` 칸, `levelKo` 를 레벨 0~5 이름으로(`R0 소리·짧은 회화 … R5 어휘 완주`) | 같은 파일, `lib/screens/dialogue_screen.dart` 표시 |
| 성별판 선택: `LearnerPrefs.gender` 로 `male/female` 폴더 고름, 성별 바꾸면 `ensureLoaded` 재실행 | `lib/services/learner_prefs.dart` 연동 |
| 음성: `ContentSync` 에 `audioManifestUrl = https://auth.talkverse.uk/art/pt/audio/manifest` 추가, `audioIndex[편][턴][m|f]`(ja `content_sync.dart` 44~62·157~168행 이식). 파일은 그림과 같은 `art/` 폴더·같은 버전 해시에 포함 | `lib/services/content_sync.dart` |
| `DialogueAudio`(ja `dialogue_audio.dart` 그대로, `t.ja`→`t.tl`), `speakTurn` 이 음성 없으면 `TtsService`(pt-PT) 로 폴백 | 새 `lib/services/dialogue_audio.dart`, `lib/widgets/episode_play_pane.dart` 75·85·118행 `TtsService` 직접 호출을 `speakTurn` 으로 |
| `version.json` db 4 → 5(회화 구조 변경), SeedLoader `_seedTurns` 가 새 폴더도 읽음 | `assets/data/version.json`, `lib/data/db/seed_loader.dart` |

검증: `flutter test`(seed_progress·menu_screens 통과) · `integration_test/dialogue_pane_test.dart` 에 R1 편 열기·음성 버튼 추가 · 아이패드 「pt-shots」+ 폰 스크린샷, 넘침 0 · 비행기 모드에서 받아 둔 mp4 재생 확인.
막힘: 없음(콘텐츠를 만들지 않음). 단 `r3`·`r4` 는 **지금 폴더 그대로** 보이게 두고 레벨 재배치는 지시 뒤.

### 단계 B — 레벨·묶음·페이월 뼈대 (⚙ 코드 가능, 내용은 ⛔) · 약 3일

목표: 레벨 0~5 홈, 레벨 1 안 묶음 1~10 진행, 「라임 직후 페이월」 자리. 아직 잠그지 않는다(HANDOFF 사용자 할 일 1).

| 할 일 | 파일 |
|---|---|
| 회화 홈을 「레벨 → 묶음(레벨 1) 또는 주제(2~5)」로. 묶음 데이터는 `assets/data/pt-PT/stages.json`(묶음 10개 이름·설명·`free`) — 이름만 넣고 내용은 비움 | `lib/screens/dialogue_screen.dart`(새 `StageListScreen`) |
| 잠금 규칙 한 곳: `Access.canOpen(level, stage)` = `level==0 || (level==1 && stage<=2) || Entitlement.premium`. 라임 화면 끝 버튼 → `Entitlement.showPaywall`. **스위치 `kPaywallOn=false`** 로 출시 전까지 전부 열어 둠 | 새 `lib/data/access.dart`, `lib/data/entitlement.dart` |
| 무료 「활용 매핑표」 화면 자리(코어 40 × 현재/완료과거 × eu·tu·ele) — 지금 `verbs_core.json` 비어 있음 → 빈 상태 안내 | `lib/screens/verb_screen.dart` 재사용 |
| 라임 화면(외계인 화자, 음성 1개, 가사 = 활용 어미 후렴) — 껍데기만, 캐릭터 시트는 uk 세션 답 대기 | 새 `lib/screens/rhyme_screen.dart` ⛔ |
| 앱 소개에 「회화 레벨 0~5 vs 단어 구간 R1~R5」 문단, `l10n_dict.dart` 세 사전 추가 | `lib/screens/about_screen.dart`, `lib/core/l10n_dict.dart` |

검증: `test/menu_screens_test.dart` 에 레벨 홈·잠금 off 상태 추가 · 스크린샷(레벨 홈·묶음 목록·페이월 시트) · 넘침 0.
막힘: 묶음 이름 10개는 `DIALOGUE_RULES_pt.md` A-빈칸의 안을 그대로 쓰되 **콘텐츠가 아니므로** 넣어도 되는지 사용자 한 줄 확인. 존칭 묶음 위치는 §D-1 답 대기(레벨 2 끝 vs 레벨 3).

### 단계 C — 뺑뺑이 카드 파이프라인 (도구 ⚙ / 데이터 ⛔) · 약 1주

목표: 변형 450 을 만드는 도구와 카드 화면. A12 순서(어휘표 CSV → 슬롯 → 핵심 → 변형 → 태깅) 를 스크립트로 준비.

| 할 일 | 파일 |
|---|---|
| `tools/core_csv.py`: `data/cliff/pt_PT_top5000_lemma.csv` 상위 55 → 기능어/내용어 라벨 + 코어 40 후보 표(사용자가 고름) | 새 도구 ⚙ |
| `tools/morph_tag.py`: spaCy `pt_core_news_sm` 으로 `morph_tags`(Gender·Number·Person·Tense·Mood) + 코어 밖 단어 표시. **이 맥에 spaCy 없음** → `~/.venvs/tts_zh` 와 별도 venv `~/.venvs/pt_nlp` 에 설치(모델 ~15MB) | 새 도구 ⚙(설치 필요) |
| `tools/pick_variants.py`: 코퍼스 문장 풀 → 레벨 1 어휘 100% 커버 + 단수만 + 가중치(빈도 20·활용 시연 35·양태 15·시제 10·단순성 15) → 450 후보 → Claude 정제 | 새 도구 ⚙(풀은 로컬에만, 저장소에 원문 금지) |
| `build_dialogues.py` 검사 확장: 레벨 1·2 에서 복수 어미·você·o senhor 금지, 레벨 1 단어 ≤ R1 55 + 편당 1 | `tools/build_dialogues.py` ⚙ |
| 카드 화면: `SentenceFlashcardScreen` 이 DB `turns` 대신 `cards/R1/<묶음>.json` 도 읽음, 앞 한국어·뒤 포르투갈어+독음+`morph_tags` 칩(「말 조각」) | `lib/screens/sentence_flashcard_screen.dart`, `lib/widgets/lemma_chips.dart` 재사용 |
| 레벨 1 핵심 50 = 회화 편 5~7편(묶음당 5문장) 작성 → 변형 450 | ⛔ 동결 해제 뒤 |

검증: 도구 단위 테스트(태거가 `Estás sozinho?` → 2sg·pres·m 를 내는지) · 카드 화면 스크린샷 · `rd_pt.py` 로 450 문장 독음 검사(로마자 잔류 0).
막힘: 데이터 전부 ⛔. §D-3(강세 부호) 답에 따라 `rd_pt.py` 입력을 표준 철자로 둘지 결정 — 기본 제안은 철자 그대로.

### 단계 D — 레벨 2~5 채우기 + 기존 4편 재배치 (⛔ 전부 지시 뒤) · 레벨당 1~2주

- 레벨 2 챗 실전: `kind: chat`·`ui: bubble`·`at`·`read` 턴 칸 → `episode_play_pane.dart` 에 말풍선 모양 분기(지금은 띠 하나). `r2_friends_b1` 이 표본.
- 레벨 3 그래머2: 레벨 1 핵심 50 을 nós/vocês/eles + 존칭(o senhor/a senhora + 3인칭 단수)으로 갈아끼운 같은 문장 — 새 단어 0, 도구 `tools/regrade.py` 가 spaCy 로 주어·동사만 바꾸고 Claude 검수.
- 레벨 4: `r3_life_b1`(접속법·인칭 부정사)·`r4_work_b1`(복수·접속법 과거) 이동 + 어휘 R4 밖 단어 교체.
- 레벨 5: 문법 신규 0, R5 657~2,000 중 500 → 단어 메뉴 「뜻 없음 373어」 채우기와 같은 작업.
- 각 레벨 핵심 → 사용자 통과 → 변형, 레벨마다 `version.json` +1, Grok 재작성·리뷰 페이지(`tools/review_html.py`) 한 바퀴(B13).

### 단계 E — 브라질판 (⛔ 콘텐츠, ⚙ 코드 일부) · 코드 2일 + 콘텐츠는 유럽판과 같은 분량

- 코드(지금 가능): `LearnerPrefs.variant`(`pt-PT` 기본) → 첫 실행 `learner_setup_dialog.dart` 에 「포르투갈 / 브라질」 질문, `DialogueService` 가 `assets/data/<variant>/` 읽기, `TtsService.locale` 을 `pt-PT`/`pt-BR` 로, 자막 칩 「Portugal ▾」(`pt_reading.dart`)가 실제 전환. 단어 메뉴 `kCliffsPt`/`kCliffsBr` 도 판 따라.
- `rd_pt.py` 는 pt-PT 규칙(어말 s → 쉬, 무강세 e 약화) — 브라질판은 별도 표 `rd_br.py` 필요(어말 s → 스, de → 지, te → 치). ⛔ 표기표 결정 뒤.
- 데이터: `pt-BR` 폴더 비움, 「준비 중」 안내. 학습 기록은 `variety` 로 분리(§1).

## 3. 배포 — 안드로이드·iOS 매번 같이

| 단계 | 안드로이드 | iOS |
|---|---|---|
| 빌드 | `master` push → `release.yml`(빌드 번호 = run_number, `**.md`·`tools/**`·`docs/**` 는 건너뜀) | `bash tools/ios_release.sh`(빌드 번호 = KST yymmddHHMM) |
| 배포 | `gh release download latest -p '*.apk'` → `apksigner` SHA-1 `9cc4bc93…` 확인 → `bash tools/zealot_push.sh "<한 줄>"`(앱이름 「포르투갈어유니버스」) | TestFlight 내부 그룹(최신 2611052356) |
| 백업 | PC `D:\OneDrive\app project\talkverse-pt\` | PC `…\ios\` |
| 확인 | 폰 덮어 설치(서명 같음·번호 증가) | 아이패드 가로·세로 스크린샷 |

규칙: 단계 A·B·E 코드가 끝날 때마다 **둘 다** 올린다(한쪽만 올리면 TestFlight 와 Zealot 내용이 어긋남 — 지금이 그 상태: Android 빌드 13, iOS 는 11-06). 콘텐츠만 바뀐 단계(C·D)도 `version.json` 이 바뀌므로 둘 다. `CoreSimulator` 가 풀리기 전엔 iOS 를 건너뛰고 HANDOFF 에 「iOS 미반영」 줄을 남긴다.

## 4. 위험

| 위험 | 영향 | 대응 |
|---|---|---|
| pt-PT 생성 음성(MOSS) 억양이 사용자 청취에서 통과 못함 | 레벨 1 핵심 50·라임 음성 전부 재생성 가능 | 단계 A 는 재생 구조만 붙이고 **TTS 폴백을 항상 살려 둔다**; 음성 교체는 키 `audio/pt/<편>/<턴>_<m|f>.mp4` + `?v=sha1` 이라 앱 수정 없이 서버 교체로 끝남. 다른 음성 엔진·참조 음성 변경은 uk/TTS 담당과 상의 |
| spaCy `pt_core_news_sm` 이 이 맥에 없음 | morph_tags 자동 태깅 불가 | `~/.venvs/pt_nlp` 신설(단계 C 첫 작업). 태거는 도구 전용, 앱에는 결과 JSON 만 |
| M6 CoreSimulator 1174.9.2 < 1174.21 (Xcode 27.2) | iOS 빌드·시뮬레이터 전부 정지 | 허브가 `sudo xcodebuild -runFirstLaunch` 처리 중 — 해결 전 iOS 명령 시작 금지(`~/logs/rc/RELAY_xcode_20261107.md`), 안드로이드로 검증 |
| 성별판 형식(§D-2)·존칭 위치(§D-1)·강세(§D-3) 미결 | 로더·검사기·rd 규칙이 흔들림 | 단계 A 는 지금 산출물(파일 분리·존칭 그대로·표준 철자) 기준으로 하고, 답이 오면 `build_dialogues.py` 출력부·검사표만 바꿈 |
| `Turns.variety` 기본값 `es_ES`, `es` 칸 이름 등 템플릿 잔재 | 판 전환 때 기록 꼬임 | 단계 A 에서 기본값을 `pt-PT` 로, SeedLoader 되붙임 키에 `variety` 추가(열 이름 `es` 는 drift 마이그레이션 비용이 커 유지) |
| 작업 트리에 CRLF 만 다른 파일 다수 | `git add -A` 하면 쓸모없는 diff | 바꾼 파일만 경로로 add |
| 외계인 캐릭터 시트 없음 | 라임 화면·컷 못 만듦 | 껍데기만 두고 uk 세션 답 대기, 그림은 한자 세션 경유 |
| 공개 저장소 | 코퍼스·작품 이름 노출 | 변형 선별 풀은 `data/`·`.gitignore` 밖 로컬(`~/tts_work/pt` 옆 `~/corpus_work/pt`)에만, 저장소엔 산출 문장만 |

## 5. 동결 해제 뒤 처음 할 3가지

1. `tools/core_csv.py` 로 레벨 1 어휘표 CSV(상위 55 + 기능어/내용어 라벨) 를 뽑고 **코어 40 을 사용자에게 고르게** 한다(A12 ①).
2. `~/.venvs/pt_nlp` 에 spaCy + `pt_core_news_sm` 설치, `tools/morph_tag.py` 로 기존 4편 32턴(남·여 64)에 `morph_tags` 를 붙여 검수 표본 1장을 만든다(A8).
3. 레벨 1 묶음 1(관사+명사 성)·묶음 2(형용사 일치) 핵심 10문장을 회화 편 2개로 쓰고 → 검사기 → Grok 재작성 → 리뷰 페이지 → 통과 뒤 변형 90(1:9) 선별(A12 ③④). 이 두 묶음이 무료 구간이므로 가장 먼저 품질을 확정한다.

## 6. 사용자 결정이 필요한 것(이 문서가 정하지 않음)

- §D-1 존칭 묶음을 레벨 2 끝에 둘지(3인칭 단수 직후), 결정대로 레벨 3 에 둘지.
- §D-2 성별판을 파일 분리(지금)로 갈지 턴 안 `tl_f` 로 갈지 — 앱 로더는 어느 쪽이든 하루 작업.
- §D-3 본문은 표준 철자 그대로, 강세는 독음 규칙에서만(제안).
- 묶음 10개 이름을 지금 코드에 넣어도 되는지(콘텐츠 동결 범위인지).
- 페이월 스위치를 켤 시점·평생 이용권 범위(브라질판 포함 여부) — HANDOFF 「사용자가 할 일」 1 과 같음.
