# B-021: Core Extensibility Contract

## 1. Execution Hook Contract

### 1.1 Purpose
ExecutionPlan에 도메인별 검증 로직(Guardian)을 Step Type 수정 없이 삽입하고, 실행 전/후 정합성을 체크하기 위함이다.

### 1.2 Invariant
- Hook은 **Read-only** 계층이다. Step의 입력(Input)이나 출력(Result)을 절대 수정할 수 없다.
- Hook은 `STEP_TYPES_CANONICAL_ORDER`를 변경하거나 특정 Step을 건너뛰는 등 실행 흐름을 제어할 수 없다.

### 1.3 Allowed
- StepResult에 대한 Read-only View 접근.
- 정해진 반환 스키마(`status`, `reason`, `evidenceRefs`) 준수.
- `state.intervention` 필드에 개입 요청 신호(BLOCK/WARN) 기록.

### 1.4 Forbidden
- StepResult 객체 직접 참조 및 멤버 변수 수정 (Mutation).
- 새로운 Result Payload 생성 또는 기존 Payload 삭제.
- Step 실행 흐름(Flow)의 단축 또는 우회.

### 1.5 Failure Mode
- Hook 내 예외 발생 시 시스템은 Fail-fast(Error) 처리한다.
- 잘못된 반환 타입(Schema Mismatch)은 Core Safety Contract 위반으로 간주하여 실행을 중단한다.

---

## 2. Deterministic Hash Contract

### 2.1 Purpose
Validator의 구성 변경이나 로직의 진화가 ExecutionPlan의 해시값에 결정론적으로 반영되도록 보장하기 위함이다.

### 2.2 Invariant
- 해시 계산 시 Validator의 함수 본문이 아닌 **Signature**(ID, Version, Config Hash)를 사용한다.
- `validator_version` 또는 `logic_hash`가 변경되면 반드시 Plan Hash가 변경되어야 한다.

### 2.3 Allowed
- `stableStringify` 대상에 Validator Signature 포함.
- 정해진 시그니처 필드(`validator_id`, `validator_version`, `config_hash`, `policy_ref`) 사용.

### 2.4 Forbidden
- Signature 필드를 누락한 상태에서의 Validator 추가/변경.
- 런타임 외부 코드(Unversioned Script 등)에 대한 동적 참조 포함.
- 동일한 로직 변경 시 시그니처를 업데이트하지 않는 행위.

### 2.5 Failure Mode
- Signature 누락 시 `execution_plan_hash` 생성 실패 (Fail-fast).
- 결정론적 재현 실패 시 Bundle Integrity Error 발생.

---

## 3. Strategy Port Contract (DecisionContextProviderPort)

### 3.1 Purpose
데이터 저장소(Storage) 접근 방식과 핵심 병합 알고리즘(Merge Logic)을 분리하여 저장소 기술 교체를 가능하게 함이다.

### 3.2 Invariant
- **Hierarchical Merge Logic** (Axis → Lock → Normal)은 반드시 Core(`decision_context.service.ts`)에서 수행되어야 한다.
- Port는 단순 Storage Access(Retrieve Raw Data)만을 담당하며, 우선순위 결정권이 없다.

### 3.3 Allowed
- SQL, Vector DB, Hybrid 검색 등 저장소 접근 방식 교체.
- 도메인별 Retrieval 필터(Scope, Domain) 주입.

### 3.4 Forbidden
- PRD-005의 Memory Loading Order (Policy → Structural → Semantic) 우회.
- 상위 계층 데이터를 하위 계층 검색 결과로 덮어쓰는(Override) 행위.
- 병합 알고리즘 전체를 외부 전략으로 대체하는 행위.

### 3.5 Failure Mode
- Memory Loading Order 위반은 Core Integrity 위반으로 간주한다.
- 해당 경우 Runtime Safety Contract에 따라 즉시 Fail-fast 처리한다.

---

## 4. Memory Provider DI Contract

### 4.1 Purpose
Bundle 및 세션 상태에 따라 적절한 Memory Repository를 동적으로 할당하면서도, 재현성(Reproducibility)을 유지하기 위함이다.

### 4.2 Invariant
- 모든 Provider 선택은 **Bundle Manifest** 또는 **BundlePinV1**에 명시된 ID에 의해 결정되어야 한다.
- Session이 시작되어 Pin된 이후에는 Provider ID를 변경할 수 없다.

### 4.3 Allowed
- Bundle Metadata에 기반한 Provider ID 명시.
- `BundlePinV1` 스키마 확장을 통한 ID 저장.

### 4.4 Forbidden
- Runtime Config를 통한 임의의 Provider Override (RD 모드 예외 제외).
- Pin 구조에 ID가 누락된 상태에서의 동적 주입.

### 4.5 Failure Mode
- 명시된 ID와 매칭되는 Provider가 없을 경우 초기화 실패 (Abort).
- Pin 정보와 런타임 환경 불일치 시 Integrity Error 발생.
