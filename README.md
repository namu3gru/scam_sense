# ScamSense (스캠센스) — 누르기 전에, 한 번 더 확인

수상한 문자·이메일·링크·전화 내용·스크린샷을 붙여 넣으면 **빨강(사기) / 노랑(의심) / 초록(안전해 보임)** 신호등으로 쉬운 말 판정을 해 주는 iPhone 앱입니다. 해야 할 일, "이미 눌렀다면?" 대처법, 신고처, 그리고 **가족에게 바로 보내는 경고 메시지**까지 한 화면에 보여 줍니다. 매일 5문제 "사기 찾기 퀴즈"로 습관을 만듭니다.

- 번들 ID: `com.namu3gru.ScamSense` · 카테고리: 유틸리티 · 표시 이름: ScamSense / 스캠센스
- 백엔드 슬러그: `scam` (apps_api) · iOS 18.0+ · SwiftUI · 외부 패키지 없음
- 언어: 영어(미국 기본) + 한국어

---

## 1. 컨셉 & 왜 팔리는가

**타깃**
1. 사기를 걱정하는 50~80대 본인 (큰 글자, 쉬운 말, 큰 버튼 필요)
2. 부모님·조부모님이 걱정되는 30~50대 자녀 → **실제 결제자**. "부모님 지키기"가 구매 동기.
3. 가족 단톡방에서 서로 챙기는 가족

**트렌드**
- 미국 FTC 신고 사기 피해액이 2024년 125억 달러를 넘었고 계속 증가 중. 통행료(톨)·택배 스미싱, AI 목소리 복제 "손주 사고" 전화, 돼지도살(pig-butchering) 투자 사기가 급증.
- 한국: 택배·청첩장·부고 스미싱, 검찰·금감원 사칭, 가족 사칭 메신저 피싱, 대출·리딩방 사기가 일상화.
- 사람들은 "누르기 전에 빠른 2차 의견"을 원함 → 붙여 넣기 한 번으로 해결.

**경쟁 앱과 차별점**
| 경쟁 | 약점 | 스캠센스 |
|---|---|---|
| Norton Genie, Bitdefender Scamio, Trend Micro ScamCheck, McAfee | 보안회사 앱 끼워팔기, 계정 요구, 젊은 사용자 중심 UI | 계정 없음, 추적 없음, **큰 글자 모드**와 신호등 UI로 어르신 친화 |
| 경찰청 사이버캅, 후후/T전화 | 번호·계좌 조회 위주, 문자 내용 해석 없음 | 문장·링크·스크린샷 내용을 해석해 "왜" 사기인지 설명 |
| 일반 AI 챗봇 | 매번 질문을 잘 써야 함, 신고처·대처법 들쭉날쭉 | 국가별 신고처(FTC/7726, 112/118/1332) 탭 한 번 연결, "이미 눌렀다면?" 단계 |

추가 무기: **가족에게 경고 보내기**(바이럴), **매일 퀴즈+연속 기록**(리텐션), 공유용 점수 카드(바이럴).

---

## 2. 수익화

**구독 그룹 "ScamSense Pro"**
| 상품 ID | 기간 | 미국 | 한국 | 비고 |
|---|---|---|---|---|
| `com.namu3gru.ScamSense.pro.yearly` | 1년 | $29.99 | ₩44,000 | **7일 무료 체험**, 기본 선택, "SAVE 49%" 표시 (월 $2.50 / 주 $0.58) |
| `com.namu3gru.ScamSense.pro.monthly` | 1개월 | $4.99 | ₩6,900 | |

**무료 vs Pro**
- 무료: AI 확인 **주 3회 (서버에서 강제)**, 퀴즈·배우기 무제한, 기록 최근 10개, 가족 경고 템플릿 2개
- Pro: 무제한 확인(공정 사용 하루 50회, 서버 강제), 전체 기록, 가족 경고 템플릿 8개 전부

**전환 장치**
- 온보딩에서 내장 샘플로 "아하" 결과를 먼저 보여 준 뒤 소프트 페이월(닫기 가능)
- 무료 3회 소진 시(서버 402 `free_limit`) 페이월 → 구매하면 그 자리에서 확인 자동 재시도
- 2번째 확인 이후 홈 화면에 부드러운 "온 가족을 지키세요" 배너
- 기록 10개 초과분 잠금, 가족 경고 템플릿 6개 잠금 → Pro 유도
- 카피: "One scam can cost thousands. Protect your family for less than $3/month." (한국: "사기 한 번이면 큰돈을 잃어요. 한 달 ₩3,667로 가족을 지키세요.")
- 예상: 자녀가 부모님 대신 결제하는 패턴 → 연간 플랜 비중 높음. 체험 시작률 8~12%, 체험→유료 35~45%를 목표로 A/B 테스트 권장.

---

## 3. 기능 목록

- **온보딩**: 누구를 지키나요(나/부모님/가족) → 글자 크기(큰 글자 모드) → 내장 샘플로 체험(서버 호출 없음) → 개인정보 동의(5.1.2) → 소프트 페이월
- **확인(홈)**: 붙여넣기 버튼(시스템 PasteButton: 누를 때만 클립보드 읽음, "붙여넣기 허용" 팝업 없음), 스크린샷(PhotosPicker, 사진 권한 불필요), 받은 경로 칩(문자/이메일/전화/SNS·메신저/웹사이트/중고거래), 추가 설명, 이번 주 남은 무료 횟수, 국가별 신고 안내
- **대기 화면**: 레이더 애니메이션 + 단계별 메시지("보낸 사람 확인 중…", "링크 살펴보는 중…", "알려진 사기와 비교 중…"), 진행 바, 안전 팁 순환
- **결과**: 전체 폭 신호등 헤더 + 0~100 위험 게이지(애니메이션), 한 줄 결론, 사기 유형, 위험 신호(아이콘+설명), 안심 신호, 번호 매긴 "이렇게 하세요", "이미 눌렀거나 돈을 보냈나요?" 펼치기, 신고처 카드(공식 사이트는 Safari로, 7726은 문자, 112/118/1332는 전화. 목록에 없는 사이트는 확인 후 열기), **가족에게 경고하기** 공유, 면책 문구
- **기록**: 기기에만 저장(JSON, 파일 보호), 판정 필터 칩, 다시 열기, 스와이프 삭제
- **사기 찾기 퀴즈(무료)**: 영어 61문항(미국 상황) + 한국어 61문항(한국 상황), 사기 37 : 정상 24. 문자 말풍선/이메일/DM/음성사서함/중고거래 채팅/웹 팝업으로 실감 나게 렌더링. 하루 5문제, 연속 기록, 점수, 레벨(Rookie → Scam Spotter → Fraud Fighter → Scam Sensei / 새내기 → 사기 감별사 → 사기 파이터 → 스캠 마스터), 점수 공유 카드(1080×1350), 연습 모드, 첫 완료 시 매일 알림 제안
- **배우기**: 언어별 사기 유형 카드 12개(수법/알아채는 법/대처법), 가족과 공유
- **가족**: "부모님 지키기" 안전 습관 8개, 부모님께 보내는 추천 메시지, 바로 보내는 경고 템플릿(Pro)
- **설정**: 국가(미국/한국), 언어(iPhone 설정 따름), 큰 글자 모드, 매일 퀴즈 알림(시간 선택), 구독 상태/업그레이드/구매 복원/구독 관리, AI 전송 정보 보기/동의 철회, 개인정보 처리방침, 이용약관, 고객 지원, 버전
- 접근성: 최소 44pt 터치 영역, 큰 버튼(58pt), 고대비 색, VoiceOver 라벨, Dynamic Type(accessibility3까지) + 큰 글자 모드, 라이트/다크, 햅틱
- 리뷰 요청: 3번째 확인 완료 또는 퀴즈 4/5 이상 후, 최대 4개월에 1번

---

## 4. 구조 / 파일 맵

```
scam_sense/
├─ README.md
├─ .gitignore                      (ios/build/ 제외)
├─ design/
│   ├─ make_icon.swift             앱 아이콘(1024, 알파 없음) 생성 스크립트
│   ├─ ko_strings.py               한국어 번역표
│   └─ make_strings.py             빌드에서 추출한 키로 Localizable.xcstrings 생성
├─ screenshots/                    시뮬레이터 스크린샷 (아래 목록)
└─ ios/
    ├─ ScamSense.xcodeproj         (공용 생성기로 생성 — 직접 수정 금지)
    ├─ Info.plist
    ├─ Products.storekit           구독 그룹 + en/ko 로컬라이즈 + 연간 7일 무료 체험
    └─ ScamSense/
        ├─ ScamSenseApp.swift      앱 진입점, RootView, 탭
        ├─ Core/
        │   ├─ AppConfig.swift     ★ 앱 토큰 / 서버 주소 / 상품 ID / 링크
        │   ├─ DeviceID.swift      키체인 UUID (X-Device-ID)
        │   ├─ APIClient.swift     /status /entitlement /run, 401/402/413/422/502 처리
        │   ├─ Models.swift        ScamResult(서버 스키마), QuotaStatus, 채널, 국가, 기록
        │   ├─ AppModel.swift      앱 상태, 설정, 테스트 훅(launch args)
        │   ├─ SubscriptionStore.swift  StoreKit 2 + 가격 폴백표
        │   ├─ HistoryStore.swift  기록 JSON (Application Support)
        │   ├─ QuizStore.swift     퀴즈 진행·연속 기록·레벨
        │   ├─ Content.swift       번들 JSON 로더
        │   ├─ Reminders.swift     매일 퀴즈 로컬 알림
        │   ├─ ImageTools.swift    1280px / JPEG 0.7 / 1.5MB 이하
        │   └─ Theme.swift         색상·버튼·카드·로고
        ├─ Views/                  Onboarding, Check, CheckRun(대기·결과·에러), Result,
        │                          History, QuizHome, QuizPlay, MessageMock(+공유카드),
        │                          Learn, Family, Settings, Paywall, Consent
        ├─ Content/                quiz_en/ko, learn_en/ko, family_en/ko, sample_en/ko,
        │                          demo_history_en/ko (스크린샷용)
        ├─ Assets.xcassets         AppIcon, AccentColor
        ├─ Localizable.xcstrings   285개 키, 한국어 100%
        ├─ InfoPlist.xcstrings     표시 이름 ScamSense / 스캠센스
        └─ PrivacyInfo.xcprivacy   추적 없음, UserDefaults CA92.1, 수집 데이터 선언
apps_api/site/scam/                privacy.html, terms.html, support.html (en + ko)
```

**서버 계약 (apps_api/apps/scam.py, 변경 없음)**
- 요청: `{"text", "image_base64", "channel": sms|email|call|social|website|marketplace|unknown, "context", "language": en|ko, "country": US|KR}`
- 응답 `result`: verdict / risk_score / scam_type / headline / red_flags[{flag,why}] / safe_signs / what_to_do / if_already_acted / report_to[{name,how}] / family_message
- 모든 요청에 `X-App-Token`, `X-Device-ID`. 구매·복원·실행 시 `Transaction.currentEntitlements`의 `jwsRepresentation`을 `/entitlement`로 전송. 남은 횟수는 항상 서버 값 표시.
- 메시지 속 링크는 앱이 절대 열지 않음(일반 텍스트로만 표시).

---

## 5. 실행 & 테스트 방법 (Xcode 처음이어도 OK)

### ★ 출시 전 꼭 할 일: 앱 토큰 넣기
`ios/ScamSense/Core/AppConfig.swift` 파일을 열고
```swift
static let appToken = "REPLACE_WITH_APP_TOKEN"
```
의 따옴표 안을 서버 `apps_api/.env`의 `APP_TOKEN` 값으로 바꿉니다. (App Store ID가 생기면 같은 파일의 `appStoreID`에 숫자를 넣으면 가족 초대 메시지에 링크가 붙습니다.)

### Xcode에서 실행
1. Finder에서 `scam_sense/ios/ScamSense.xcodeproj` 더블클릭
2. 상단 기기 선택에서 원하는 iPhone 시뮬레이터 또는 내 iPhone 선택
3. ▶ (Run) 클릭. Xcode에서 실행하면 `Products.storekit`이 연결되어 **구독 구매도 테스트**할 수 있습니다.

### 로컬 목(mock) 서버로 전체 흐름 테스트 (API 비용 0원)
```bash
cd /Users/namu3gru/Claude/shorts/apps_api
AI_MOCK=1 APP_TOKEN=dev APPS_DB=/Users/namu3gru/Claude/shorts/scam_sense/ios/build/mock.db HOST=127.0.0.1 PORT=8112 .venv/bin/python server.py
```
Xcode: Product › Scheme › Edit Scheme › Run › Arguments에 `-apiBaseURL http://127.0.0.1:8112 -apiToken dev` 추가.
→ 확인 3번은 샘플 결과, 4번째는 402 → 페이월이 뜨는 것까지 확인 가능.
(Xcode 로컬 구매를 서버가 Pro로 인정하게 하려면 서버 실행 시 `ALLOW_XCODE_PURCHASES=1` 추가 — 개발용만!)

### 명령줄 빌드
```bash
cd scam_sense/ios
xcodebuild -project ScamSense.xcodeproj -scheme ScamSense -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -derivedDataPath build build
xcodebuild -project ScamSense.xcodeproj -scheme ScamSense -configuration Release -destination 'generic/platform=iOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```
두 빌드 모두 경고 0개로 성공 확인함.

### 스크린샷용 테스트 훅 (launch arguments)
| 인자 | 효과 |
|---|---|
| `-uiReset YES` | 설정·기록·퀴즈 초기화 |
| `-uiOnboarded YES/NO`, `-uiOnboardingStep 0~5`, `-uiDemoResult YES` | 온보딩 건너뛰기 / 특정 단계 / 체험 결과 표시 |
| `-uiConsent YES` | AI 동의 완료 상태 |
| `-uiDemo YES` | 예시 기록 4개 + 퀴즈 진행(380점, 6일 연속) |
| `-uiScreen` | `check, waiting, result, quiz, quizHome, quizAnswered, quizResult, history, historyDetail, paywall, settings, learn, learnDetail, family, consent` |
| `-uiPrefill "문구"`, `-uiAutoCheck YES`, `-uiMinWait 20` | 입력 채우기 / 자동 확인 / 대기 화면 최소 표시 시간 |
| `-uiLargeText YES`, `-uiCountry KR`, `-uiResultScroll YES`, `-uiExportShareCard YES` | 큰 글자 / 국가 / 결과 아래쪽으로 스크롤 / 공유 카드 PNG를 Documents에 저장 |
| `-AppleLanguages "(ko)" -AppleLocale ko_KR` | 한국어로 실행 |

### 문자열 다시 만들기 (문구를 바꿨을 때)
빌드 한 번 → `python3 design/make_strings.py` → 빠진 번역을 `design/ko_strings.py`에 추가 → 다시 실행.

---

## 6. 스크린샷 (`screenshots/`, iPhone Air 시뮬레이터, 1260×2736)
01 온보딩 첫 화면 · 02 대상 선택 · 03 내장 샘플 체험 결과 · 04 개인정보 동의 · 05 페이월 · 06 확인(홈) · 07 대기 · 08 결과 · 09 결과(대처법·신고처) · 10 기록 · 11 기록 상세 · 12 402 후 페이월 · 13 퀴즈 홈 · 14 퀴즈 문제 · 15 퀴즈 정답 해설 · 16 퀴즈 결과 · 17 공유 카드(1080×1350) · 18 설정 · 19 큰 글자 모드 · 20 배우기 · 21 가족 · 22~24 한국어(홈/퀴즈/페이월) · 25~26 다크 모드

---

## 7. App Store 메타데이터

### English (U.S.)
- **Name (28/30):** ScamSense: Scam Text Checker
- **Subtitle (29/30):** Check texts & links for scams
- **Keywords (95/100):** `scam,detector,fraud,phishing,smishing,spam,text,link,checker,toll,elderly,parents,family,safety`
- **Promotional text:** Got a text that feels off? Paste it and get a clear red / amber / green answer in plain words, what to do next, and a one-tap warning for your family.
- **Description:**
```
Is it a scam? Find out before you tap.

Scam texts, fake toll and package alerts, "your account is locked" emails, AI voice-clone "grandkid in trouble" calls, crypto "wrong number" chats — they're everywhere, and one tap can cost thousands. ScamSense gives you a calm, plain-language second opinion in seconds.

HOW IT WORKS
• Paste a text, email, link or phone number — or add a screenshot
• Get a traffic-light verdict: red (scam), amber (suspicious) or green (likely safe), with a 0–100 risk score
• See the red flags explained in simple words
• Follow clear steps: what to do now, and what to do if you already clicked or paid
• Report it in one tap (FTC, forward to 7726, and more)
• Warn your family with a ready-made message

BUILT FOR EVERYONE — ESPECIALLY OUR PARENTS
• Large text mode, big buttons, high contrast and VoiceOver support
• No account, no ads, no tracking
• ScamSense never opens links from your messages

SPOT THE SCAM — FREE DAILY QUIZ
Five realistic messages a day. Can you tell the scam from the real thing? Keep your streak, level up from Rookie to Scam Sensei, and share your score.

LEARN THE TRICKS
12 short guides to today's biggest scams: toll and package texts, bank "safe account" calls, grandparent scams, romance and investment scams, job scams, marketplace tricks and more.

PROTECT A PARENT
Family safety habits (like a family safe word) and an invite message to help your parents get set up.

FREE: 3 checks every week, unlimited quiz and learning.
SCAMSENSE PRO: unlimited checks (fair use 50/day), full history and ready-to-send family warnings. Monthly or yearly with a 7-day free trial.

Payment is charged to your Apple Account at confirmation of purchase (after the free trial, if any). Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in your App Store account settings.

ScamSense uses AI (Anthropic's Claude) and can be wrong. When in doubt, contact the company directly using its official number.

Privacy: https://scamsense.namu3gru.com/privacy
Terms: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

### 한국어
- **이름 (15/30):** 스캠센스 - 사기 문자 확인
- **부제 (16/30):** 누르기 전에 스미싱·피싱 확인
- **키워드 (63/100):** `사기,스미싱,피싱,보이스피싱,메신저피싱,문자,링크,검사,택배,부고,청첩장,부모님,사기탐지,스팸,안전,확인,대출사기`
- **프로모션 텍스트:** 수상한 문자, 누르기 전에 붙여 넣으세요. 빨강·노랑·초록 신호등으로 쉽게 알려주고, 대처법과 가족에게 보낼 경고 메시지까지 한 번에.
- **설명:**
```
이거 사기일까요? 누르기 전에 확인하세요.

택배 주소 확인 문자, 청첩장·부고 링크, 검찰·금감원 사칭 전화, "엄마 나 폰 고장 났어" 메신저, 저금리 대출과 리딩방 권유까지. 한 번 누르면 큰돈을 잃을 수 있어요. 스캠센스가 몇 초 만에 쉬운 말로 알려드려요.

이렇게 써요
• 문자, 이메일, 링크, 전화번호를 붙여 넣거나 스크린샷을 추가하세요
• 신호등 판정: 빨강(사기), 노랑(의심), 초록(안전해 보임) + 0~100 위험 점수
• 위험 신호를 쉬운 말로 설명
• 지금 해야 할 일, 이미 눌렀거나 돈을 보냈을 때 대처법
• 한 번에 신고: 경찰청 112, 한국인터넷진흥원 118, 금융감독원 1332
• 가족에게 경고 메시지 바로 보내기

부모님도 쉽게
• 큰 글자 모드, 큰 버튼, 높은 대비, VoiceOver 지원
• 회원가입·광고·추적 없음
• 메시지 속 링크를 앱이 절대 열지 않아요

사기 찾기 퀴즈 (무료)
매일 진짜 같은 메시지 5개. 사기와 정상을 구별해 보세요. 연속 기록과 레벨, 점수 공유까지!

사기 수법 알아보기
택배 스미싱, 청첩장·부고, 가족 사칭, 검찰·금감원 사칭, 대출 사기, 리딩방·코인, 로맨스 스캠, 중고거래 사기 등 12가지.

부모님 지키기
가족 확인 암호 같은 안전 습관과 부모님께 보내는 추천 메시지.

무료: 매주 3회 확인, 퀴즈·학습 무제한
스캠센스 Pro: 무제한 확인(공정 사용 하루 50회), 전체 기록, 가족 경고 메시지. 월간 또는 연간(7일 무료 체험).

결제는 구매 확정 시(무료 체험 후) Apple 계정으로 청구되며, 현재 기간 종료 24시간 전까지 해지하지 않으면 자동 갱신됩니다. App Store 계정 설정에서 언제든 관리·해지할 수 있어요.

스캠센스는 AI(Anthropic Claude)를 사용하며 틀릴 수 있어요. 헷갈리면 회사의 공식 번호로 직접 확인하세요.

개인정보 처리방침: https://scamsense.namu3gru.com/privacy
이용약관: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

---

## 8. Apple 심사 메모 (App Review Notes — 영어로 붙여 넣기)
```
ScamSense gives an AI second opinion on whether a pasted message, link, phone number or screenshot is a scam.

- No account or login is needed. Launch the app, finish the short onboarding (the demo uses a built-in sample, no network call), then on the Check tab tap "Paste" or type any text, e.g. "Toll Services: you owe $6.99, pay at tollpay-renew.top", and tap "Check it". Results take 15-25 seconds.
- Before the first AI request the app shows a consent screen explaining exactly what is sent (text/screenshot), to whom (our server and Anthropic's Claude AI), that it is not stored or used for ads, and requires an explicit "Agree" tap (Guideline 5.1.2(i)).
- Free users get 3 checks per week (enforced by our server). The quiz and learning content are free. Pro subscription: monthly or yearly with a 7-day free trial; Restore Purchases is on the paywall and in Settings.
- The app never opens links contained in the user's message. Report links (e.g. reportfraud.ftc.gov) open in Safari only when tapped.
- The clipboard is read only when the user taps the system Paste button.
- Privacy policy: https://scamsense.namu3gru.com/privacy  Support: support@namu3gru.com
```
(심사 기기 IP 대역 17.0.0.0/8은 서버가 IP 한도에서 제외하므로 심사 중 한도 문제는 없습니다.)

---

## 9. 출시 전 체크리스트
- [x] (2026-10-29) 번들 ID `com.namu3gru.ScamSense` 등록 + 배포 프로필 "ScamSense App Store" 생성·설치(API). 서명 빌드: `ios/release.sh` (`LOCAL=1`이면 업로드 없이 .ipa만). `AppConfig.swift`에 `REPLACE_WITH_APP_TOKEN`이 남아 있으면 release.sh가 멈춥니다(로컬 서명 테스트만 `ALLOW_PLACEHOLDER_TOKEN=1 LOCAL=1`).
- [x] 6.9" 스크린샷 세트(1320×2868, 캡션 포함) en 7장 `screenshots/appstore/en/`, ko 7장 `screenshots/appstore/ko/`. 원본 캡처: `U=<시뮬레이터 UDID> tools/shot69.sh`, 캡션 합성: `swift tools/frame_shots.swift` (예시 데이터만 사용, 서버 호출 없음).
- [ ] 서버(apps_api) 배포 + 실제 `APP_TOKEN`, 결제 유예 기간(grace period) 중인 구독자도 Pro로 인정하도록 서버 보완 필요(아래 11번).
- [ ] `AppConfig.swift`의 `appToken`을 실제 값으로 교체 (위 5번)
- [ ] App Store Connect에서 앱 생성: 번들 ID `com.namu3gru.ScamSense`, SKU 예: `scamsense01`, 기본 언어 영어(미국), 한국어 추가
- [ ] 구독 그룹 **"ScamSense Pro"** 생성 + 그룹 표시 이름 en "ScamSense Pro" / ko "스캠센스 Pro"
  - [ ] `com.namu3gru.ScamSense.pro.yearly` — 1년, $29.99 / ₩44,000, 소개 혜택: **무료 1주** (신규 구독자)
  - [ ] `com.namu3gru.ScamSense.pro.monthly` — 1개월, $4.99 / ₩6,900
  - [ ] 각 상품 en/ko 표시 이름·설명, 심사용 스크린샷(페이월 화면 `screenshots/05_paywall.png`) 첨부
- [ ] 서버 `.env`에 `APPLE_APP_ID_SCAM=<앱 숫자 ID>` 추가 (프로덕션 구매 검증용)
- [ ] `apps_api/site/scam/` 페이지를 https://scamsense.namu3gru.com 에 배포 후 https://scamsense.namu3gru.com/privacy , /terms , /support 열리는지 확인
- [ ] App Store Connect 앱 정보: 개인정보 처리방침 URL = `https://scamsense.namu3gru.com/privacy`, 지원 URL = `https://scamsense.namu3gru.com/support`, 이용약관(EULA)은 Apple 표준 사용
- [ ] **앱 개인정보(App Privacy) 답변**: 추적 안 함. 수집 항목 → "기타 사용자 콘텐츠", "사진 또는 비디오"(스크린샷), "기기 ID", "구입 내역" 모두 **앱 기능 목적, 사용자와 연결 안 됨**
- [ ] **연령 등급**: 설문에 정직하게 답하세요(18+ 불필요). 사기 관련 교육 내용이라 대체로 **4+ 또는 9+** 예상 — 폭력/성인 콘텐츠 없음
- [ ] 카테고리: 유틸리티 (보조: 라이프스타일)
- [ ] 스크린샷 세트(6.9")는 이후 별도 제작 — 위 테스트 훅 사용
- [ ] Xcode › Product › Archive → TestFlight 업로드 → 샌드박스 계정으로 구매·복원·402 흐름 확인
- [ ] (선택) 가족 공유(Family Sharing) 켜기 검토 — "부모님 지키기"와 잘 맞지만 **한 번 켜면 끌 수 없음**. 서버는 구독 1개당 기기 5대까지 허용.

---

## 10. 로드맵
1. **공유 확장(Share Extension)**: 메시지 앱에서 길게 눌러 "공유 → 스캠센스"로 바로 확인 (가장 큰 전환 레버)
2. **가족 플랜/보호자 모드**: 부모님 기기에서 "사기" 판정 시 자녀에게 알림(동의 기반)
3. 문자 필터 확장(ILMessageFilterExtension)으로 미확인 발신 스팸 자동 분류
4. 퀴즈 콘텐츠 월 20문항 추가(서버에서 내려받기), 시즌 이벤트(연말 택배·세금 시즌)
5. 홈 화면 위젯: 오늘의 퀴즈·연속 기록
6. 일본·영국·캐나다·호주 신고처 추가 및 현지화
7. 페이월 A/B 테스트(연간 단독 vs 2플랜), 주간 플랜 실험

---

## 11. 알려진 한계
- 시뮬레이터를 `simctl`로 실행하면 StoreKit 상품이 로드되지 않아 페이월은 폴백 가격으로 표시됩니다(정상). Xcode ▶ 실행 시에는 `Products.storekit`으로 구매 테스트 가능.
- 목 서버는 어떤 입력이든 같은 샘플(통행료 사기, 영어)을 돌려줍니다. 실제 판정 품질은 TestFlight에서 확인하세요.
- 서버는 구독 거래의 만료일(expiresDate)까지만 Pro로 인정합니다. Apple 결제 유예 기간(갱신 결제 실패 후 재시도 중)에는 앱은 Pro로 표시하지만 서버는 무료 한도를 적용해, 앱이 "구매 복원" 안내 오류를 보여 줍니다. 유예 기간을 켜려면 서버가 갱신 정보(renewalInfo의 gracePeriodExpiresDate)도 확인해야 합니다.
- 일부 시뮬레이터는 이모지 글꼴을 못 그려 퀴즈 메시지 속 이모지가 "?"로 보일 수 있습니다(실기기는 정상).
