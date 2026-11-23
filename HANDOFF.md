# HANDOFF — talkverse-pt (포르투갈어유니버스) · 2026-11-07

규칙은 `CLAUDE.md`(서명 §1·Zealot §8·판 §9·회화 원칙 §10), 언어앱 공통 절차는 `~/talkverse/LANG_APP_REPLICATE_PROMPT.md`.

## 11-09 밤 진행(Grok 재작성·앱 연결·단어 뜻)
- **Grok = PC 크롬 9260**(예약 작업 `Grok-Chrome-pt-9260`, 프로필 `D:\chrome-grok-pt`, 포트 표 M4 `~/talkverse-uk/docs/GROK_CHROME_PORTS.md` 에 적음 — uk 리포라 커밋은 안 함). 터널: M4·M6 각각 `ssh -fN -L 9260:127.0.0.1:9260 pc`, 쿠키 `ssh macmini4 '/usr/bin/python3 ~/talkverse-uk/tools/grok_cookie_sync.py 9231 9260'`, 모델 전문가 확인 `grok_mode.py 9260 --check`. 처음 띄우면 쿠키 동의 창(OneTrust)이 화면을 가려 모델 단추가 안 보임 → 「모두 거부」 누르면 됨.
- 도구 `tools/grok/`: `pt_dialogue_txt.py export|import`(원본 JSON ↔ 편별 글, 감정 바뀌는 곳은 ` // `, 숫자 읽기 `say=`), 규칙 `rewrite_grok_pt.md`(방 첫 메시지에만 첨부), `rewrite_all.sh`(10편씩 방 하나, 결과 `data/review/grok/out/`, 로그 `run.log`). 넣은 뒤 `build_dialogues.py`(모든 원본 한 번에 — 그래야 앱 묶음 `assets/data/pt-PT/dialogues/<male|female>.json` 이 갱신됨) → `make_plan.py`.
- 앱 연결(단계 A, 6cdd9d7): 회화 메뉴에 레벨 0~5(32편) + 옛 「이야기」 5편. 학습자 성별로 묶음 파일을 고르고 성별을 바꾸면 다시 읽음. 음성은 `ContentSync.audioIndex`(색인만, 미리 받기 없음) + `DialogueAudio` — **음성 글이 지금 대사와 같을 때만** 재생, 아니면 TTS. DB 시드(문장 카드·말하기)는 아직 옛 L1 만(전략 문서 단계 A 의 SeedLoader 항목은 남음).
- 절벽 단어 뜻: `data/freq/ko_fill_pt_PT.csv` 로 373어 채움(활용형 「(너) 간다 · ir」, 이름 「(이름) …」), 뜻이 「-」인 81어(말뭉치 잡음·외국 이름 조각)는 목록에서 숨김 — 순위 번호는 그대로.
- **11-10 00:20 멈춤(사용자 지시 "uk 세션 외 모든 세션 지금 작업만 마무리하고 작업 끄고 탭 닫고 대기")**: Grok 재작성 15/32 받음(`data/review/grok/out/`, 아직 원본에 안 넣음·리뷰 전). 3분 넘겨 중지된 편 r1_love_c1·r2_friends_c2 와 나머지 17편은 `zsh tools/grok/rewrite_all.sh` 다시 돌리면 이어서 함(있는 편은 건너뜀). 9260 의 Grok 탭은 닫음(크롬·PC 예약 작업은 둠).
- **Grok 답 3분 한도(사용자 지시 11-10 "그록 3분만, 넘어가면 대화방 중지")**: `grok_text.py` 기본 `--wait 180`, 넘으면 중지 단추(없으면 Esc) 누르고 저장 없이 rc=4.
- **11-10 세션 종료(허브 지시 "M6 꽉 참 — 마무리·캐시 삭제·세션 닫기")**: `flutter clean`·android/.gradle·__pycache__ 지움(약 3.7GB). 6cdd9d7(앱 연결·단어 뜻)은 push 했지만 [skip ci] 커밋이 맨 위라 **CI 빌드·Zealot·TestFlight 는 아직 안 함** — 다음 앱 변경 push 때 Android+iOS 함께. 지울 후보: `~/tts_work/pt`(32MB, 실패 판정 시험 음성 — R2·D1 에 올라가 있음; 사용자가 원인 답하기 전엔 둠).
- **DB 업로드 점검(11-10 uk 전달 "모든 자산 db 에")**: pt 음성 4편 102줄 = D1 `audio_lines` 와 일치, 단어 2,552 = `art_words`(uk), 장면 컷은 아직 없음. 회화 글을 담을 D1 표는 없음(앱 묶음으로 나감) — 표가 필요하면 uk·사용자 결정. Supabase 커넥터는 재로그인 필요해서 못 봄.
- **다음 할 일**: ① Grok 한도(11/16 초기화) 뒤 `zsh tools/grok/rewrite_all.sh` 로 남은 17편 → 32편 리뷰(브라질 말·문법 단계·{o|a}) → `pt_dialogue_txt.py import` → `build_dialogues.py` → `make_plan.py`·`check_inflection.py` → pubspec 빌드 번호 올려 push → CI APK SHA-1 확인·Zealot·PC 백업 + `tools/ios_release.sh`. ② 사용자 답 대기: 음성 실패 원인, A9·B10, 단어 잡음 이름이 옛 커밋·`pt_PT_top5000_lemma.csv` 에 남은 것 정리 여부.

- **11-19**: 빌드 — Android CI 빌드 19(Flutter 3.47.7 고정, 6db3614)·Zealot https://apps.talkverse.uk/KtegX/515·PC 백업, iOS TestFlight 2611191957(IPA PC 백업). 서버 원고 rev 4(노트 작성 표시 「(A 성별)」 10줄 지움). **새 회화 33편**(사용자 「새회화 시작·레벨 러시아어참고」 → R0~R5 그대로, 러시아어앱 분포로 R0 4·R1 8·R2 10·R3 5·R4 3·R5 3): 초안 `tools/grok/new_specs_1119.py`(흐름은 설명 문장, 대사 문장 금지) → 뼈대 `data/review/grok/new/` → uk 「pt 시작」 뒤 `zsh tools/grok/new_all.sh`(규칙 `write_grok_pt.md`) → `new_specs_1119.py apply` → `data/dialogues_src/pt-PT/new_1119.json` → build_dialogues·turn_lock·script_publish. uk 대기 4번. 대사 확정 뒤 음성 편 수를 uk 에 알릴 것(새벽 창 배정).
- **11-19 밤**: 새 회화 33편 Grok 작성 완료(방 4개, 경고 없음) → `new_1119.json` → 서버 원고 rev 5(9c8502e), 묶음 남·여 각 65편. 형식만 손댐: 목록 밖 감정 40개 매핑(curious→gentle 등), r0_culture_a1 「és {famoso|famosa}」. Android 빌드 20(Zealot https://apps.talkverse.uk/KtegX/521·PC 백업), iOS TestFlight 2611192228. 음성: 33편 조각 507개(공용 195·남 156·여 156, 새벽 창 1회 분량) — `data/tts/plan/` 생성만, **사용자 전편 음성 지시·11-07 실패 원인 답 전에는 3090 쓰지 말 것**(uk 날짜 배정 대기).
- **11-22 19:50 진행 페이지·3090 순서(uk 전달)**: 상태가 바뀌면 `~/bin/tv-progress pt <stop|wait|user|run|done> "<멈춘 것>" "<이유>" "<필요한 것>"` 실행(페이지 https://talkverse.uk/talkverse/review/release/). 3090 순서 「한자 → 짐프리 → 문법 → 음성」, **음성도 이제 낮에 넘김** — uk 가 「지금 시작」을 보내면 `--night` 없이 `~/.venvs/tts_zh/bin/python tools/tts/run_all.py ~/tts_work/pt 3 --refs` 로 시작, 앞 순서가 3090 을 달라면 `touch ~/tts_work/pt/PAUSE`(묶음 경계에서 멈춤). 시작·끝날 때 tv-progress run/done. TTS 대체는 이미 `dialogue_audio.dart` 84~86행.
- **11-22 18:40 PC 재가동(uk 전달)**: PAUSE 지움, screen `pt-refs-23`(11-23 01:00 2060 참고 음성)·`pt-tts-26`(11-26 01:00 3090 65편) 다시 걸음(11-25 칸은 이제 없음 — id). 3090 은 부팅 때 :8002 vLLM 이 22.9GB 를 쥐고 있을 수 있음 → night_pt.sh 가 06:30 까지 8GB 미만을 못 보면 exit 2 — 그때 uk 에 한 줄. Android 24(cdb8dd8, Zealot KtegX/564, PC 백업)·iOS 2611221839.
- **11-22 19시 사용자 「pc 작업은 잠시멈춤」(uk 전달)**: 새벽 실행기 screen `pt-refs-23`·`pt-tts-25`·`pt-tts-26` 내림 + `~/tts_work/pt/PAUSE`. **풀렸다는 전달이 오면** PAUSE 지우고 다시 건다: `screen -dmS pt-tts-26 zsh -c 'zsh tools/tts/night_pt.sh 26 0100 > ~/tts_work/pt/night_26.log 2>&1'`(참고 음성은 `--refs` 로 본 창 맨 앞에서 함께 만들어짐 — 따로 걸려면 `night_pt.sh <DD> 0100 --refs-only`). 날짜는 uk 배정대로. APK PC 백업(scp)도 멈춤 동안 건너뜀.
- **통합 앱 심사(11-23, 22개 언어 전체)**: 빈 메뉴 숨김 — 동사 활용(verbs_core.json 0개)·성·수(준비 중). 남은 미완성 표시: 언어감각 「영상 준비 중」(영상 없음), 오늘의 카드 「Minjun & Inês 스토리」 문구.
- **11-22 17:40 Grok 끝**: 장면 컷 10편×남·여 80장 → art 저장소 `~/talkverse/pt-art`(sparse, scene/pt, 6ef30ac2d) + `tools/scene_upload.py` 로 R2·D1 직접 게시(매니페스트 80, uk 원칙 「그 세션이 직접」). 언어감각 100줄 Grok → 5급(L2·L6·L7·L9·L10) 문법·한국어 오류를 지적해 Grok 이 다시 씀(옛 답 `data/review/grok/sense_old/`) → `sense_specs_1122.py apply` → 서버 원고 rev 7. 크롬 9260·터널 끔.
- **11-22 「막힌 것 각자 판단대로 완료」(사용자 → uk 전달) — 이 세션이 고른 것**:
  - 음성 = 전편 MOSS(uk 읽기 「전편 음성 여부 - TTS」). 65편 1,059조각, `tools/tts/night_pt.sh`(3090 5분 연속 8GB 미만일 때 시작·06:30 PAUSE). 11-07 실패 원인은 답이 없어 받아쓰기 기준 0.72→0.85, 옛 4편은 대사가 바뀌어 다시 만든다(옛 done → `~/tts_work/pt/done_1107_old.txt`). screen `pt-refs-23`(11-23 01:00 참고 음성 70개, 2060) · `pt-tts-25`(11-25 03:40~, 인도네시아어 다음, 못 들어가도 됨) · `pt-tts-26`(**11-26 01:00 본 창**, 첫 순서). 11-26 끝나면 「GPU 끝」+남은 조각을 **uk 와 아랍어앱**에 같이. Grok: 언어감각 = 이탈리아어 뒤 uk 「pt 시작」, 장면 컷 = 미얀마어앱 「Grok 끝」이 시작 신호 — **장면 컷 끝나면 「Grok 끝」을 uk 와 일본어앱에 같이**(다음 = 일본어 R4 컷). 11-26 00:01~00:55 는 일본어앱이 3090 사용(night_pt.sh 가 5분 연속 빌 때까지 기다림). 빌드 22(Zealot KtegX/536)·iOS 2611221549. 둘째·셋째 창은 uk 가 알려 줌. 끝날 때마다 uk 에 「GPU 끝」+남은 조각.
  - 회화 기기 음성(TTS) 연결 고침 — 빌드 21(925137f).
  - 언어감각 10급: 화면·메뉴(문법 구역 첫 칸) + 자리표시 원고(서버 원고 rev 6 에 포함, `script_publish.py` 가 `grammar/sense_course.json` 도 올림). 대사는 Grok — 초안 `tools/grok/sense_specs_1122.py`(skel→`data/review/grok/sense/`, 회차 `sense_run.sh`, 뒤 `apply` → `script_publish.py --publish`). 영상은 자리만(「영상 준비 중」, video_player 없음).
  - 단어 퀴즈: `word_quiz_screen.dart`(뜻 → 포르투갈어 4지선다, 절벽 1,919어). 단어 그림은 이미 연결돼 있음(ArtService, 매니페스트 1,792장).
  - 장면 컷 10편(남·여 20건): `tools/grok/scene_prompts.py` → `data/review/scene/*_prompt.md`, 회차 `scene_run.sh`(그림 도구 `grok_img.py`). Grok 순서 uk 요청함. 받은 그림 게시는 uk(`grok_art.py scene pt`).
  - 옛 L1 초안 5편: 지우지 않고 「이야기」 메뉴·문장 카드 DB 시드로 그대로 둔다(새 회화 65편과 겹치지 않음).
- **11-18 일본어앱 수준 맞추기(사용자 지시, 일본어앱 전달 `~/talkverse/ja/docs/RELAY_2026-11-18_ja_parity.md`)**: ① 원고 서버 받기 완료(3773146) — `ScriptSync`(`script/pt`, 대상 = 성별판 묶음 2개), 켤 때 15초, `tools/script_publish.py`·`turn_lock.py`. 서버 rev 2 = 11-10 Grok 답 15편을 Grok 문장 그대로 넣은 판(옛 rev 1 기준표로 실제 서버 받기 시험 통과). ② 남은 것: Grok 재작성 17편(uk 순서 4번 — 「pt 시작」 받으면 PC 9260, 「빠른」 모드) · 새 편 약 34편(30% 기준, 사용자 답 대기) · 언어감각 과정·단어 퀴즈 · 장면 컷 10장 · 빌드(Android+iOS) 뒤 uk 에 커밋·rev 보고. **회화 대사는 Grok 이 쓰고 Claude 는 초안·형식만(11-18 사용자 지시).**

## ▶ 다음 세션이 바로 할 일(2026-11-08 세션 종료 시점)
1. **Grok 완전 재작성**(11-09 재개 — **한자 세션 대행 중단**: 자기 크롬을 M4 에서 켜고 `ssh macmini4` 로 `/usr/bin/python3 ~/talkverse-uk/tools/grok_cookie_sync.py 9231 <자기 포트>` 로 쿠키 동기화, 도구는 M6 `~/Hanja/tools/grok_req.py`·`grok_cdp.py` 를 복사해 씀, uk 의 방·9231 탭은 건드리지 않음 — `~/logs/rc/RELAY_grok_20261109.md`, 요청문 작성법 `~/talkverse/GROK_PROMPT_GUIDE.md`): 회화 32편(`data/dialogues_src/pt-PT/*.json`)을 편마다 새 방에서 「모든 줄 새로」 → 리뷰 → `build_dialogues.py`(원본 전부 한 번에) → `make_plan.py` → REVIEW_pt 갱신 요청.
   - **Grok 은 PC 크롬에서(사용자 지시 11-09 "집필 시작 안 한 세션은 PC 에서 시작") — 전체 절차 `~/talkverse/PC_GROK_GUIDE.md`(PC 크롬은 작업 스케줄러 사용자 john, 첨부는 PC 경로)**: `~/talkverse-uk/docs/GROK_CHROME_PORTS.md` 표에 빈 포트(예: 9248)를 먼저 적고, PC 에 프로필 `D:\chrome-grok-pt` 로 예약 작업 크롬을 띄운 뒤(헝가리어 `Grok-Chrome-hu-9247` 참고) M4·M6 에서 `ssh -fN -L <포트>:127.0.0.1:<포트> pc` 터널, 쿠키는 M4 에서 `grok_cookie_sync.py 9231 <포트>`.
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

## 11-22 밤 — 토크버스 커리큘럼(전 언어 공통, `~/talkverse/CURRICULUM_SPEC.md`)
- 1998a38 첫 구현 → 75e96e8 일본어 기준(ja ceb91c3) 맞춤(service·screen·test·l10n 그대로, 대상어 tl·낱말 경계 빈칸·독음 줄) → fa96839 칩 줄 Wrap(300 폭 넘침).
- 저장 `pt_curriculum_v1`(Prefs 접두) + `today:{day,new,review}`. 포르투갈어 회화 묶음에 lemmas 없음 → 문제는 뜻 4지선다만(빈칸은 표면형 있는 줄만).
- AI 회화 작성: `custom_script_screen/service` 이식, 서버 `https://talkverse.uk/api/script/pt`, `kCustomScriptLive=false`(숨김, 켜는 것은 사용자 결정).
- 사용자 「넣어야지」 → 커리큘럼은 심사 빌드에 보이게. 빌드: Android CI 27(Zealot https://apps.talkverse.uk/KtegX/619·PC 백업), iOS TestFlight 2611222203.

## 11-23 새벽 — 문법 스텝 서버 받기(사용자 지시, uk 경유)
- 1436a9e: 스텝 목록 `assets/data/grammar/lessons.json`(지금 15칸, 개수·순서·제목은 데이터대로 — 서버 목록에서 빼면 사라지고 더하면 생김), 각 스텝 `grammar/lessonN.json` 은 ScriptSync(서버 판 우선·묶음 대체), 패턴 빈 스텝은 숨김. 내용 있는 스텝 1/15. `script_publish.py` 대상에 문법 파일 포함 → 서버 원고 rev 8.
- 빌드: Android CI 28(Zealot https://apps.talkverse.uk/KtegX/641·PC 백업), iOS TestFlight 2611222334. M6 디스크 규칙(uk): iOS 빌드는 10GB 이상·한 번에 한 세션(`pgrep xcodebuild`), 올린 뒤 build/ 바로 삭제.
- ⚠ `ios/Runner.xcodeproj/project.pbxproj` 에 이 세션 전부터 커밋 안 된 변경(130줄)이 있다 — `git checkout` 으로 되돌리지 말 것.

## 11-23 06시 — 음성 받아쓰기 검사 다시(한국어앱이 찾은 qa 캐시 버그, uk 전달)
- `tools/tts/qa.py`: 캐시 키에 대사 글·파일 생성 시각(mtime)을 넣음(ko c6433c4 와 같게) — 같은 이름으로 다시 만든 조각에 옛 점수가 남던 버그. 옛 캐시는 `~/tts_work/pt/wav/qa_1107_bak.json`.
- 서버에 올라 있던 11-07 시험 음성 102줄 중 지금 대사와 글이 같아 실제로 재생되는 것은 r2_friends_b1 20줄뿐(나머지 82줄은 대사가 바뀌어 앱이 TTS 로 읽음). 다시 채점 → 조각 21개 중 불합격 2(02_0_c 0.41, 03_0_m 파일 없음) → D1 `audio_lines` 에서 그 턴 3줄(2턴 m·f, 3턴 m)만 지움(서버 목록 102→99), `data/tts/audio_pt.json` 도 맞춤. 11-26 본 생성 때 전편 새로 만들어 다시 올라간다.
- `run_all.py` `sh()`: PC 오류문(cp949)을 utf-8 로 못 읽어 실행이 죽던 것 → `errors='replace'`.
- 참고 음성(11-23 01:00): 118개 중 잡음 기준(-60dB) 미달 47개가 3회 다시 만들어도 그대로(-56~-59dB, VoxCPM 바닥 잡음) — 기준(§5 공용)은 손대지 않고 uk 에 알림. 11-26 은 PC 에 있는 참고 음성을 그대로 쓴다.
- 11-22 19시 멈춤 때 screen 은 내렸지만 안의 night_pt.sh(25일 03:40 둘·26일 하나)가 남아 돌고 있었다 → 종료. 지금은 screen `pt-tts-26` 하나만.

## 11-23 07시 — 음성은 uk 「pt 지금 시작」 대기(고정 새벽 실행기 내림)
- uk: 3090 은 낮에도 음성, 순서 zh → ko 재생성 → es → ja R4 → **pt**. screen `pt-tts-26`(11-26 01:00) 내림 — 지금 걸린 실행기 없음.
- 「pt 지금 시작」이 오면: `screen -dmS pt-tts zsh -c '~/.venvs/tts_zh/bin/python tools/tts/run_all.py ~/tts_work/pt 3 --refs > ~/tts_work/pt/run_day.log 2>&1'`(`--night` 없음) → `tv-progress pt run`. 앞 순서가 3090 을 달라면 `touch ~/tts_work/pt/PAUSE`(묶음 경계에서 멈춤). 끝나면 「GPU 끝」+남은 조각을 uk·아랍어앱에, `tv-progress pt done`, `data/tts/audio_pt.json` 커밋.
- 참고 음성 잡음 미달 47개(-56~-59dB)는 uk 판단으로 통과(모델 바닥 잡음) — 그 목소리로 만든 본 음성의 받아쓰기·음량 불합격이 늘면 그 목소리만 다른 참고로 바꾼다. 공용 §5 문서는 그대로.
- uk(11-23 07:1x): 3090 「비었다」는 nvidia-smi 만으로 판단 금지(묶음마다 모델을 올렸다 내려 몇 초씩 576MiB 로 보임) — ① 앞 세션 「GPU 끝」/uk 「pt 지금 시작」 + ② PC `D:	ts_test\job\job.log`·`moss_jobs.json` 수정 시각 5분 넘게 멈춤, 둘 다일 때만. night_pt.sh 의 8GB 조건은 시작 신호를 받은 뒤에만.

## 11-23 낮 — 커리큘럼 §12(단계 1~5·서버 목록)
- 863dc90: 단계·편 목록 `assets/curriculum_pt.json`(rev 1, 기본 대응 R0+R1→1 … R5→5, 편 27·15·8·8·7) → 서버 `https://talkverse.uk/api/curriculum/pt` rev 가 더 높으면 받아 prefs `curriculum_plan_v1` 에 두고 씀(지금 404). 앱에 없는 id 건너뜀·빈 단계 숨김, 옛 R 저장값 → 단계, JSON 실패면 회화 레벨 동작.
- ca1c1e2: 단계 JSON 의 pass(시험 판정·문구)·daily(가볍게·보통·집중 새 편 수)도 읽음(없으면 80 / 1·2·3). prep 은 pt 없음.
- uk 에 편 목록 경로(`…/art/script/pt/pt-PT/dialogues/male.json`)와 이 JSON 을 알림 — D1 값은 uk 가 채움.
- 빌드: Android 29(KtegX/660)·30(KtegX/666, PC 백업), iOS 2611231202·2611231212. 음성은 uk 「pt 지금 시작」 대기 그대로.

## 11-23 오후 — 심사 수정·이용권 잠금
- b4ce04d 심사 점검(비속어 10개 단어표·퀴즈·시드 제외 `lib/core/word_filter.dart`, 로그인 문구·준비 안 된 제공자 숨김, 결제 문구 플랫폼별·해지 안내 Talkverse). 4f39dce 이용권 잠금(PAYWALL_SPEC, `lib/data/access.dart`): 무료 = 커리큘럼 1단계·회화 R0·R1·L1·문법 1~2스텝·언어감각 1급, 한도는 커리큘럼 JSON rev 2(free·freeSteps·freeSenseLevels). 결제 화면 스토어 가격만·불러오기 실패 시 다시 시도/닫기. 저장 pt_entitlement_v1·all_entitlement_v1. 시작 복원은 안드로이드만(iOS 는 암호 창 우려 — uk 에 알림).
- Android 32(Zealot KtegX/670, PC 백업).
- **uk(11-23 오후): M6 디스크 빠듯 → 단독 iOS 빌드(TestFlight) 당분간 멈춤.** 출시는 통합 앱(uk 가 1.0.0+15 로 묶어 올림). 단독 앱은 Android CI·Zealot 만. 4f39dce iOS 빌드는 이미 돌던 것이라 끝까지 두고 build/ 삭제.
