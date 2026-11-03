# HANDOFF — talkverse-pt (포르투갈어유니버스) · 2026-11-03

규칙은 `CLAUDE.md`(서명 §1·Zealot §8·판 §9·회화 원칙 §10), 언어앱 공통 절차는 `~/talkverse/LANG_APP_REPLICATE_PROMPT.md`.

## ⛔ 지금 걸려 있는 사용자 지시
- **콘텐츠 생성 금지**(2026-11-02, 해제 전까지): 회화·단어·예문·문법 설명·음성·그림 등 새 학습 콘텐츠를 만들거나 다시 쓰지 않는다. 허용 = 저작권·이력 정리, 버그 수정, 문서, 빌드.
- **아이콘은 talkverse.uk 세션 담당** — mipmap·AppIcon 파일을 직접 고치지 말고 요청.
- **Grok 그림 요청은 한자 세션 경유**(그림만, 글 시안은 이 세션이 직접 씀).
- **맥미니(M6) 부하**: 시뮬레이터는 쓰고 바로 `xcrun simctl shutdown`, 빌드는 `pgrep -f flutter_tools.snapshot | wc -l` 이 3 이상이면 기다렸다가.

## 상태 표
| 항목 | 상태 |
|---|---|
| 캐릭터 시안 ① | **통과**(11-03) — `data/review/art/chars_pt_v1.jpg`, 인물표 `CHARACTERS.md` |
| UX/UI 시안 ② | **통과**(11-03) — 글 `data/review/uxui/sian_pt_01.md`, 그림 `sian_pt_02.jpg`(PT-01 은 캐릭터 미반영으로 다시 그림) |
| 아이패드 빌드 ③ | 코드 `ba4007e`·`b73eec4`, 아이패드 스크린샷 9장 넘침 0·통합 테스트 통과 |
| Android | CI 빌드 **10**(b73eec4) · Zealot https://apps.talkverse.uk/KtegX/214 · PC `D:\OneDrive\app project\talkverse-pt\` |
| iOS | TestFlight 업로드 **빌드 2611030130**(11-03 01:33) — 처리 뒤 TestFlight 에 나타남. ⚠ **Sign in with Apple 권한 빠짐**(아래) |
| 로그인·결제 | 코드 `d58eb09`(Talkverse ID client_id `pt`, 상품 `com.talkverse.portugueseUniverse.lifetime`/`lang_pt`) — 잠근 화면은 아직 없음 |
| 절벽(레마) | **판별 재산정 11-03** — pt-PT R1 55·R2 83·R3 217·R4 656(상위 2,500 90.1%) / pt-BR 63·96·243·727, 자국 작품 자막 기준(`data/cliff/README.md`, `tools/pt_cliff.py`). 옛 234·403·1,134 폐기. 사이트 카드 = pt-PT 값 |
| 단어 그림 리스트 | talkversehanja `talkverse_art/words/pt.csv` = 새 레마 순위 2,500(PT·BR 합침, 구간 PT 경계, R5 = 절벽 밖, 340f9b5)·`pt_food.csv`(50), uk 세션이 D1 다시 적재 — 그림은 `GET https://auth.talkverse.uk/art/pt/manifest` |
| 저작권 정리 | 책 이름·책 파서 삭제 + 이력 재작성·강제 push 끝(11-02, 사용자 승인) |

## 이번에 만든 것(③)
- 넓은 화면(가로 720+): 레일 + 왼쪽 탭 | 오른쪽 칸(`lib/core/pane.dart`), 폰은 하단 탭·세로 고정(`main.dart` `_setOrientations`).
- 회화 리더(`lib/widgets/episode_play_pane.dart`) — 장면 컷(지금은 공유 단어 그림 → 이모지)·말풍선·캡션·대화 스크립트·재생/속도/자막 칩·편 끝 연출, 그림 카드(`dialogue_card_screen.dart`), 회화 홈(`dialogue_screen.dart`).
- 포르투갈어 칸: 독음의 「쉬」(어말 s·z)·「아웅」(비모음 ão) 표시 + ⓘ 범례(`lib/widgets/pt_reading.dart`), 자막 줄 끝 「Portugal ▾」 칩(브라질판 준비 중 안내).
- 「나」 성과 데스크(진행 탭), 학습자 이름·성별(프로필), 홈 메뉴 「회화」→ 새 리더 · 옛 화면 「회화 노트」.
- 데이터는 그대로 — 초안 `assets/data/dialogues/L1.json` 을 `lib/services/dialogue_service.dart` 가 읽어 변환.
- 화면 문구 스페인어 잔재 정리(Olá!·INICIANTE 1·Minjun & Inês·Progresso·Dia 1).
- 스크린샷 흐름: `integration_test/dialogue_pane_test.dart` + `tools/pane_shots.py`(아이패드 시뮬레이터 「pt-shots iPad Pro 11」 3F293F2F-E008-495C-AE42-B1AC2CF6F5C5, 쓴 뒤 shutdown).

## 사용자가 할 일
1. **개발자 포털 → Identifiers → `com.talkverse.portugueseUniverse` → Sign in with Apple 켜기**(Primary App ID 는 한자 앱, 이 앱은 "Group with existing primary"). 켠 뒤 `bash tools/ios_release.sh` 를 다시 돌려야 iOS 에서 Apple 로그인이 된다(지금 빌드는 구글·네이버·카카오·이메일 로그인만).
2. **평생 이용권으로 무엇을 열지** 결정(예: R2 이상 회화·단어, 브라질판) — 정해지기 전에는 잠그지 않는다.
3. 스토어 인앱 상품 등록(iOS `com.talkverse.portugueseUniverse.lifetime`, Play `lang_pt`), 데모 계정에 lang `pt` 이용권 부여는 talkverse.uk 세션에 요청.

## 다음 할 일(지시가 오면)
- 동사 활용 시트(시안 PT-01 칸 ①) — `assets/data/grammar/verbs_core.json` 이 비어 있어 미구현. 콘텐츠 금지가 풀리면 동사 데이터와 함께.
- 회화: R1~R4 재태그·성별판(남·여 파일)·pt-PT/pt-BR 폴더·반전 턴·검수(공통 원칙 https://talkverse.uk/talkverse/dialogue-rules/). 지금 초안은 남성 학습자·유럽판뿐.
- 절벽 말뭉치 한계: 자국 작품 수가 적고(PT 181편·BR 115편), pt-BR 은 브라질판 전용 자막 묶음이 아니라 포르투갈어 묶음 안의 브라질 제작 작품 — 더 정확히 하려면 브라질판 묶음을 받아 분류부터. 앱 「빈도 단어」 CSV(`lang_es_top.csv`, 헤더만)는 콘텐츠 금지가 풀리면 이 순위로 채운다.
- 공용 사전 원본 `talkverse/_update_kit/l10n/l10n_dict.dart` 에 이 앱에서 추가한 로그인·리더 문구를 옮길지(다른 앱 세션과 겹치지 않을 때).
- 작업 트리에 줄바꿈(CRLF)만 다른 파일이 남아 있다 — `git add -A` 금지, 바꾼 파일만 경로로.
