---
description: Flutter 정적 분석 + 자동 수정을 실행합니다.
---

Flutter 코드 품질 분석을 수행하라. 아래 단계를 순서대로 실행한다.

## Step 1: 정적 분석
```bash
flutter analyze
```

## Step 2: 포맷 체크
```bash
dart format --set-exit-if-changed .
```

## Step 3: 자동 수정 가능 항목 확인
```bash
dart fix --dry-run
```

## Step 4: 결과 보고
아래 형식으로 보고한다:

| 유형 | 개수 |
|------|------|
| Error | N개 |
| Warning | N개 |
| Info | N개 |

- Error가 있으면 각 에러에 대해 파일:라인, 에러 메시지, 수정 방법을 제시.
- 자동 수정 가능한 항목이 있으면 `dart fix --apply` 실행 여부를 사용자에게 확인.

## Step 5: 최종 판정
- Error 0개 + 포맷 적용됨 → 커밋 가능 상태
- Error 존재 → 수정 필요
