# PRD-030: Guardian YAML Wiring

## 1. Objective
- `ModeDefinition`에 `validators` 및 `postValidators` 선언 필드를 도입한다.
- `PolicyInterpreter`가 YAML 설정을 해석하여 `ExecutionPlan.validators`에 주입하도록 한다.
- 웹 런타임 경로에서도 Guardian Enforcement가 실제로 실행되도록 Wiring을 완성한다.

## 2. Scope
### 포함
- `ModeDefinition` 확장 및 YAML 스키마 검증 로직 추가.
- `resolveExecutionPlan` 매핑 로직 고도화.
- `PlanHash` 계약 유지 및 안정성 확보.
- 테스트 보강.

### 제외
- Guardian 로직 수정.
- `PlanHash` 제외 전환.
- Decision/WorkItem 로직 변경.
- Atlas 구조 변경.

## 3. YAML Contract (Schema Definition)

```yaml
modes:
  - id: "default"
    plan: [...]
    # preflight: executePlan 진입 직후 실행되는 검증기
    validators:
      - validator_id: "guardian.contract"
        validator_version: "v1"
    # post: 각 step 완료 직후 실행되는 검증기
    postValidators:
      - validator_id: "guardian.evidence_integrity"
        validator_version: "v1"
```

### 계약 규칙
- `validators`/`postValidators`는 mode 루트 레벨에 위치한다.
- **배열 순서**는 실행 순서이자 해시 입력 순서이다.
- 자동 정렬 로직은 없으며, 순서 변경 시 `PlanHash`가 변경된다.
- 중복 validator 선언을 허용하며, 중복된 항목도 해시에 각각 포함된다.
- 등록되지 않은 `validator_id`는 `ALLOW` 처리하며 `VALIDATOR_NOT_FOUND` 로그를 남긴다.

## 4. Execution Model Alignment
- **Preflight**: `executePlan` 진입 직후 1회 실행된다.
- **Post**: 각 step 실행 완료 직후 실행된다.
- `runValidators`는 `ExecutionPlan`의 주입된 validators를 직접 참조하여 실행한다.

## 5. Hash Contract
- `normalizeExecutionPlanForHash` 로직은 기존 계약을 유지한다.
- `validators` 및 `postValidators` 리스트는 `PlanHash` 입력 데이터에 포함된다.
- 🔒 **LOCK**: `validatorFindings`는 어떠한 경우에도 `PlanHash` 계산에 포함되지 않는다.

## 6. Acceptance Criteria
- YAML에 validator 선언 시 `ExecutionPlan` 객체에 정상 주입됨을 확인한다.
- 웹 입력에서 PRD 참조 없는 코드 수정 시 Guardian `BLOCK` 발동을 확인한다.
- validator 구성 또는 순서 변경 시 `PlanHash`가 달라짐을 확인한다.
- 존재하지 않는 ID 입력 시 `ALLOW` + `VALIDATOR_NOT_FOUND` 반환을 확인한다.
- 기존 세션 재현성 및 회귀 테스트를 통과한다.
