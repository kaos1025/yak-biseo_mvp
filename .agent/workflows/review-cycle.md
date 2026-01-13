---
description: 마스터 워크플로우
---

# review-cycle

1) Call /research
   - 변경 의도/영향 범위를 5줄로 요약하고, 리스크 후보 3개 뽑아줘.

2) Call /architect
   - 이번 변경이 아키텍처/모듈 경계에 맞는지 점검하고, 대안/트레이드오프 짧게 정리해줘.

3) Call /reviewer
   - Blocker/Major 위주로 먼저 잡고, 수정안(코드 스니펫 가능하면) 제시해줘.

4) Call /qa
   - 테스트 케이스 표 + 리그레션 체크리스트 만들어줘.

5) 최종 산출물
   - 머지 전 체크리스트(최대 7개)
   - PR 설명 초안(What/Why/How + 테스트 방법)
