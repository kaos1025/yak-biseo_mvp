---
description: 커밋 전 안전성 체크만 수행합니다 (커밋하지 않음).
---

커밋 전 필수 검사만 수행하라 (실제 커밋은 하지 않는다).

## Step 1: 정적 분석
```bash
flutter analyze
```
- Error가 1개라도 있으면 → 커밋 불가 판정

## Step 2: 포맷 정리
```bash
dart format .
```

## Step 3: 보안 체크
`lib/` 내 hardcoded secrets 검색:
- `api_key`, `apiKey`, `API_KEY`, `secret`, `password`, `token`
- 민감 정보 발견 시 → 커밋 불가 판정

## Step 4: 디버그 코드 체크
`lib/` 내 `print()` 문 검색. 발견 시 제거 권장.

## Step 5: .env 파일 체크
`.env` 파일이 git staged 상태인지 확인.
- staged 상태면 → 커밋 불가 판정

## Step 6: 결과 보고

| 항목 | 상태 | 비고 |
|------|------|------|
| flutter analyze | pass/fail | Error N개 |
| dart format | pass/fail | 변경 N개 |
| 보안 체크 | pass/fail | |
| 디버그 코드 | pass/warn | print() N개 |
| .env 체크 | pass/fail | |

**최종 판정: [커밋 가능 / 수정 필요]**

### 커밋 불가 조건 (하나라도 해당 시 불가):
1. `flutter analyze` Error 존재
2. API Key/토큰/비밀번호 하드코딩
3. `.env` 파일 staged 상태
4. 컴파일 에러 존재
