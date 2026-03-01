# D-027 — WorkItem Platform Spec
> Enforcement, insertion point, and storage rules

## 1. Insertion Point (LOCK)
- Completion 평가 레이어는 executePlan에서 PersistSession 직전에 실행한다.
- executePlan 루프 내부(step 실행 중) 삽입 금지.
- validators 계층 삽입 금지.
- PersistSession 이후 삽입 금지(도달 불가/상태 반환).

### 🔒 Execution Insertion Exact Position

Completion 평가 레이어는 다음 조건을 만족하는 지점에 삽입한다:

- 모든 Step 실행 완료
- 모든 Validator(Guardian) 실행 완료
- PersistSession Step 실행 직전

금지:
- executePlan 루프 내부 Step 실행 중 삽입
- runValidators 내부 삽입
- PersistSession 이후 삽입

### 🔒 Plan Hash Isolation

CompletionPolicy 결과는 Execution Plan Hash 계산에 포함되지 않는다.
Completion 결과 변경은 Plan 재계산을 유발하지 않는다.

## 2. Enforcement Boundary (LOCK)
- completion_policy는 평가만 수행.
- 상태 전이(IMPLEMENTED→VERIFIED→CLOSED)는 Enforcer만 수행:
  - work_items.status overwrite
  - work_item_transitions append-only 기록

## 3. Atlas Stale Adapter (REQUIRED)
- stale은 DB 고정값이 아니라 조회 시 계산값임.
- 따라서 PlanExecutorDeps 또는 GraphState 확장 중 하나로 stale 조회 경로를 제공해야 한다.
- 최소 요구: Completion 평가 시점에 { stale }를 확보 가능해야 한다.

## 4. Failure Classification (LOCK)
- BudgetExceededError는 FailFast(구조적 차단)이며 Completion 흐름과 혼합 금지.
- completion_policy BLOCK/REQUIRE_CONFIRMATION은 Intervention(사용자 개입) 범주.
