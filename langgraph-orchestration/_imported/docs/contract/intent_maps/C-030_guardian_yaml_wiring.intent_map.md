# PRD-030: Guardian YAML Wiring Intent Map

## INT-030-001: Inject Validators
- **Intent**: 유저가 정의한 가디언 검증기를 실행 계획에 주입한다.
- **Trigger**: `resolveExecutionPlan` 수행 시 `mode.validators`가 정의되어 있을 때.
- **Outcome**: `ExecutionPlan.validators`가 해당 데이터로 채워진다.

## INT-030-002: Execute Preflight Guardian
- **Intent**: 전체 계획 실행 전 사전 무결성을 검증한다.
- **Trigger**: `executePlan` 진입 시점.
- **Outcome**: `runValidators(preflight)`를 수행한다.

## INT-030-003: Execute Post Guardian
- **Intent**: 각 스텝 실행 후 결과의 정합성을 검증한다.
- **Trigger**: 개별 스텝 완료 시점.
- **Outcome**: `runValidators(post)`를 수행한다.

## INT-030-004: Preserve Hash Determinism
- **Intent**: 실행 계획의 결정론적 해시를 유지한다.
- **Trigger**: `ExecutionPlan` 해시 계산 시점.
- **Outcome**: `validators` 배열을 해시에 포함하고, `validatorFindings`는 제외한다.
