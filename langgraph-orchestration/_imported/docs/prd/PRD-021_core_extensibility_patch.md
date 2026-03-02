# PRD-021: Core Extensibility Patch (Execution Hook & Strategy Port)

## 1. Objective

본 PRD의 목적은 LangGraph Runtime Core를 “고정 토폴로지 실행 엔진”에서 “확장 가능한 오케스트레이션 플랫폼”으로 진화시키는 것이다.

기능 추가가 아니라, Core의 제어권을 Domain Pack에 위임할 수 있는 확장 포인트를 개방하는 구조적 리팩토링이다.

---

## 2. Problem Statement

현재 구조의 제약:

1. ExecutionPlan은 고정 `STEP_TYPES_CANONICAL_ORDER`에 의존한다.
2. `runtime/graph/graph.ts`는 단일 `execute_plan` 노드 구조이다.
3. `decision_context.service.ts`는 계층적 Retrieval 전략을 하드코딩한다.
4. MemoryRepository 선택은 runtime 레벨에서 고정되어 있다.

이 구조는 다음을 불가능하게 한다:
- Guardian을 Step Type 수정 없이 삽입
- Retrieval Strategy 교체 (Hierarchical → Semantic)
- Memory Provider 정책 기반 선택
- 도메인별 Validator 주입

---

## 3. Scope

### 3.1 Execution Hook 도입

ExecutionPlan 스키마에 다음 필드를 추가한다:
- `validators[]` (또는 `preflightHooks[]`)
- `postValidators[]`

Core는:
1. Plan 실행 전 `validators[]` 호출
2. 각 Validator 결과(ALLOW/WARN/BLOCK) 수집
3. BLOCK 발생 시 InterventionRequired 상태 전환
4. Execution 지속 여부는 Safety Contract 기준으로 판단

⚠ Guardian BLOCK은 자동 실행 차단을 의미하지 않는다.

#### 🔒 3.1.1 Step Contract Preservation (LOCK)
Execution Hook은 기존 ExecutionPlan Step Contract (PRD-007)를 절대 침해하지 않는다.
- Hook은 Step Input/Output을 수정할 수 없다.
- Hook은 StepResult 스키마를 변형할 수 없다.
- Hook은 `STEP_TYPES_CANONICAL_ORDER`를 변경하거나 우회할 수 없다.
- Hook은 Step 실행 흐름을 단축/건너뛸 수 없다.
- Hook의 반환 타입은 `{ status: "ALLOW" | "WARN" | "BLOCK", reason: string, evidenceRefs?: string[] }`으로 제한된다.
- Core는 Hook 결과를 해석하여 `state.intervention = { required: true, reasons: [...] }`를 생성하거나, Runtime Safety Contract 위반 시 Fail-fast만 수행할 수 있다.
- Hook은 StepResult를 변경하는 “Side Channel State Transition”을 생성할 수 없다.
- **Hook은 StepResult에 대한 Read-only View만 접근할 수 있으며, 객체를 직접 참조/수정하거나 새로운 Result Payload를 생성할 수 없다.**
- **Intervention 신호는 StepResult와 분리된 상태 채널에만 기록된다.**

#### 🔒 3.1.2 Deterministic Hash Integration (LOCK)
ExecutionPlan에 `validators[]` / `postValidators[]` 필드가 추가되는 경우:
- `execution_plan_hash.ts`의 Deterministic Hash 계산 대상에 포함되어야 한다.
- 단, 함수 참조가 아닌 Validator Signature(`validator_id`, `validator_version`, `config_hash`, `policy_ref`) 기반으로 포함한다.
- 동일한 Execution 의미가 변경되었음에도 Hash가 유지되는 상황은 허용되지 않는다.
- Hash에서 Validator를 제외하는 경우, 그 근거와 의미 불변성 논리를 문서화해야 한다.
- **Validator 구현은 반드시 `validator_version` 또는 `logic_hash` 필드를 가져야 하며, 이는 stableStringify 대상에 포함되어야 한다.**
- **실행 의미(Validation Logic)가 변경되었으나 Signature가 동일한 상태는 허용되지 않으며, Validator는 순수 데이터(signature) 기반 정의만 허용된다. (런타임 외부 로직 참조 금지)**

#### 🔒 3.1.3 Intervention State Definition (LOCK)
InterventionRequired 상태는 Execution 실패 상태가 아니다.
- `status = "InterventionRequired"`는 Error 상태와 구분된다.
- Session Persistence(PRD-004) 구조를 변경하지 않는다.
- Intervention 상태는 기존 Session Pin 및 Hash 구조에 영향을 주지 않는다.
- Resume 시 기존 Plan을 재실행하며 StepResult를 변형하지 않는다.

---

### 3.2 Strategy Port 분리

Decision Retrieval 로직을 다음 인터페이스 기반으로 분리한다:
- `DecisionContextProviderPort`

Core는 전략 구현을 알지 못하고, 단순히 Port만 호출한다.

전략 예시:
- Hierarchical SQL Strategy (기존 방식)
- Semantic Vector Strategy
- Hybrid Graph Strategy

#### 🔒 3.2.1 Bundle Integrity Preservation (LOCK)
Retrieval Strategy 선택은 Runtime 임의 DI에 의해 결정되지 않는다.
- Strategy / Memory Provider 선택은 Bundle Manifest, Bundle Metadata, Session Pin Metadata 중 하나에 의해 고정되어야 한다.
- Bundle이 Promote된 이후 Strategy 구현은 변경될 수 없다.
- Pin된 Session은 동일한 Strategy 환경에서 재현 가능해야 한다.
- Runtime은 Port를 통해 구현체를 resolve할 수 있으나, 선택 권한은 Bundle 단위에 귀속된다. (PRD-018 Bundle-as-a-Unit 원칙 준수)
- **Strategy/Memory Provider ID는 BundlePinV1 또는 Bundle Manifest에 명시적으로 저장되어야 하며, Pin 구조에 해당 필드가 없을 경우 Strategy Injection은 허용되지 않는다.**

#### 🔒 3.2.2 Memory Ordering Preservation (LOCK)
Retrieval Strategy는 PRD-005의 Memory Loading Order를 변경할 수 없다.
- Policy Layer → Structural Layer → Semantic Layer 순서를 유지해야 한다.
- Strategy 교체는 데이터 선택 방식(Data Selection Strategy)만 변경할 수 있다.
- 상위 계층을 우회하거나, 하위 계층이 상위 계층을 override하는 구조는 허용되지 않는다.
- **`DecisionContextProviderPort`는 Retrieval Storage 접근을 추상화하는 계층이며, Hierarchical Merge Logic (Axis → Lock → Normal) 및 Scope Resolution 알고리즘은 Core에서 유지되어야 한다.**
- **Strategy 교체는 Storage 접근 방식(SQL / Vector / Hybrid)을 변경할 수 있으나, 알고리즘 전체 교체는 본 PRD 범위에 포함되지 않는다.**

---

### 3.3 Memory Provider Injection

`MemoryRepositoryPort`를 DI 기반으로 주입 가능하게 변경한다.

선택 방식은 다음 우선순위를 따른다:
1. Bundle Metadata (최우선)
2. Session Pin Metadata
3. Runtime Default (Fallback only)

Runtime config 단독 override는 허용되지 않는다. (단, Dev/RD 모드에서만 예외 허용 가능하며 이는 Bundle에 명시되어야 한다.)

---

## 4. Non-Goals

- Guardian 정책 로직 구현은 포함하지 않는다.
- Structural Graph DB 구현은 포함하지 않는다.
- Letta 자동 Anchor 연동은 포함하지 않는다.

본 PRD는 확장 포인트 개방에만 집중한다.

---

## 5. Architectural Impact

### Before
- Fixed Topology
- Hardcoded Retrieval
- Runtime-level Memory Injection

### After
- Execution Hook 기반 확장
- Strategy Injection 기반 Retrieval
- DI 기반 Memory Provider 선택

---

## 6. Acceptance Criteria

- Step Type 추가 없이 Guardian Hook 삽입 가능
- Retrieval Strategy 교체 시 Core 수정 불필요
- Memory Provider 선택이 정책 기반으로 가능
- 기존 기능(PRD-001~018)에 영향 없음
- **Execution Hook 추가 후 Plan Hash가 결정론적으로 변경됨**
- **Step Contract(PRD-007) 위반 없음**
- **Bundle Promotion(PRD-018) 재현성 유지**
- **Session Pinning 구조 영향 없음**

---

## 7. Risk Assessment

- **Medium-High (Core Contract Modification)**
- Hash, Pinning, Strategy Injection 교차 영역에 대한 회귀 테스트 필수
- PRD-012A / PRD-007 / PRD-018 재검증 필요

---

## 8. Phase Mapping

- Phase 6.5
- Roadmap Section: Core Extensibility & Execution Hook Refactor
