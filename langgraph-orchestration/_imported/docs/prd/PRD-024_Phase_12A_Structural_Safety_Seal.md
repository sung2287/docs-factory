# PRD-024: Phase 12-A Structural Safety Seal (Seal Only)

## 1. Objective
- Phase 12-A의 구조적 확장 대비(소켓) 4개를 “Seal(봉인)”로 선언한다.
- 본 PRD는 기능 구현 추가가 아니라, 이미 확립된 계약을 PRD 레포 기준으로 고정/참조 가능하게 만드는 목적이다.

## 2. Non-Goals (Scope Guard)
- 코드 기능 확장 요구 없음
- Core Execution Flow 변경 요구 없음
- Receipt 저장 확대/감사 시스템 구현 금지
- Risk 차단 로직 구현 금지
- 서명/검증 인프라 구현 금지

## 3. SSOT References (Docs Repository is SSOT)
SSOT는 별도 문서 레포의 아래 문서에 존재한다. (본 PRD는 링크/앵커만 제공하며 본문을 복제하지 않는다.)

- SSOT: docs/concepts/02_SYSTEM_RUNTIME.md
- SSOT: docs/concepts/03_MEMORY_MODEL.md

### Anchor Map (SSOT 섹션 기준)
- **Receipt 계약 정본**: 02_SYSTEM_RUNTIME.md / 6.3 ExecutionReceipt & Export Hook Placement
- **Pin/Resolution 정본**: 02_SYSTEM_RUNTIME.md / 5 Session Pinning & Bundle Resolution (+ Multi-Tenant Pin Scope Contract)
- **Guardian 경계 정본**: 02_SYSTEM_RUNTIME.md / 1.x Hook Class Split Contract (SSOT)
- **Graph Boundary 정본**: 03_MEMORY_MODEL.md / 3.3 Structural Layer (Impact Analysis) + Boundary/Cycle/Subgraph Principles
- **High-Volume 원칙 정본**: 03_MEMORY_MODEL.md / 2 Decision Versioning & High-Volume Decision Scalability Principle
- **Loading Order/Cost Control 정본**: 03_MEMORY_MODEL.md / 4 Retrieval Architecture (Loading Order, Cost Control)

## 4. Seal Statements (LOCK)
아래 4개는 “구현 요구”가 아니라 “경계 봉인”이다. 위반되는 변경은 설계/PRD 먼저 갱신되지 않는 한 거부된다.

### 4.1 [SEAL-A] ExecutionReceipt Canonical / Extension Block / No Flow Control
- ExecutionReceipt는 실행 단위의 해시 기반 참조 영수증이며, Core Execution Flow를 변경하지 않는 메타데이터 레이어이다.
- Extension Block 구조만 허용한다.
- **LOCK**: Receipt/Export는 Execution Flow Control 권한을 갖지 않는다. (Core Safety Contract 위반 제외)

### 4.2 [SEAL-B] Bundle Pinning & Version Chain Governance
- Session Pinning은 실행 중 변경될 수 없다.
- Decision은 overwrite가 아니라 새 version으로만 변경된다.
- Semantic Versioning은 운영 규범으로 채택한다.
- **LOCK**: Tenant Pin은 전역 번들 업데이트에 의해 암묵적으로 변경될 수 없다.

### 4.3 [SEAL-C] Guardian Layer Isolation
- Guardian은 Retrieval 전략에 개입할 수 없다.
- Guardian은 GraphState/ExecutionPlan을 mutate할 수 없다.
- Sync/Async split은 Non-blocking 원칙 유지를 위한 구조적 계약이다.
- Guardian/Policy Hook의 BLOCK은 동일 실행 루프에서 Step 진행을 차단하지 않는다.
- BLOCK은 “intervention required” 메타데이터 기록으로만 사용되며, 실행 흐름 제어 권한을 갖지 않는다. (Core Safety Contract 위반 제외)
- **LOCK**: 성능/품질을 이유로 동기적 확장을 Execution Flow에 추가할 수 없다.

#### 4.3.1 Implementation Locks (Core-Driven, Non-blocking) (LOCK)

- **LOCK-C1 (Policy BLOCK Non-Blocking)**
  Guardian/Policy Hook의 BLOCK은 동일 실행 루프에서 실행을 중단할 수 없다.
  다음 행위는 모두 금지된다: `throw`, `return`, step skip/short-circuit.
  Core는 BLOCK을 해석하여 오직 `interventionRequired` 신호로만 반영한다.

- **LOCK-C2 (Snapshot Input + Pure Result)**
  Guardian은 항상 Snapshot 입력(불변 스냅샷)만 받으며, GraphState/ExecutionPlan에 대한 writable reference를 획득할 수 없다.
  Guardian은 순수 결과 객체(예: ALLOW/WARN/BLOCK + reason)만 반환한다.
  `interventionRequired` 기록은 Guardian이 아니라 Core가 수행한다.

- **LOCK-C3 (Single Source of HookClass Routing)**
  Safety/Integrity Hook(SYNC/BLOCKING)과 Guardian/Policy Hook(ASYNC/NON-BLOCKING)의 분기 기준은 반드시 명시적 `HookClass`(또는 동등한 단일 필드)로만 결정된다.
  reason 문자열, evidenceRefs, validator_id 패턴 등 휴리스틱 기반 분기는 금지된다.
  HookClass는 실행 계획 해시/정규화에 포함되어야 한다.

### 4.4 [SEAL-D] Structural Graph Boundary & Cycle Safety
- Impact Analysis는 명시적 관계 그래프 범위 내에서만 수행된다.
- Cycle이 있어도 무한 반복 탐색을 수행하지 않는다.
- Subgraph 범위 내에서만 분석한다.
- **LOCK**: Structural 분석은 Semantic Layer 탐색으로 확장되거나 Loading Order를 우회하는 근거가 될 수 없다.

### 4.5 🔒 POLICY Hook Execution Semantics LOCK (Seal Reinforcement)

#### 1. Execution Flow Authority Boundary
- Execution Flow를 중단(throw/abort/early return)할 수 있는 권한은 **SAFETY Hook에만** 존재한다.
- POLICY Hook는 어떤 경우에도 Execution Flow를 중단할 수 없다.
- POLICY BLOCK은 자동 실행 차단을 의미하지 않는다.

#### 2. Non-Blocking Enforcement
- POLICY Hook의 결과(ALLOW/WARN/BLOCK)는 Execution Flow를 변경하지 않는다.
- BLOCK 결과는 `InterventionRequired` 메타데이터로만 기록된다.
- POLICY Hook는 return/throw를 통해 Step 실행을 중단할 수 없다.
- POLICY Hook는 StepResult 또는 ExecutionPlan을 변형할 수 없다.

#### 3. Mutation Prohibition
- POLICY Hook는 GraphState를 변경할 수 없다.
- POLICY Hook는 StepResult payload를 수정할 수 없다.
- POLICY Hook는 Retrieval 결과를 재작성하거나 교체할 수 없다.
- POLICY Hook는 ExecutionReceipt Core 필드를 변경할 수 없다.
- POLICY Hook의 출력은 반드시 Extension Block에만 기록되어야 한다.

#### 4. Deterministic Integrity Guarantee
- HookClass(SAFETY / POLICY)는 execution_plan_hash 계산에 반드시 포함되어야 한다.
- 동일 입력 + 동일 Hook 구성에서는 POLICY 결과가 결정론적으로 재현 가능해야 한다.
- POLICY Hook의 signature/logic_hash 변경은 Plan Hash에 반영되어야 한다.
- Hook 순서 또한 Hash 계산에 포함되어야 한다.

#### 5. Side-Channel Isolation
- POLICY 결과 수집은 Sidecar 방식으로 수행되어야 한다.
- executePlan 내부에서 POLICY 결과는 지역 변수로 수집되고, 최종 반환 시 ExecutionReceipt Extension Block에 병합된다.
- POLICY Hook는 Core Execution 경로에 직접 개입할 수 없다.

#### 6. Guardian Layer Isolation Alignment
본 LOCK은 다음 불변 조건과 정합을 유지한다:
- Guardian은 Retrieval Layer에 개입할 수 없다.
- Guardian은 GraphState를 변경할 수 없다.
- Guardian은 Non-blocking 원칙을 위반할 수 없다.
- SAFETY와 POLICY는 명확히 분리된 권한 체계를 유지한다.

**Structural Meaning**
이 봉인은 다음을 보장한다:
- POLICY는 "통제 신호"이지 "실행 제어기"가 아니다.
- Core Execution Engine은 정책 판단과 흐름 제어를 구조적으로 분리한다.
- Intervention은 Flow Control이 아닌 Governance Signal이다.

이로써 Execution 의미 체계는 완전히 봉인되며, 향후 Guardian/Validator 확장은 Core 수정 없이 수행 가능하다.

## 5. Compliance Checklist (PR Review)
- [ ] Policy/Guardian BLOCK이 throw/return/step-skip으로 실행 흐름을 끊는가? → **Reject**
- [ ] Guardian이 writable state reference를 획득 가능한 경로가 있는가? → **Reject**
- [ ] HookClass 분기가 휴리스틱(reason/ID 패턴 등)에 의존하는가? → **Reject**
- [ ] Policy/Guardian BLOCK이 실행 루프에서 즉시 중단(return/throw)으로 연결되는가? → **Reject**
- [ ] Safety/Integrity Hook과 Guardian/Policy Hook의 구분이 계약 문서에 명시되지 않는가? → **Reject**
- [ ] Guardian이 Retrieval 전략/탐색 범위를 변경하는가? → **Reject**
- [ ] Guardian이 GraphState/ExecutionPlan을 수정하는가? → **Reject**
- [ ] Receipt/Export가 실행 흐름을 차단/제어하는가? → **Reject**
- [ ] Decision overwrite(기존 버전 덮어쓰기)를 허용하는가? → **Reject**
- [ ] Structural 분석이 전체 그래프 전량 탐색/무제한 전파를 수행하는가? → **Reject**
- [ ] Loading Order 우회가 발생하는가? → **Reject**

## 6. Change Policy
- Seal 변경이 필요하면: (1) 문서 레포 SSOT(02/03) 먼저 수정 → (2) 본 PRD-024를 동일하게 갱신한다.
- 본 PRD는 SSOT 복제 문서가 아니라 “봉인 및 참조 앵커”이다.
