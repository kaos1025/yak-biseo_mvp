---
description: Git 커밋/푸시 규칙. 커밋 메시지 작성이나 git 작업 시 적용.
globs: ""
---

# Git Conventions

## CRITICAL

- **DO NOT** commit `.env`, credentials, API keys, or secret files.
- **DO NOT** mix multiple intents in one commit (1 commit = 1 intent).
- **DO NOT** commit with `flutter analyze` errors present.

## HIGH

- **DO** use Conventional Commits format: `<type>: <subject>`
  - Types: `feat`, `fix`, `refactor`, `docs`, `chore`
  - Subject: 50 chars max, no trailing period.
- **DO** run `dart format .` before committing.
- **DO** remove stray `print()` statements before committing.
- **DO** verify `.env` is not staged before committing.
