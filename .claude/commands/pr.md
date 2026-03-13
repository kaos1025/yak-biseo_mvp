---
description: PR 설명을 자동 생성합니다.
---

Pull Request 설명을 자동 생성한다. 아래 단계를 순서대로 실행하라.

## Step 1: 변경 사항 분석
```bash
git diff master --stat
git log master..HEAD --oneline
git diff master --name-only
```

## Step 2: PR 설명 생성
아래 형식으로 PR 설명을 작성한다:

```markdown
## Summary
- 변경사항 bullet points

## Why
- 이 변경이 필요한 이유

## How
- 구현 방법

## Test Plan
- [ ] 테스트 항목들

## Checklist
- [ ] `flutter analyze` Error 0개
- [ ] 테스트 통과
- [ ] 코드 리뷰 완료
```

## Step 3: 사용자 확인
생성된 PR 설명을 보여주고 수정이 필요한지 확인한다.

## Step 4: PR 생성
사용자가 승인하면 `gh pr create`로 PR을 생성한다.
