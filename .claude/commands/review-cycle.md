---
description: 전체 품질 체크 사이클 (format → analyze → test → security → commit-ready)
---

PR/Merge 전 전체 품질 체크 사이클을 실행하라. 아래 단계를 순서대로 수행한다.

## Step 1: 포맷 정리
```bash
dart format .
```

## Step 2: 정적 분석
```bash
flutter analyze
```
- Error가 있으면 **즉시 중단**, 수정 방법 안내.

## Step 3: 테스트 실행
```bash
flutter test
```
- 실패한 테스트가 있으면 목록과 수정 제안을 보여준다.

## Step 4: 보안 체크
- `lib/` 내 hardcoded secrets 검색 (`api_key`, `apiKey`, `API_KEY`, `secret`, `password`, `token`)
- `.env` 파일 staging 여부 확인

## Step 5: 디버그 코드 체크
- `lib/` 내 `print()` 문 검색

## Step 6: 전체 결과 리포트
아래 형식으로 보고한다:

| 항목 | 상태 | 비고 |
|------|------|------|
| dart format | pass/fail | |
| flutter analyze | pass/fail | Error N개 |
| flutter test | pass/fail | 통과 N/N |
| 보안 체크 | pass/fail | |
| 디버그 코드 | pass/warn | print() N개 |
| .env 체크 | pass/fail | |

**최종 판정: [통과 / 조건부 통과 / 실패]**

## Step 7: 다음 단계 안내
- 통과 → `/commit` → `/push` → `/pr`
- 실패 → 수정 항목 안내 후 다시 `/review-cycle`
