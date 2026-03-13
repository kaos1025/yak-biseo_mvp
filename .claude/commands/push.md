---
description: 원격 저장소에 안전하게 푸시합니다.
---

원격 저장소에 코드를 푸시한다. 아래 단계를 순서대로 실행하라.

## Step 1: 현재 브랜치 확인
```bash
git branch --show-current
```

## Step 2: 원격 저장소 상태 확인
```bash
git fetch origin
git status
```

## Step 3: 푸시할 커밋 확인
현재 브랜치에서 원격에 없는 커밋 목록을 보여준다.

## Step 4: 충돌 가능성 체크
- 원격에 새 커밋이 있으면 사용자에게 알리고 `git pull --rebase` 제안.

## Step 5: 최종 확인
사용자에게 브랜치명, 커밋 수, 커밋 목록을 요약하여 보여주고 **승인을 받은 후** 푸시를 실행한다.

## Step 6: 푸시 실행
```bash
git push origin <current-branch>
```

## Step 7: 결과 보고
브랜치명, 푸시된 커밋 수를 보고한다.
