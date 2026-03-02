# D-021: Core Extensibility Platform Spec

## 1. File-level Change Map

| File Path | Description of Change | Role |
|:----------|:----------------------|:-----|
| `src/types/execution_plan.ts` | `ExecutionPlan` 인터페이스에 `validators[]`, `postValidators[]` 필드 추가. `ValidatorSignature` 타입 정의. | **Schema** |
| `src/runtime/graph/execution_plan_hash.ts` | `ValidatorSignature`(`id`, `version`, `config_hash`)를 해시 계산 대상(stableStringify)에 포함. | **Integrity** |
| `src/session/bundle_pin.store.ts` | `BundlePinV1` 스키마에 `strategy_provider_id`, `memory_provider_id` 필드 추가 및 저장/로드 로직 보강. | **Persistence** |
| `src/memory/decision_context.service.ts` | `DecisionContextProviderPort` 인터페이스 추출 및 주입된 전략을 통한 데이터 로드 로직 구현. (Merge 로직 유지) | **Memory** |
| `src/di/strategy_resolver.ts` (New) | Bundle Manifest/Pin 기반으로 적절한 Strategy/Provider 구현체를 찾아주는 Resolver 레이어 구축. | **DI** |

---

## 2. Dependency Graph (Before/After)

### Before
```text
Runtime Core -> Hardcoded Hierarchical Retrieval
             -> Hardcoded Memory Repository
             -> Fixed Step Execution (No Hooks)
```

### After
```text
Runtime Core -> [DecisionContextProviderPort] -> Strategy Implementation (SQL/Vector/...)
             -> [MemoryRepositoryPort] -> Provider Implementation (SQLite/...)
             -> [Execution Hook Handler] -> Domain Pack Validator (Guardian/...)
```

---

## 3. State Machine Diagram

```text
[ START ]
    |
    v
[ Pre-flight Hooks ] (validators[])
    |
    |-- ALLOW ----> [ Step Execution ]
    |-- WARN  ----> [ Step Execution ] (Notification Log)
    |-- BLOCK ----> [ InterventionRequired ] (Wait for User/Override)
    |
    v
[ Step Result ] (Read-only View)
    |
    v
[ Post-validators ] (postValidators[])
    |
    |-- ALLOW ----> [ NEXT STEP / SUCCESS ]
    |-- WARN  ----> [ NEXT STEP / SUCCESS ] (Notification Log)
    |-- BLOCK ----> [ InterventionRequired ] (Wait for User/Override)
    |
    v
[ END ]
```

### 3.1 Resume Path (InterventionRequired -> Resume)
1. 사용자가 개입(Override)하거나 조건을 수정하여 Resume 요청.
2. 시스템은 기존 `ExecutionPlan`과 Plan Hash를 재검증한다.
3. Intervention 발생 이전의 StepResult는 재사용하지 않는다.
4. Resume는 동일 Step을 재실행하는 것이 아니라, 해당 Step을 처음부터 다시 실행하는 방식으로 수행한다.
5. StepResult는 항상 순수 실행 결과로만 생성된다.

---

## 4. Hash Evolution Flow

1. **ExecutionPlan 정의**: Step 정보 + `validators[]` 구성.
2. **Validator Signature 생성**: 각 Validator의 `id`, `version`, `config_hash` 추출.
3. **Payload 조립**: Step + Validator Signatures (Logic-only 변경 시 버전 업 필수).
4. **Plan Hash 계산**: `stableStringify(payload)` -> `SHA-256`.
5. **결과**: Validator의 로직 버전이 바뀌면 Plan Hash가 결정론적으로 변경되어 불일치 감지 가능.

---

## 5. Bundle Resolution + Strategy Resolution Flow

1. **Load Bundle**: `manifest.json`을 읽어 번들 정보 로드.
2. **Identify IDs**: `strategy_provider_id`, `memory_provider_id` 식별.
3. **Check Pin**: 기존 세션인 경우 `BundlePinV1`에서 고정된 ID 확인.
4. **Resolve Port**: `StrategyResolver`를 통해 해당 ID에 매칭되는 구현체 인스턴스 획득.
5. **Inject Core**: `DecisionContextService` 및 `MemoryService`에 Port 구현체 주입.
6. **Execution Start**: 주입된 전략 기반으로 리트리벌 및 실행 개시.

---

## 6. Migration Notes (Non-breaking Path)

- **Legacy Compatibility**: `validators[]` 필드가 없는 기존 `ExecutionPlan`은 빈 배열(`[]`)로 처리하여 하위 호환성 유지.
- **Default Strategy**: Bundle에 Strategy ID가 없는 경우, 기존의 `Hierarchical SQL Strategy`를 Default로 할당.
- **Pin Upgrade**: 기존 `BundlePin` 데이터 로드 시 ID 필드가 없으면 `manifest.json`의 현재 값을 주입하여 마이그레이션 수행.
- **Fail-fast Policy**: 마이그레이션 중 ID 불일치나 재현 불가 상황 발생 시 Safety Contract에 따라 실행을 중단하고 사용자에게 알림.
