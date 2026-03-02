# **🚀 SYSTEM RUNTIME (02)**

이 문서는 LangGraph 기반 실행 엔진의 **구조와 계약(Contract)**을 정의한다. 본 시스템은 정책 중립적인 Core와 도메인 팩(Domain Pack)의 분리를 통해 무색무취의 오케스트레이션을 구현한다.

---

## [RUNTIME-LOCK] Web Runtime Surface Contract

본 런타임의 1차 실행 표면(Primary Execution Surface)은
Web Runtime Interface이다.

### 1. Surface 우선순위

- Web Runtime Surface가 공식 사용자 인터페이스이다.
- CLI는 Operator/Debug/Development 보조 레이어이다.
- CLI 전용 경로는 제품 기능으로 간주하지 않는다.

### 2. Completion Gate (Runtime Level)

런타임 차원에서 기능의 완료는 다음을 만족해야 한다:

1. Web Runtime에서 직접 호출 가능할 것
2. Web Session 상태와 통합될 것
3. Web UI를 통해 사용자 플로우로 재현 가능할 것

위 조건을 만족하지 못하는 기능은
Runtime Feature로 승격될 수 없다.

### 3. Architectural Guard

- 새로운 기능은 Web Handler / API Layer / UI Trigger 중
  최소 하나에 연결되어야 한다.
- CLI Command만 존재하는 기능은
  Runtime Feature Registry에 등록할 수 없다.

LOCK:
CLI 구현은 Runtime 실험 단계로만 허용되며,
Web Surface 통합 없이는 Feature Complete로 선언할 수 없다.

---

## **1. Runtime 역할 정의 (Executor vs Governance)**

*   **Executor (실행기)**: GraphState, Mode Router, Session Store를 관리하며 LLM 호출 및 프롬프트 조립을 수행한다.
*   **Governance (수호자)**: 번들 무결성 검증, 런타임-스키마 호환성 게이트, 가디언 루프(Guardian Loop)를 통한 정합성 검토를 수행한다.
*   **Non-blocking Principle**: 업무 실행 로직은 기본적으로 비차단 방식으로 작동한다. (상세는 4번 섹션 참조)

### **Guardian Loop: Sync vs Async Split (Latency Compatibility Contract)**

Non-blocking Principle을 보존하기 위해 Guardian Loop 검증은 2계층으로 분리된다:

- **Synchronous Critical Gate (Core Safety)**:
  번들 무결성(bundle_hash), 런타임-스키마 호환성, pin 파일 위변조 등
  Runtime Safety Contract 범위의 위반만 동기 검증 대상으로 간주한다.
  위반 시 Fail-fast/Abort는 허용된다.

- **Asynchronous Governance Checks (Policy/Heuristic)**:
  정책 정합성 평가, 위험도 추정, 사후 감사 준비, 경고/개입 신호 생성 등은
  비동기 처리로 분리되며 기본 실행 흐름을 차단하지 않는다.

이 분리는 성능 최적화가 아니라 Non-blocking 원칙을 유지하기 위한 구조적 계약이다.

### **1.x Hook Class Split Contract (SSOT)**

시스템의 Hook/Validator는 목적에 따라 2종으로 구분된다.

1) **Safety / Integrity Hook (SYNC / BLOCKING)**
- 구조 계약, 실행 무결성, 스키마 안전 위반을 다룬다.
- 실행 루프 내부에서 동기 실행된다.
- BLOCK은 실행을 중단(Fail-fast 또는 Intervention Return)할 수 있다.

2) **Guardian / Policy Hook (ASYNC / NON-BLOCKING)**
- 정책, 품질, 휴리스틱, 거버넌스 성격의 검사를 다룬다.
- 실행 흐름을 차단하지 않는다.
- BLOCK은 실행 중단 권한이 없다.
- BLOCK은 “interventionRequired” 메타데이터 기록으로만 사용된다.
- 개입은 다음 턴/다음 실행/UX 레벨에서만 유도된다.

LOCK:
- Guardian/Policy Hook의 BLOCK은 실행 단계 진행을 차단하거나 Step 흐름을 단축/우회하는 근거가 될 수 없다.
- Sync 확장을 “성능/품질 개선” 명목으로 실행 흐름에 추가할 수 없다.
- Hook은 GraphState/ExecutionPlan을 mutate할 수 없다.
- Hook 결과는 메타데이터 레이어에 한정된다.

### **Execution Latency Budget Principle**

Runtime은 비차단(Non-blocking) 원칙을 유지하기 위해 실행 단위 내 데이터 확장 및 검증 범위를 통제한다.

- Guardian의 동기(Synchronous) 검증은 Core Safety Contract 범위로 제한된다.
- Structural Impact Analysis는 명시적 관계 범위를 초과하여 확장되지 않는다.
- Retrieval은 실행 흐름을 변경하지 않는 Data Selection Layer로 유지된다.

LOCK:
성능 또는 품질 향상을 이유로 Execution Flow에 동기적 확장을 추가할 수 없다.

---

### Decision Capture Layer Boundary Contract

Decision Capture Layer는 Execution Flow의 일부가 아니다.

이는 Conversation Pre-processing Layer에 속하며,
Runtime Core의 Safety Contract,
Execution Hook 계층,
Guardian Layer와 구조적으로 분리된다.

- Capture Layer는 GraphState를 mutate하지 않는다.
- Capture Layer는 ExecutionPlan을 변경하지 않는다.
- Capture Layer는 Runtime Safety Contract의 대상이 아니다.
- Capture Layer는 Execution Latency Budget에 영향을 주지 않도록 설계되어야 한다.

LOCK:
Decision Capture는 Execution Layer로 승격될 수 없다.

---

## **2. Builder ↔ Runtime ↔ Promotion 구조**

*   **Builder (Control Plane)**: 아키텍트가 UI로 파이프라인 설계, HITL 테스트 수행, manifest.json 포함 **Workflow Bundle** 생성.
*   **Promotion Pipeline (Deployment)**: 빌더에서 검증된 번들을 런타임 활성 저장소로 밀어 넣는 승격 과정.
*   **Active Bundle Store**: 런타임이 참조하는 활성 번들 물리 위치 (`ops/runtime/bundles/active`).

---

## **3. Workflow Bundle 구조 (Technical Spec)**

단순 JSON이 아닌, 버저닝된 아티팩트의 뼈대이다.

*   **Identity**: bundle_id, bundle_version, bundle_hash (LOCK-11/17 Sorted Map Hash).
*   **Components**: prompts[] (.md), policies[] (.yaml), rubrics[] (.json).
*   **Runtime Scope**: routing (모드 규칙), steps (입출력 Contract).
*   **R&D vs Prod Switch**: rd(HITL 허용) vs prod(Judge AI 승인 주체화).

---

## **4. Runtime Safety Contracts (LOCK)**

실행 중 발생할 수 있는 정책의 오류나 무결성 침해로부터 시스템을 보호하는 하드코딩된 계약이다.

### **4.1 Core-enforced Fallback [LOCK-4]**
*   Judge AI의 판단 실패, 보류, 불확실성 발생 시, 시스템은 번들의 정책이 아닌 Runtime Core의 Fallback Contract(재시도/에스컬레이션/중단)를 강제로 따른다.

### **4.2 Hash Mismatch & Integrity Fail-fast**
*   **조건**: bundle_hash 무결성 불일치, 런타임-스키마 호환성 위반, pin 파일 위변조 감지.
*   **동작**: 시스템은 신규 번들 활성화를 중단(Abort)하고 직전 정상 Active Bundle을 유지하거나, 실행을 즉시 Fail-fast 한다. 이는 정책 판단과는 독립적이다.

### **4.3 Version Compatibility Gate [LOCK-15]**
*   `min_runtime_version`을 통해 번들과 런타임 엔진 간의 버전 호환성을 엄격히 검증한다.

※ 정책 정합성 위반(Guardian BLOCK)은 Safety Contract 위반으로 간주되지 않는다. 이는 실행 중단 사유가 아니라, 개입 요청 상태 전환 사유이다.

※ Guardian의 WARN/BLOCK은 정책/거버넌스 신호이며, Runtime Safety Contract 위반이 아닌 한 자동 실행 차단을 의미하지 않는다. BLOCK은 "Intervention Required" 상태 전환 사유로만 해석된다.

---

## **5. Session Pinning & Bundle Resolution**

*   **Session Pinning [LOCK-12]**: 세션은 시작 시점의 `bundle_version`에 고정(Pinned)되며 실행 중 변경되지 않는다.
*   **Bundle Resolver**: 어댑터 레이어에서 manifest를 읽어 Core에 필요한 컨텍스트를 주입한다.

### **Multi-Tenant Pin Scope Contract**

Bundle Pin은 반드시 Tenant Scope를 포함한 식별자 공간 내에서 해석된다.

- Pin 식별자는 최소한 `(tenant_id, bundle_id, bundle_version/hash)` 범위를 포함해야 한다.
- 전역 채널(stable/canary)은 "버전 포인터"일 뿐, Tenant Pin을 덮어쓰지 않는다.
- Tenant Pin은 불변 참조이며, Promotion은 새로운 버전 추가로만 표현된다.

LOCK:
Tenant Pin은 전역 번들 업데이트에 의해 암묵적으로 변경될 수 없다.

---

## **6. Extension Points (Revised Structure)**

### **6.1 Retrieval Strategy Injection**
*   **DecisionContextProviderPort** 기반 전략 주입.
*   Hierarchical / Semantic / Hybrid 전략 교체 가능.
*   **Data Selection Layer**에 해당하며, Execution Flow를 변경하지 않는다.

### **6.2 Execution Hook (Guardian Layer)**
*   **ExecutionPlan** 수준에서 실행 전/후 Validator Hook 호출.
*   Core는 훅을 호출하고 결과(ALLOW/WARN/BLOCK)를 해석만 한다.
*   Guardian은 ALLOW / WARN / BLOCK 신호를 생성할 수 있다. 단, BLOCK은 자동 실행 차단을 의미하지 않는다.
*   BLOCK은 “Intervention Required(추가 확인 필요)” 상태를 의미하며, Core는 이를 Human-in-the-loop 또는 명시적 override 승인 흐름으로 전환한다.
*   실행을 기술적으로 차단(Fail-fast)할 수 있는 권한은 오직 **Runtime Safety Contract**(무결성, 해시, 버전 호환성 위반 등)에 한정된다.
*   Retrieval Strategy와 다른 계층이다 (**Execution Layer**).

Guardian Loop는 Execution Hook 계층이며 Retrieval Strategy와 구분된다. Retrieval은 데이터 선택 전략이고, Guardian은 실행 전/후 검증 훅이다. Guardian의 BLOCK은 정책적 정합성 경고 수준의 개입 신호이며, Runtime Safety Contract 위반이 아닌 한 자동 실행 차단을 발생시키지 않는다.

### **Guardian–Retrieval Layer Isolation (Strict Boundary Contract)**

Guardian(Execution Hook 계층)은 Retrieval Strategy Injection(DecisionContextProviderPort) 계층에 개입할 수 없다.

- Guardian은 데이터 선택 전략을 변경할 권한이 없다.
- Guardian은 Loading Order [LOCK]를 동적으로 재정의할 수 없다.
- Guardian은 Structural Layer 또는 Semantic Layer의 탐색 범위를 확장/축소하지 않는다.

Guardian은 오직 실행 전/후 검증 신호(ALLOW/WARN/BLOCK)를 생성하는 역할에 한정된다.

LOCK:
Execution Hook는 Data Selection Layer의 동작을 변경하거나 우회할 수 없다.

### **Guardian State Mutation Prohibition (Execution Integrity Contract)**

Guardian(Execution Hook 계층)은 GraphState 또는 ExecutionPlan의 내부 상태를 직접 수정할 수 없다.

- Guardian은 상태를 변경하는 명령을 실행하지 않는다.
- Guardian은 Execution Flow를 재구성하거나 단계 순서를 변경하지 않는다.
- Guardian의 책임은 ALLOW / WARN / BLOCK 신호 생성에 한정된다.

LOCK:
Execution Hook는 GraphState를 mutate하거나 ExecutionPlan을 재작성할 수 없다.
Execution Flow 변경 권한은 오직 Runtime Core에만 존재한다.

- Safety Hook만 실행 중단 권한을 가진다.
- Guardian/Policy Hook은 실행 흐름 제어 권한이 없다.
- Hook 구현 방식(스레드/워커/큐 등)은 SSOT 범위가 아니며, SSOT는 권한과 효과만 정의한다.

### **6.3 ExecutionReceipt & Export Hook Placement (Extension Layer Only)**

ExecutionReceipt는 실행 단위의 해시 기반 참조 영수증이며, Core Execution Flow를 변경하지 않는 "추가 메타데이터"로만 취급한다.

- Receipt 생성은 Core 실행 흐름을 차단하지 않도록 설계된다.
- Receipt 확장 필드는 Extension Block 구조로만 수용한다.
- Export Hook은 Receipt를 외부로 내보내는 인터페이스이며, 기본 동작은 비동기/사후 처리로 분리될 수 있어야 한다.

LOCK:
Receipt/Export는 Execution Flow Control 권한을 갖지 않는다.
(Core Safety Contract 위반을 제외하고 실행 차단을 유발할 수 없다.)

---
*Last Updated: 2026-02-25 (Multi-Tenant & Latency Budget Hardening)*
