# D-030: Guardian YAML Wiring Governance & LOCKs

## 1. Definition Location LOCK

- 🔒 `validators` 및 `postValidators`는 반드시 `mode` 루트 레벨에 위치한다.
- 🔒 `step` 하위 배치는 금지한다.

## 2. Execution Order LOCK

- 🔒 배열 순서는 실행 순서이다.
- 🔒 자동 정렬 로직은 존재하지 않는다.
- 🔒 YAML 선언 순서를 SSOT로 간주한다.

## 3. Hash Integrity LOCK

- 🔒 `validators` 및 `postValidators`는 `PlanHash` 입력에 포함된다.
- 🔒 배열 순서 변경은 `PlanHash` 변경을 유발한다.
- 🔒 `validatorFindings`는 `PlanHash` 계산에 포함되지 않는다.
- 🔒 `normalizeExecutionPlanForHash` 변경을 금지한다.

## 4. Unknown ID Policy

- registry miss 시 기본 동작은 `ALLOW`이다.
- reason은 `VALIDATOR_NOT_FOUND`를 유지한다.
- FailFast 전환은 금지한다.

## 5. Side-Effect Isolation

- 🔒 Guardian은 `GraphState`, `ExecutionPlan`, `StepResult`를 변경할 수 없다.
- 🔒 Guardian은 Side Channel State Transition을 생성할 수 없다.
- 🔒 Guardian은 validation 결과(`ALLOW | WARN | BLOCK`)만 반환할 수 있다.
