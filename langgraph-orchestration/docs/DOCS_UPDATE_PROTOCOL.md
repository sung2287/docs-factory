# DOCS UPDATE PROTOCOL (Agent Governance)

Purpose:
이 문서는 에이전트(LLM 포함)가 docs/ 내 문서를 생성/수정할 때 반드시 따라야 할 규칙을 정의한다.
설계-구현 분리 원칙과 거버넌스 일관성을 유지하기 위한 "문서 업데이트 헌법"이다.

----------------------------------------------------------------
0. GLOBAL PRINCIPLES
----------------------------------------------------------------

1) 문서는 코드와 동일한 수준의 변경 통제 대상이다.
2) 기존 내용을 삭제/덮어쓰기 금지. 변경은 Patch 또는 Append-only 원칙을 따른다.
3) "왜(why)"는 ADR에 기록하고, 규칙/형태/게이트만 governance에 둔다.
4) PRD는 기능 명세, Contract는 형태 정의, Governance는 경계/불변 요약.
5) 설명이 길어지면 잘못된 위치일 가능성이 높다.

----------------------------------------------------------------
1. FOLDER ROLE DEFINITIONS
----------------------------------------------------------------

docs/prd/
- 기능 단위 설계 문서.
- 상태: OPEN / CLOSED / RECONSTRUCTED 표시 필수.
- 구현 세부는 포함하되, 공통 불변 규칙은 복사하지 않는다.

docs/contract/
- 스키마 / 인터페이스 / LOCK 정의.
- shape 변경 시 반드시 version 명시.
- 하위 호환 깨지면 BREAKING CHANGE 명시.

docs/adr/
- 아키텍처 결정 이유(why) 기록.
- 과거 결정 수정 시 새 ADR 생성. 기존 ADR 수정 금지.

docs/governance/
- CORE_INVARIANTS: 깨지면 안 되는 축만.
- EXIT_CRITERIA: PRD 종료 조건 누적.
- EVIDENCE_MAPS: 코어 PRD 영향 지형도.
- 설명 금지. 규칙/체크 항목만.

docs/repomap/
- REPO_MAP: 어디를 보면 되는지(Where).
- updates.md: PRD 완료 시 최소 3개, 최대 5개 구조 변경 로그.

----------------------------------------------------------------
2. UPDATE RULES BY DOCUMENT TYPE
----------------------------------------------------------------

[PRD 업데이트]
- Status 필드 유지.
- 종료 시 CLOSED로 변경.
- 과거 PRD를 사후 작성하는 경우 RECONSTRUCTED 명시.

[CONTRACT 업데이트]
- 기존 스키마 직접 수정 금지.
- 변경 시 새 버전 생성 (e.g., V2).
- 하위 호환 유지 여부 명시.

[ADR 업데이트]
- 기존 ADR 수정 금지.
- 변경 사항은 새 ADR 추가.

[EXIT_CRITERIA 업데이트]
- 기존 항목 수정/삭제 금지.
- Patch 섹션에 append-only 추가.

[EVIDENCE_MAPS 업데이트]
- PRD 섹션 1~2페이지 초과 금지.
- 금지 삽입 지점 / SSOT 영향 / 해시 영향 / 회귀 위험 / 테스트 근거 필수 기록.

----------------------------------------------------------------
Cross-cutting Concern Section (Optional)

PRD 단위가 아닌 구조적 축(예: Session Lifecycle, Deterministic Hashing 등)은
"## <Concern Name>" 형식으로 작성할 수 있다.

이 경우에도 반드시 포함:
- Scope
- Touchpoints
- Forbidden
- SSOT/Hash Impact
- Regression Risks
- Tests/Evidence

PRD ID가 없더라도 동일한 형식 규율을 따른다.
----------------------------------------------------------------

[REPO_MAP 업데이트]
- 구조 변경 발생 시:
  1) 먼저 updates.md에 3줄 기록
  2) 그 후 필요 시 REPO_MAP 본문 수정
- 상세 설명 추가 금지.

----------------------------------------------------------------
3. STRUCTURAL CHANGE WORKFLOW (MANDATORY)
----------------------------------------------------------------

구조적 변경(SSOT, Hash boundary, Authority, Status machine 등)이 발생하는 경우:

1) ADR 생성
2) CORE_INVARIANTS 검토/필요 시 수정
3) EXIT_CRITERIA 영향 확인
4) EVIDENCE_MAP 업데이트
5) repomap/updates.md 기록

이 순서를 건너뛰면 안 된다.

----------------------------------------------------------------
3.1 CORE_INVARIANTS CHANGE POLICY
----------------------------------------------------------------

Invariant 변경은 일반 문서 수정이 아니다. 반드시 ADR을 선행한다.

[추가(Add)]
- 새 Invariant 추가 시:
  1) ADR 생성 (이유 명시)
  2) CORE_INVARIANTS에 append-only 추가
  3) 관련 PRD / EXIT 영향 검토

[수정(Modify)]
- 기존 Invariant 직접 수정 금지.
- 수정이 필요한 경우:
  1) 신규 ADR 생성
  2) 기존 RULE은 유지하되 "DEPRECATED" 표시
  3) 새 RULE을 append

[삭제(Remove)]
- 물리적 삭제 금지.
- "DEPRECATED — superseded by ADR-XXX" 형태로 표시.

Invariant은 역사 보존 대상이며 rewrite 대상이 아니다.

----------------------------------------------------------------
4. ANTI-PATTERNS (FORBIDDEN)
----------------------------------------------------------------

- PRD 안에 공통 불변 규칙 복사
- Governance 문서에 배경 설명 장문 작성
- Contract에 구현 로직 서술
- REPO_MAP에 철학/설명 추가
- 기존 문서 내용 무단 삭제

----------------------------------------------------------------
5. DOCUMENT LENGTH DISCIPLINE
----------------------------------------------------------------

- CORE_INVARIANTS: 1페이지 이내
- REPO_MAP: 2페이지 이내
- EXIT_CRITERIA: 누적 가능하나 PRD 섹션은 간결
- EVIDENCE_MAP: PRD당 1~2페이지 제한

문서가 길어지면 분리할 것. 늘리지 말 것.

----------------------------------------------------------------
6. RECONSTRUCTED POLICY
----------------------------------------------------------------

과거 PRD/Exit/Evidence를 사후 작성할 경우 반드시 상단에:

Status: RECONSTRUCTED
Purpose: Governance Hardening / Regression Guard

를 명시한다.

----------------------------------------------------------------
END OF PROTOCOL
----------------------------------------------------------------
