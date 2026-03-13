# yak-biseo_mvp — Claude Code 프로젝트 규칙

> 이 파일의 모든 규칙은 절대적이다. 모든 작업에서 반드시 따른다.

## Project Overview

Flutter 앱 "약비서(yak-biseo)" — 사용자가 약 사진을 찍으면 AI가 분석하여 중복/상호작용 경고, 절약 금액을 알려주는 서비스.

- **타겟 사용자:** 4050 세대 (큰 텍스트, 높은 명도 대비)
- **State Management:** `ChangeNotifier` + `Provider`
- **Architecture:** UI → Repository → DataSource (계층 분리)
- **AI Backend:** Google Generative AI API
- **UI 언어:** 한국어(Korean) 기본

## Tech Stack

- Flutter / Dart (null-safety)
- Provider (`ChangeNotifier`)
- Google Generative AI API
- Firebase Analytics

## Project Structure

```
lib/
├── config/          # 앱 설정
├── core/            # 공통 유틸/상수
├── data/            # DataSource, Repository 구현
├── l10n/            # 다국어(i18n)
├── models/          # 데이터 모델
├── presentation/    # 화면별 UI
├── screens/         # 스크린 위젯
├── services/        # API, Analytics 서비스
├── theme/           # 테마 설정
├── utils/           # 유틸리티
└── widgets/         # 공용 위젯
```

---

## CRITICAL — 절대 규칙

### NEVER DO

- **DO NOT** hardcode API keys, tokens, or passwords in source code.
- **DO NOT** add new packages without user approval.
- **DO NOT** make large-scale structural changes without user approval.
- **DO NOT** mix multiple intents in one change (1 change = 1 intent).
- **DO NOT** print or share `.env` file contents.
- **DO NOT** commit `.env`, credentials, or secret files.

### ALWAYS DO

- **DO** present a plan before making changes: summary (1-3 lines) + action items (3-7 bullets).
- **DO** keep changes small and reversible — one file/feature per change.
- **DO** follow existing code style and patterns before introducing new ones.
- **DO** run `flutter analyze` and confirm 0 errors before considering work done.

### STOP AND ASK

Stop and ask the user before proceeding when:
- A new package is needed.
- Architecture changes are required.
- Requirements are unclear.
- Multiple approaches are viable (present options).

---

## HIGH — Flutter/Dart 규칙

### Code Style

- **DO** use `snake_case.dart` filenames, `PascalCase` classes/enums, `camelCase` variables/functions.
- **DO** prefer `final`/`const` and explicit type declarations.
- **DO** follow Effective Dart + null-safety conventions.
- **DON'T** abuse `dynamic` type.
- **DON'T** use `!` (null assertion) without a prior null check or guaranteed non-null context.
- **DON'T** perform heavy computation or I/O inside `build()`.

### Widget Design

- **DO** decompose large screens into small, focused widgets.
- **DO** use `ListView.builder` and other lazy builders for lists.
- **DO** handle all states explicitly: loading, error, empty, data.
- **DON'T** build monolithic mega-widgets.

### State Management

- **DO** use `ChangeNotifier` + `Provider` (project standard).
- **DO** keep business logic out of UI widgets.
- **DON'T** add new state management packages without approval.

### Network / Data

- **DO** follow UI → Repository → DataSource layering.
- **DO** handle DTO ↔ Domain conversion in a single place.
- **DO** model failure cases explicitly; always handle loading/cancel/error.
- **DON'T** call HTTP/DB directly from UI code.

### AI/Gemini Integration

- **DO** wrap all AI-generated JSON parsing in `try-catch`.
- **DO** use safe conversions (`int.tryParse`, etc.) with default values.

---

## NORMAL — UI/UX 규칙 (약비서 전용)

- Target audience is 4050 세대 → ensure sufficient text size and strong contrast.
- UI text defaults to Korean.
- Colors: positive = Green, warning = Amber/Orange.
- Use `Theme.of(context)` for consistent theming.

---

## NORMAL — 개발 철학 (Kent Beck / XP)

> 작게(Small) → 피드백(Feedback) → 단순하게(Simple) → 정리(Refactor)

- **DO** choose the smallest next action, verify immediately, improve structure while keeping behavior.
- **DO** design the simplest solution that satisfies current requirements.
- **DON'T** create abstractions "just in case" — no premature abstraction.

---

## Git Conventions

### Commit Format

```
<type>: <subject>
```

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring |
| `docs` | Documentation |
| `chore` | Config/build |

- Subject: 50 chars max, no period.
- 1 commit = 1 intent (don't mix feature + refactor + format).

### Pre-commit Checklist

1. `dart format .`
2. `flutter analyze` — must have 0 errors
3. No hardcoded secrets in `lib/`
4. No stray `print()` statements
5. `.env` not staged

---

## Definition of Done

- [ ] Code works (at least 1 verified path)
- [ ] `flutter analyze` — 0 errors
- [ ] Failure cases handled (error/empty states)
- [ ] Names and structure reveal intent
- [ ] PR description written (What/Why/How)

---

## Slash Commands

Use these Claude Code commands for common workflows:

- `/commit` — Pre-commit checks + git commit
- `/push` — Push to remote with safety checks
- `/pr` — Generate PR description
- `/test` — Run Flutter tests
- `/review-cycle` — Full quality check cycle (format → analyze → test → security → commit-ready)
- `/code-review` — Structured code review with checklist
- `/analyze` — Run flutter analyze + dart fix
- `/pre-commit` — Pre-commit safety checks only
