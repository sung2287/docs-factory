# PRD-030: Guardian YAML Wiring Contract

## A. ModeDefinition 확장 계약

```typescript
/**
 * WHY: YAML 기반의 선언적 가디언 주입을 위한 스키마 확장
 */
interface ModeDefinition {
  id: string;
  plan: StepDefinition[];
  validators?: ValidatorRef[];     // preflight validators
  postValidators?: ValidatorRef[]; // post-step validators
}

interface ValidatorRef {
  validator_id: string;
  validator_version: string;
}
```

## B. Mapping Contract
- `resolveExecutionPlan`은 `mode.validators`를 `ExecutionPlan.validators`에 1:1 매핑한다.
- `mode.postValidators`는 `ExecutionPlan.postValidators`에 1:1 매핑한다.
- `undefined`는 `[]`로 정규화한다.
- 🔒 **LOCK**: 배열 순서를 엄격히 유지하며, deep copy 후 freeze 처리한다.

## C. Hash Contract
- `validators` 및 `postValidators`는 `PlanHash` 입력에 포함된다.
- `normalizeExecutionPlanForHash` 변경을 금지한다.
- 배열 순서 변경은 반드시 `PlanHash` 변경을 유발한다.

## D. Unknown ID Contract
- registry miss 시 `ALLOW`를 반환한다.
- `VALIDATOR_NOT_FOUND` reason을 유지한다.
- 런타임 FailFast 전환은 금지한다.
