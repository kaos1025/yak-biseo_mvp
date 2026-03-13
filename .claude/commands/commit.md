---
description: Pre-commit 체크 후 Git 커밋을 수행합니다.
---

커밋 전 품질 체크 후 Git 커밋을 수행하라. 아래 단계를 순서대로 실행한다.

## Step 1: 포맷 정리
```bash
dart format .
```

## Step 2: 정적 분석
```bash
flutter analyze
```
- Error가 1개라도 있으면 **즉시 중단**하고 사용자에게 에러 목록과 수정 방법을 알린다.
- Warning은 목록으로 보여주고 계속 진행.

## Step 3: 보안 체크
`lib/` 디렉토리에서 아래 패턴을 검색한다:
- `api_key`, `apiKey`, `API_KEY`, `secret`, `password`, `token` 이 하드코딩되어 있는지 확인
- `.env` 파일이 git staged 상태인지 확인
- 민감 정보 발견 시 **즉시 중단**.

## Step 4: 디버그 코드 체크
`lib/` 내 `print()` 문을 검색하고, 발견 시 제거를 권장한다.

## Step 5: 변경 사항 확인
`git status`와 `git diff --stat`으로 변경 사항을 요약한다.

## Step 6: 커밋 메시지 제안
변경된 파일을 분석하여 Conventional Commits 형식으로 메시지를 제안한다:
- `feat:` / `fix:` / `refactor:` / `docs:` / `chore:`
- 50자 이내, 마침표 없음

**사용자에게 제안 메시지를 보여주고 확인/수정을 받은 후** 커밋을 실행한다.

## Step 7: 결과 보고
커밋 완료 후 해시, 메시지, 변경 파일 수를 보고한다.
