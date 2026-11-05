# CLAUDE.md — talkverselab/talkverse-pt

이 폴더에서 작업하는 모든 세션이 먼저 읽는 규칙. **빌드·배포를 건드리기 전에 반드시 확인할 것.**

## 1. 서명 (가장 자주 사고 나는 곳)

이 앱은 GitHub 릴리스로 **앱 안에서 스스로 업데이트**한다.
폰에 이미 깔린 앱과 **서명 키가 같아야만** 덮어쓰기 설치가 된다.

### 쓰는 키 — 새로 만들지 말 것

- 폰에 깔린 앱과 같은 키: 로컬 `~/.android/debug.keystore`
  (alias `androiddebugkey`, store/key 비밀번호 `android`)
- SHA-1 `9C:C4:BC:93:26:38:BE:43:A3:98:2D:F2:0B:71:C4:75:02:88:47:6B`
- 같은 키가 리포 시크릿 **`ANDROID_DEBUG_KEYSTORE_BASE64`** 에 base64로 들어 있고, CI가 이걸 복원해 서명한다.
- 로컬에서 릴리스 빌드할 때도 같은 키를 쓴다. `android/key.properties`가 없으면 이렇게 만든다:

```bash
cp ~/.android/debug.keystore android/app/signing-key.jks
printf 'storePassword=android\nkeyPassword=android\nkeyAlias=androiddebugkey\nstoreFile=signing-key.jks\n' > android/key.properties
```

### 절대 하지 말 것

- **새 키스토어를 만들지 말 것.** 서명이 바뀌면 폰에서 앱을 지웠다 다시 깔아야 하고, **학습 기록이 전부 사라진다.**
- CI의 `Restore signing key` 단계를 지우거나, `build.gradle.kts`의 release 서명을
  `signingConfigs.getByName("debug")` 로 되돌리지 말 것.
  GitHub 러너는 빌드할 때마다 debug 키를 **새로 만들어** 서명이 매번 달라진다.
  (2026-09-10에 실제로 겪은 문제 — 17개 앱 설치가 전부 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`로 실패했다.)
- `android/key.properties`, `android/app/signing-key.jks`를 커밋하지 말 것 (`.gitignore`에 있음).

### 설치가 실패하면

```
INSTALL_FAILED_UPDATE_INCOMPATIBLE: signatures do not match
```

→ 앱을 지우지 말고 **서명부터 확인**한다:

```bash
apksigner verify --print-certs <apk> | grep SHA-1   # 9cc4bc932638be43a3982df20b71c4750288476b 여야 한다
```

## 폰에 설치할 때 (PC에서 케이블로)

폰에 **듀얼 메신저 프로필(user 95)** 과 보안 폴더(user 150)가 있다. `adb install` 은 프로필을 지정하지 않으면
**모든 프로필에 설치**해서 앱 아이콘이 두 개(파란 말풍선 배지 달린 복제본)가 생긴다. 반드시 기본 프로필만 지정한다:

```bash
adb -s R3CY20HDN2K install --user 0 -r <apk>
```

(2026-09-11에 24개 앱이 전부 두 개씩 깔려 있던 것을 정리함. 앱 안의 「앱 업데이트」로 설치하면 이 문제는 생기지 않는다.)

## 2. 배포 흐름

- `master`(또는 기본 브랜치) 푸시 → GitHub Actions(`.github/workflows/release.yml`)가
  서명된 APK와 `latest.json`을 `latest` 릴리스에 올린다.
- **빌드 번호 = 워크플로 실행 번호**(`--build-number=${{ github.run_number }}`).
  앱은 자기 빌드 번호와 `latest.json`의 `build`를 견주어 새 빌드를 판단한다.
  로컬 `flutter build apk`로 만든 APK는 pubspec의 작은 번호를 써서 앱이 늘 "새 빌드 있음"으로 보인다 — 정상.
- `**.md`만 고친 푸시는 빌드하지 않는다(`paths-ignore`). 헛된 업데이트 알림 방지.
- **폰 업데이트**: 앱 → 설정(프로필) 화면 → **「앱 업데이트」** → 내려받아 설치. 케이블·adb 불필요.
  첫 설치 때 「출처를 알 수 없는 앱 설치」 허용이 한 번 필요하다(안드로이드 강제).

관련 파일: `lib/services/update_service.dart`, `lib/screens/update_screen.dart`,
`android/app/src/main/kotlin/**/MainActivity.kt`(설치 메서드 채널),
`android/app/src/main/res/xml/file_paths.xml`, `.github/workflows/release.yml`

구현 안내서: https://github.com/talkverselab/talkverse-th/blob/master/docs/in-app-update-via-github.md

## 3. 리포

- 이름은 **`talkverselab/talkverse-<언어코드>`** 로 통일(2026-09-10). 옛 이름(`pt-universe` 등)은 리다이렉트되지만
  remote는 새 이름으로 바꿔 둘 것: `git remote set-url origin https://github.com/talkverselab/talkverse-pt.git`
- **공개(PUBLIC) 저장소**다. 앱이 토큰 없이 APK를 받으려면 공개여야 한다.
- 다운로드 허브: https://github.com/talkverselab/talkverse-releases

## 4. 공개 저장소라서 지킬 것

- **출처를 드러내지 말 것.** 자막·말뭉치 제공처 이름(스트리밍 서비스, 공개 자막 데이터셋 등), 책 이름·쪽수,
  드라마·영화 제목을 코드·에셋·문서·파일명·화면 문구 어디에도 남기지 않는다.
- 저작권 있는 원문(자막 대본, 원서 전사)을 리포에 넣지 않는다. 단어·빈도 통계만 쓰고 문장은 자체 제작한다.
- 새 파일을 추가할 때 위 두 가지를 먼저 확인할 것. 한 번 공개 커밋되면 히스토리에 남는다.

## 화면 구성 (2026-09-11 — zh 기준 이식)

홈 메뉴: 회화 · **문법** · **문장 카드** · **말하기** · **청크 검색** · 동사 활용 · 단어 · 표현 · 빈도 단어 · 성·수(준비중) · 발음(준비중) · **단어 카드**

새로 들어온 6개는 `talkverse/_update_kit/port6/` 의 공용 키트에서 왔다. **8개 앱(de·es·fa·fr·hi·hu·it·pt·tr)이 같은 코드**를 쓰므로,
고칠 일이 있으면 키트를 고치고 `port6_apply.py` 로 다시 배포하는 편이 낫다(개별 수정은 다음 배포에서 덮인다).

| 화면 | 파일 | 데이터 |
|---|---|---|
| 문법 강의·테스트 | `grammar_lesson_screen.dart` / `grammar_test_screen.dart` | `assets/data/grammar/lesson*.json` (`patterns[].examples[] = {tl, rd, ko}`) |
| 문장 카드 | `sentence_flashcard_screen.dart` | DB `turns` + `user_progress` |
| 말하기 연습 | `speaking_practice_screen.dart`, `services/speech_service.dart`, `services/speak_match.dart` | DB `turns`, 판정은 단어 단위 LCS ≥ 0.7 |
| 청크 검색 | `chunk_search_screen.dart`, `services/chunk_index_service.dart` | 회화 턴 + 문법 예문에서 1~3단어 청크 색인 |
| 단어 카드 | `word_flashcard_screen.dart` | `assets/data/vocab/travel_words.json` (`{ko, tx, rd, ic}`) |

- **대화 턴에 한글 독음 `rd` 칸**이 있다(DB 스키마 v2, 시드 키 `db_seeded_v2`). 대화·문법·단어 모두 독음을 넣고,
  화면에서는 `KoReadingText` 로 전역 독음 토글에 연동한다.
- 대상어 문장 칸 이름은 템플릿 그대로 `es` 다(스페인어 앱에서 복제된 흔적). 언어와 무관하게 "대상어"로 읽으면 된다.
- **콘텐츠는 초안**이다 — 회화 5편 × 8턴, 문법 10패턴 × 예문 3, 단어 40개. 자체 제작이며 원문·출처를 쓰지 않는다.
  내용을 늘리려면 `_update_kit/content/<언어코드>.py` 를 고치고 `build_content.py` 로 다시 만든다.
- 말하기 연습은 `RECORD_AUDIO` 권한과 기기의 음성 인식(Google 앱)이 필요하다. 인식 언어는 `TtsService.locale` 을 따른다.

## 5. 표시 언어 (한국어 / English / 日本語 / 中文) — 2026-09-12

- 프로필 · 설정 → 「언어 / Language」 를 탭할 때마다 한국어 → English → 日本語 → 中文 순으로 바뀐다.
  `AppLangPrefs`(`lib/core/l10n.dart`)가 값을 들고 있고, 바뀌면 `main.dart` 의 `MaterialApp` key 가 바뀌어
  앱 전체가 새로 그려진다(홈으로 돌아감).
- **UI 문구는 `tr('한국어')` / `trf('{0}개', [n])` 로 감싼다.** 번역은 `lib/core/l10n_dict.dart` 의
  `kDictEn` / `kDictJa` / `kDictZh` 에서 찾고, 없으면 한국어가 그대로 나온다.
  새 문구를 추가하면 세 사전에 한 줄씩 넣을 것. 키는 코드의 한국어 문자열 그대로(보간은 `{0},{1}` 템플릿).
- `tr()` 은 const 가 아니다 — `const Text(tr(...))` 처럼 쓰면 컴파일 오류. 그 위젯의 `const` 를 뺀다.
  enum 생성자·`static const`·`case` 패턴에는 못 쓴다(한국어를 두고 getter 에서 `tr()`).
- **회화·단어·문법 콘텐츠(뜻·번역·설명)는 번역 대상이 아니다** — 화면 문구(메뉴·버튼·안내)만 바뀐다.
- 사전은 12개 언어 앱이 공용(`_update_kit/l10n/l10n_dict.dart` 원본). 다른 앱에서 고친 번역이 있으면 원본도 같이 고칠 것.

## 6. 갤럭시·아이폰 공용 인터페이스 — 2026-09-12

- 플랫폼 판단은 `lib/core/platform.dart` 의 `isIOS` / `isAndroid` 만 쓴다(`dart:io` Platform 직접 호출 금지 — 웹·테스트에서 깨짐).
- **화면 아래 고정 버튼·목록 바닥 여백은 `bottomInset(context)` 를 더한다**
  (`EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset(context))`). 아이폰 홈 인디케이터(34pt)·갤럭시 제스처 바에 가려지지 않게.
  새 화면을 만들 때도 같은 규칙.
- 글자 확대 상한 1.2배(`main.dart` builder) — 아이폰 Dynamic Type 로 타일이 깨지는 것 방지.
- iOS 오디오: `TtsService` 와 `AudioService` 가 iOS 에서 재생 카테고리(playback)를 잡는다 — 무음 스위치에서도 소리가 난다. 지우지 말 것.
- 「앱 업데이트」 타일은 Android 전용(APK 설치 채널). iOS 는 TestFlight 안내 타일이 대신 나온다. `UpdateService.install` 은 Android 에서만 호출.

## 7. iOS 빌드 — 초안 (2026-09-12)

- `.github/workflows/ios-build.yml`: 푸시마다 GitHub macOS 러너가 **서명 없는** IPA 를 아티팩트로 올린다(동작 확인용).
- `.github/workflows/ios-testflight.yml`: 리포 Variables `IOS_TESTFLIGHT_ENABLED=true` 일 때만 돈다.
  Apple Developer Program(유료) 활성화 → App Store Connect API 키 → `tools/ios/make_ios_cert.py` 로 인증서·시크릿 생성 → 시크릿 등록.
  절차: `docs/ios-build-and-testflight.md`.
- `ios/Runner/Info.plist` 에 마이크·음성 인식 권한 문구가 있다(말하기 연습). 지우면 iOS 에서 크래시.
- `release.yml`(Android) 은 `ios/**`·`docs/**`·`tools/**` 만 바뀐 푸시는 건너뛴다.

## 8. Zealot 무선 설치 (apps.talkverse.uk) — 2026-10-11

- **Zealot 앱이름: 포르투갈어유니버스** (앱 표시 이름 그대로. 2026-10-11 정함 — 이 리포에는 그전에 올린 기록이 없다. 바꾸면 Zealot 에 다른 앱이 새로 생긴다.)
- 올리기: `bash tools/zealot_push.sh ["변경 내용 한 줄"]` — `build/app/outputs/flutter-apk/` 의 가장 최근 release APK 를
  `~/bin/zealot-upload` 로 올린다(빌드는 하지 않음. 변경 내용을 안 주면 최근 커밋 제목). 서명 SHA-1 이 §1 값과 다르면 올리지 않는다.
- **덮어 설치 상태(2026-10-11 확인)**: 서명 = `android/key.properties` + `android/app/signing-key.jks` 가 이미 있고 SHA-1 `9C:C4:…:47:6B`(§1 과 같은 키) —
  단 **맥미니의 `~/.android/debug.keystore` 는 다른 키(`BE:B3:…:0B:81`)** 라서 §1 의 `cp ~/.android/debug.keystore …` 를 맥미니에서 다시 실행하면 안 된다.
  버전 코드 = `pubspec.yaml` `0.1.0+1` 인데 CI 릴리스는 빌드 5(`latest.json`) → 로컬 빌드는 `--build-number` 를 폰에 깔린 번호보다 크게 줘야 덮어 설치된다.
- **2026-10-26 첫 업로드(빌드 6·7)는 CI 가 만든 APK 를 그대로 올렸다** — `gh release download latest -R talkverselab/talkverse-pt -p '*.apk'` → `apksigner` 로 SHA-1 확인 → `~/bin/zealot-upload`. 빌드 번호가 앱 안 업데이트(`latest.json`)와 같아 번호가 꼬이지 않으므로 이 방법을 기본으로 쓴다.
  M6 의 `apksigner` = `~/Library/Android/sdk/build-tools/36.0.0/apksigner`, M6 의 `~/.android/debug.keystore` 도 §1 과 다른 키(`72:08:…:E7:BB`) — 여기서도 §1 의 `cp` 를 하지 말 것.
- 서명 키 백업: Doppler `keys/prd` 의 `SIGNKEY_*`(내용이 같은 다른 앱 이름으로 저장됨, `SIGNKEY_INDEX` 참조) + PC `D:\backup\signing_keys\talkverse-pt\`. APK 백업 PC `D:\OneDrive\app project\talkverse-pt\talkverse-pt-latest.apk`.

## 9. 유럽판·브라질판 — 한 앱 안 판 선택 (2026-11-02 사용자 결정)

- 포르투갈어는 **유럽판(pt-PT)과 브라질판(pt-BR)을 둘 다 따로** 만든다. 코퍼스·빈도표·절벽구간(R1~R4)·구간별 단어/예문/독음·TTS 음색은 **판마다 따로** 산출·관리한다(talkverse.uk /cliff/ 도 두 판을 따로 표기).
- 구조: **앱은 하나** — 번들 ID `com.talkverse.portugueseUniverse`·서명 키·Zealot 앱이름·아이콘·로그인 client_id `pt` 그대로. 처음 실행 때와 설정에서 「포르투갈 / 브라질」을 고르고, 데이터는 `assets/data/pt-PT/`·`assets/data/pt-BR/` 로 나누며 학습 기록도 판별로 따로 둔다(공용 학습 DB 에 올릴 때는 `lang='pt'` + 판 구분 칸).
- 지금 들어 있는 초안 콘텐츠(회화 5편·문법 10패턴·단어 40, 독음 포함)는 **유럽판**이다.
- 아직 구현 전 — 판 선택 화면·데이터 폴더 분리·`TtsService.locale` 판별 전환은 다음 작업.

## 10. 회화 원칙 — 공통 원칙 링크 + 포르투갈어 특이점 (2026-11-02)

- **공통 원칙(SSOT)**: https://talkverse.uk/talkverse/dialogue-rules/ — 레벨 = 절벽 R1~R4(L 폐지, 기준 https://talkverse.uk/cliff/18/), 턴 수 R1 6~8 · R2 8~12 · R3·R4 12~16, 모든 턴 한글 독음 `rd` 필수, 번역·설명 한국어, 편마다 반전 1회, 수위 12+, 검수 = 자동 검사 + Grok·Gemini 교차. 회화를 만들거나 고칠 때 이 페이지를 따른다. 아래는 포르투갈어만의 것.
- **반전 비율·그림(2026-11-03 사용자 지시, 공통 원칙 §9)**: 카오스 30% 이상 · 연애·플러팅 편마다 심쿵 한 줄(여성 주도 편 더 많이) · 편마다 `twist_type`(chaos·slip·reveal·emotion·ignore) · 새 편은 왕초보·초급 위주 · 장면 그림 = A·B 쌍 1컷, 말풍선·글자 없음, 인물 기준 그림(`CHARACTERS.md`·`data/review/art/chars_pt_v1.jpg`) 첨부. Grok 을 직접 쓸 때는 M4 Chrome(쿠키 복사는 M4 안에서, `~/talkverse/GROK_M4_LOGIN.md`) — 사용자 지시가 있을 때만 켜고, 탭은 건마다 닫고 끝나면 Chrome 도 끈다. 요청문 작성법(편마다 새 방·재작성은 「모든 줄 새로」·받은 답은 리뷰·컷마다 한 요청) = `~/talkverse/GROK_PROMPT_GUIDE.md`, 틀 파일 `~/talkverse/zh/tools/`.
- **기본 변이 = 유럽 포르투갈어(pt-PT)**. 브라질판(pt-BR)은 별도 파일(`assets/data/pt-PT/`·`pt-BR/`, §9). 한 턴 안에 두 판을 병기하지 않는다. 지금 초안(`assets/data/dialogues/L1.json`)은 pt-PT 이고 아직 L1 태그 — R 로 다시 태그할 것.
- **턴 길이(제안 — 검사기에 넣을 값)**: R1 3~10단어(1단어 단답 금지) · R2 ≤14단어 · R3·R4 ≤20단어, 한 턴 1~2문장.
- **말투**: 친구·연인 = tu(동사 2인칭 단수), 낯선 사람·가게·일 = 3인칭 존칭(o senhor / a senhora, 동사 3인칭) — 유럽판은 você 를 거의 쓰지 않는다. pt-BR 은 você 가 기본.
- **학습자 성별 — 성별판을 따로 만든다(2026-11-03 사용자 결정)**: 화자 자신을 가리키는 형용사·인사(obrigado/obrigada, cansado/cansada, contente…)가 성별로 바뀌므로 학습자(화자 A) 남·여 두 판의 회화 파일을 따로 둔다(규칙 치환이 아니라 판별 파일, 공통 원칙 §6). 프로필 성별로 판을 고른다. 판 구분은 pt-PT/pt-BR 변이 폴더 안에서 다시 남·여로 나눈다. 지금 초안(L1)은 남성 학습자판뿐이고, 여성판은 회화 작성 금지가 풀린 뒤 만든다.
- **독음 표기표(pt-PT, 지금 초안에서 쓰는 규칙)** — 스크립트 검사 기준:

| 철자·자리 | 독음 | 예 |
|---|---|---|
| 무성 p·t·c(k)·qu | 된소리 ㅃ·ㄸ·ㄲ | por → 뽀르, tu → 뚜, café → 까페 |
| 음절 끝·자음 앞 s·z | 쉬 (유성음 앞 쥬) | Lisboa → 리쉬보아, mesmo → 메쥬무 |
| 단어 첫 r·rr | ㅎ | Rossio → 호씨우 |
| 강세 없는 어말 o | 우 | obrigado → 오브리가두 |
| 강세 없는 e | 약화 「으」 또는 탈락 | de → 드, hoje → 오즈, cidade → 씨다드 |
| ão / õe | 아웅 / 오잉 | então → 엔따웅 |
| em·en(어말·자음 앞) | 앵/엥 | em → 앵, sempre → 셈프르 |
| lh / nh | ㄹ리 / 니·뉴 | venho → 벵유 |
| ch·x(대개) / j·g(e,i) | 샤 계열 / 즈 계열 | chá → 샤, já → 자 |

- **템플릿 잔재(공통 원칙 §12 — 정리할 것)**: 대상어 칸 이름 `es`, 홈 인사 「¡Hola!」(→ Olá!), 오늘의 학습 카드 「PRINCIPIANTE 1」·「Minjun & Lucía 스토리」(실제 인물은 Inês). 회화 데이터 변환기(공통 모양 `{num, speaker, tl, rd, ko, note, tags, twist, flags}`)는 내보낼 때 만든다.
