# PRD-027 — WorkItem Completion & VERIFIED Engine
상태: DRAFT (Design 예정)

---

## 0. Scope

### 포함
- WorkItem v1 엔티티(테이블 + 상태머신) 도입
- completion_policy evaluator(도메인팩 외부화)
- VERIFIED 전이 Enforcer 규칙
- Atlas stale adapter 경로 확정

### 제외
- Retrieval 전략 개선(PRD-023)
- Atlas 인덱스 갱신(PRD-026)
- Decision Commit Gate(PRD-025)

---

## 1. WorkItem Model (A-Level Integrated Contract)

### 1.1 Binding (LOCK)
- WorkItem은 반드시 `decisions.id` (DecisionVersion UUID)에 바인딩된다.
- `root_id` 또는 active root 기반 바인딩은 금지한다.
- DecisionVersion active 포인터 변경은 WorkItem에 영향을 주지 않는다.
- WorkItem.decision_id는 생성 후 변경 불가(Immutable FK).

### 1.2 Status Space (LOCK)
WorkItem.status는 다음 집합을 가진다:
- PROPOSED
- ANALYZING
- DESIGN_CONFIRMED
- IMPLEMENTING
- IMPLEMENTED
- VERIFIED
- CLOSED

### 1.3 Transition Rule (LOCK)
- work_item_transitions는 append-only이다.
- 기존 transition row 수정/삭제는 금지된다.
- 상태 overwrite는 work_items.status 필드에 한해 허용되며,
  반드시 transition log가 선행 기록되어야 한다.
- 임의 점프 금지 (정의된 전이 그래프 외 전이 불가).

### 1.4 Transition Graph (V1)

허용 전이 경로는 다음으로 제한된다:

PROPOSED
  → ANALYZING
  → DESIGN_CONFIRMED
  → IMPLEMENTING
  → IMPLEMENTED
  → VERIFIED
  → CLOSED

- 정의되지 않은 상태 점프는 금지된다.
- IMPLEMENTED 이전에 VERIFIED 전이 금지.
- VERIFIED 이전에 CLOSED 전이 금지.

---

## 2. Completion & Enforcement Rules

### 2.1 Key Structural LOCKs
- WorkItem.decision_id는 DecisionVersion UUID에 바인딩 (root_id 금지)
- transition log append-only
- completion_policy는 평가만 수행하며 상태 전이는 Enforcer만 수행
- Atlas stale=true일 경우 auto VERIFIED 금지
- Completion 결과는 PlanHash에 포함되지 않음
- BudgetExceededError는 FailFast이며 Completion 흐름과 혼합 금지
- status overwrite + transition append는 반드시 하나의 DB 트랜잭션으로 수행되어야 한다 (Atomic Guarantee).
- transition 기록 실패 시 status 변경은 롤백되어야 한다.
- WorkItem.status는 “현재 상태 캐시”이며, 감사 SSOT는 work_item_transitions(append-only)이다.
- completion_policy는 결과만 반환하며, WorkItem 업데이트(transition append + status overwrite)는 Enforcer만 수행한다.

---

## 3. Exit Criteria (v1)

| # | 종료 조건 | 비고 |
|:--|:--|:--|
| 1 | WorkItem v1 테이블 + FK/인덱스 추가 | work_items / work_item_transitions |
| 2 | 상태 전이 엔진 구현 | 임의 점프 불가 + 전이 로그 기록 |
| 3 | completion_policy evaluator 동작 | Domain Pack 기반 |
| 4 | VERIFIED 전이 강제 | IMPLEMENTED → VERIFIED → CLOSED |
| 5 | stale 처리 정책 적용 | stale 시 auto-verify 금지 |
