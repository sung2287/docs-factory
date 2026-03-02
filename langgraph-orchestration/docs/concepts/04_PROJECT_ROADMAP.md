# **🚀 PROJECT ROADMAP (04)**

본 문서는 Phase 0에서 시작하여 Phase 12까지의 의미적 진화 경로를 서술하며, 각 단계에서 무엇을 구축했고 무엇이 남았는지를 명확히 기록한다. 또한, 본 문서는 LangGraph 오케스트레이션 시스템의 **현 위치에서 [01 Master Blueprint](./01_Master_Blueprint.md) 완성 상태까지 가는 경로 지도**이다. 단순한 구현 목록이 아닌, 철학적 청사진을 현실화하기 위한 의미적 진화 단계를 정의한다.

> **📌 2026-02-26 전략 컨텍스트 추가**
> 본 시스템의 출발점은 **AI 코딩 병목 해결**이다. 비전공자가 코드를 직접 읽지 않고 AI와 협업할 때, 매 PRD마다 레포 전체 스캔 → 충돌 포인트 파악 → 컨텍스트 재설명의 반복이 핵심 병목이다. 이 시스템은 그 병목을 Decision SSOT + Atlas 구조로 제거하기 위해 설계되었다. 시스템이 완성되면 코딩 번들로 자기 자신을 검증하고, 이후 번들 마켓 → B2B → 소비자 순서로 확장한다.

---

## **I. Current Baseline (현 위치)**

시스템의 기초 인프라와 거버넌스가 확립되었으며, 1차 사용자 접점이 안정화된 상태이다.

### **I-1. Evolution History (Phase 0~6 Summary)**

#### Phase 0 – 철학 고정 ✅ 완료
- Doc-Bundle 철학 및 Agent Separation(조사-구현 분리) 원칙을 수립함.
- 시스템의 불변적 가치와 향후 확장 경로를 정의하여 아키텍처의 정체성을 확보함.

#### Phase 1 – Core Runtime Skeleton ✅ 완료
- 도메인 중립적(Domain-neutral) LangGraph 실행 엔진 및 Step Contract를 구현함.
- 세션 상태 구조를 정의하고 기본적인 워크플로우 제어 로직을 구축함.

#### Phase 2 – DocBundle Injection ✅ 완료
- `mode_docs.yaml` 기반의 문서 주입 및 Section Slice 구조를 도입함.
- LLM이 방대한 문서를 구조적으로 인식하고 필요한 맥락을 정확히 참조하도록 함.

#### Phase 3 – Decision/Evidence Engine ✅ 완료
- Versioned Decision Record 및 3층 메모리(Short/Long/Semantic) 모델을 확립함.
- 근거 기반 추론(Evidence Engine) 및 Hierarchical Retrieval을 통한 정합성을 확보함.

#### Phase 4 – (Reserved/Deferred) ☐ 계획 (Deferred to Phase 7)
- 복합 에이전트 라우팅 및 인지 레이어 통합을 위해 예약.
- Phase 7에서 Letta Anchor 연동을 통해 고도화된 형태로 구현 예정.

#### Phase 5.5 – Runtime Governance ✅ 완료
- Bundle Promotion 파이프라인 및 Deterministic Hash 기반의 무결성 검증을 도입함.
- 세션 고정(Pinning) 및 Core 수준의 Fail-fast 정책을 통해 시스템 신뢰도를 극대화함.

#### Phase 6 / 6A – UX Stabilization ✅ 완료
- Session Lifecycle 관리 및 Provider/Model Override UX를 React UI로 구현함.
- 실시간 스트리밍 렌더링 및 UI Observer를 통해 사용자 경험을 안정화함.

#### Phase 6.5 – Core Extensibility & Execution Hook Refactor ✅ 완료

**PRD-021: Core Extensibility Patch**

**구현:**
- ExecutionPlan에 `validators[]`, `postValidators[]` 확장 포인트 도입.
- Guardian을 Step Type 추가 없이 Execution Hook 계층으로 삽입 가능하도록 구조 개방.
- Retrieval Strategy를 `DecisionContextProviderPort` 기반 Strategy Injection 구조로 분리.
- Memory Provider 선택을 정책/번들 기반으로 확장 가능하도록 DI 구조 정비.

**의미:**
- Core가 "고정 토폴로지 엔진"에서 "확장 가능한 오케스트레이션 플랫폼"으로 진화 완료.
- 이후 Phase 7/8은 해당 확장 포인트를 실제로 사용하는 단계임.

---

## **II. Blueprint Gap Analysis (청사진 대비 부족 요소)**

- **Core Execution Hook 확장성 (PRD-021)**: ✅ 해결 완료.
- **Atlas Index Engine**: ✅ 구현 완료 (PRD-026).
- **Decision Capture Layer**: ✅ 구현 완료 (PRD-025).
- **Retrieval Strategy 검색 품질 고도화**: ✅ 구현 완료 (PRD-023).
- **WorkItem & Completion Engine**: ✅ 구현 완료 (PRD-027).
- **Domain Pack Library & Validation**: ✅ 구현 완료 (PRD-028).
- **Guardian YAML Wiring (Live Plan Injection Gap)**: ✅ 구현 완료 (PRD-030).
- **Persist Proposal (Ask-to-Commit)**: ✅ 구현 완료 (PRD-029).
- **Policy Registration Engine**: ✅ 구현 완료 (PRD-033).

## 🔒 Minimum Engine Completion Set (Core Operational Ready)

- PRD-026 — CLOSED
- PRD-025 — CLOSED
- PRD-022 — CLOSED
- PRD-023 — CLOSED
- PRD-027 — CLOSED
- PRD-028 — CLOSED
- PRD-030 -- CLOSED
- PRD-031 -- CLOSED
- PRD-032 -- CLOSED
- PRD-033 -- CLOSED
- PRD-034 -- CLOSED
- PRD-035 -- CLOSED

---

## III. Path to Blueprint Completion (확장 단계)

### **1. Phase 7 — Atlas Index Engine + Guardian Automation**

#### PRD-026: Atlas Index Engine
**상태: ✅ COMPLETED (2026-02-27)**

- Atlas 4대 인덱스 생성/갱신/조회 엔진 구현 완료
- Cycle-End 갱신 + Budget Enforcer + Deterministic Snapshot 확정
- Plan Hash와 Atlas Hash 완전 분리 유지

- **목표**:
  - Atlas Index(Structure / Contract / ConflictPoints / DecisionIndex) 생성·갱신·조회 엔진 구현
  - 부분 스캔 예산(scan_budget) / 화이트리스트 / 포인터 규칙을 Domain Pack 기반으로 집행하는 Enforcer 구현
  - PRD-022/023/025의 공통 기반 레이어 확보

- **핵심 산출물**:
  - Atlas SSOT 스키마 (Structure / Contract / Decision / ConflictPoints Index)
  - Index Build 초기화 파이프라인 (레포 최초 온보딩 시 Atlas 생성)
  - Index Update 루프 (Cycle 종료 시 fingerprint 기반 갱신)
  - Partial Scan Budget Enforcer (Domain Pack의 max_files / max_bytes / max_hops 집행)
  - Atlas 조회 API (PRD-022/023/025가 공통 사용)

- **LOCK**:
  - Atlas는 SSOT 인덱스이며 원문 데이터를 저장하지 않는다 (pointer + fingerprint만)
  - Index 갱신은 Cycle 종료 시점에만 수행 (실행 흐름 중 Atlas 직접 수정 금지)
  - Scan Budget 집행 권한은 Enforcer(코드)에만 있음 (LLM이 예산을 직접 변경 불가)

- **Acceptance Criteria**:
  - 레포 최초 온보딩 시 Atlas 4개 인덱스 정상 생성 확인
  - fingerprint 변경된 Artifact만 REVALIDATION_REQUIRED로 표시 확인
  - Domain Pack scan_budget 초과 요청 시 Enforcer가 차단 확인
  - PRD-022/023/025가 Atlas 조회 API를 통해 정상 동작 확인

> **Status:** CLOSED (Exit Criteria 6/6 통과)

---

#### PRD-022: Guardian Enforcement Layer
**상태: ✅ COMPLETED (2026-02-27)**

**구현 완료 사항:**
- Execution Hook 기반 Guardian Validator 도입 (preflight + post)
- `ValidatorFinding` 타입 도입 및 GraphState.validatorFindings append-only 구조 확정
- POLICY class WARN/BLOCK → InterventionRequired 전환 정책 구현
- SAFETY class BLOCK → 즉시 실행 차단 유지
- Evidence persistence는 PersistSession 단계에서만 수행 (Cycle-End SSOT 유지)
- logic_hash 기반 결정론적 재현 보장
- Plan Hash(PRD-012A)와 완전 분리 유지

**의미:**
- Guardian은 더 이상 “계획된 레이어”가 아니라 Core Engine Set의 일부
- PRD-025 Decision Commit Gate와 구조적으로 정합성 확보
- Atlas(026) → Guardian(022) → Decision(025) 삼각 구조 완성

**LOCK 확인:**
- StepResult mutation 금지 유지
- PlanHash 입력에 validatorFindings 포함 금지
- Atlas → Decision 자동 변경 루프 금지

---

### **2. Phase 7.5 — Decision Capture Layer + WorkItem Manager**

#### PRD-025: Decision Capture Layer
상태: ✅ COMPLETED (2026-02-27)

- Structured reason + root evidence Commit Gate 구현 완료
- DecisionVersion에 reason JSON 영속 저장
- InterventionRequired BLOCK 정책 구현
- Plan Hash와 Decision Payload 완전 분리
- Atlas 동기화는 PRD-026 Cycle-End 책임 유지

#### PRD-027: WorkItem Completion & VERIFIED Engine
상태: ✅ COMPLETED (2026-02-28)

- WorkItem v1 엔티티 (테이블 + 상태머신) 도입 완료
- 상태 전이 강제 (PROPOSED → ANALYZING → DESIGN_CONFIRMED → IMPLEMENTING → IMPLEMENTED → VERIFIED → CLOSED)
- completion_policy evaluator (Domain Pack 기반) 구현
- auto_verify_allowed 정책 지원 및 Atlas stale 시 auto-verify 차단 로직 적용
- 모든 전이 기록은 append-only 로그로 SSOT 관리

---

### **3. Phase 8 — Retrieval Intelligence Upgrade**

#### PRD-023: Retrieval Strategy 검색 품질 고도화
상태: ✅ COMPLETED (2026-02-28)

- **구현 성과**:
  - `DecisionContextProviderPort` 기반 Strategy Injection 구조 확립
  - `hybrid_v1` (Semantic + SQL 결합) 전략 도입 및 품질 벤치마크 통과
  - 검색 실패 시 `hierarchical_sql`로의 자동 폴백(Failover) 메커니즘 구축
  - 결정론적 결과 순서 보장 및 Plan Hash 분리 원칙 고수
- **의미**:
  - 단순 키워드 매칭을 넘어 맥락 기반의 고도화된 근거(Evidence) 탐색 가능
  - 시스템 안정성을 해치지 않으면서 검색 엔진의 점진적 개선 경로 확보

- **LOCK**:
  - Memory Loading Order 유지 (PRD-005)
  - Merge Logic은 Core 유지
  - Strategy/Provider 선택은 Bundle/Pin에 고정 (PRD-018)

---

### **3.5 Phase 8.5 — Runtime Enforcement & Auto-Capture Hardening**

이 단계는 웹 라이브 경로의 구조적 갭을 해소하여 E2E 도달성을 회복한 단계였다.

---

#### PRD-030: Guardian YAML Wiring (Plan Validator Injection)

상태: ✅ COMPLETED (2026-02-28)

**구현 완료 사항:**
- `ModeDefinition` 스키마 확장 (`validators`, `postValidators` 추가)
- `PolicyInterpreter`의 YAML 해석 및 `ExecutionPlan` 주입 로직 구현 완료
- `PlanHash` 계산 시 가디언 선언 정보 포함 (순서 SSOT 보장)
- 웹 런타임 경로에서도 Guardian wiring이 동작하도록 경로를 완성 (단, 실제 BLOCK 실증은 PRD-031/032에서 수행)

**의미:**
- 가디언 엔진(PRD-022)과 정책 선언(YAML) 사이의 마지막 연결 고리 완성
- 정책 로직(stub 제거)과 라이브 실증은 후속 PRD로 분리.

**LOCK 확인:**
- `validators`/`postValidators`는 `mode` 루트 레벨에만 위치 (LOCK-030-1)
- 선언 순서 기반 PlanHash 결정론 유지 (LOCK-030-2)
- 가디언의 Side-Effect 격리 (GraphState/Decision 직접 수정 금지) 준수

---

#### PRD-031: Guardian Rule Set Implementation (Live BLOCK Enablement)

상태: ✅ COMPLETED (2026-02-28)

**구현 완료 사항:**
- `GuardianAudit` 전용 감사 테이블 도입 및 영속화 경로 구축
- `BlockKey` (planHash, turnId, validatorId, targetRootId) 기반 무한 루프 방지 로직 구현
- `guardian.contract`, `guardian.evidence_integrity` 등 실제 BLOCK validator 로직 구현
- `MinimalPersistenceRecordV1` 및 `GuardianAuditRecordV1` 감사 스키마 확정

**의미:**
- 단순 Wiring(PRD-030)을 넘어 실질적인 정책 집행 및 감사 추적 기능 확보
- 무결성 위반 시 안전한 차단 및 시스템 인지(Informed Block) 메커니즘 완성

**LOCK 확인:**
- `GuardianAudit`은 정규 SSOT와 분리된 감사 전용 저장소로 운영
- 가디언은 `GraphState`/`Decision` 직접 수정 금지 원칙 고수
- `BlockKey` 판단은 DB 조회를 SSOT로 사용 (인메모리 배제)

---

#### PRD-032: Live Validation Harness & Seed Data Stabilization

상태: ✅ COMPLETED (2026-02-28)

**구현 완료 사항:**
- Seed Run 시나리오 4종(Guardian/Decision/WorkItem/Atlas) 정의 및 자동화
- 동일 입력 반복 실행 시 `PlanHash`, `snapshotId`, `InterventionRequired` 판정 일관성 검증 완료
- `freshSession=true` 조건에서의 결정론적 재현성(Determinism) 3회 연속 통과
- DB 데이터 관계 무결성 및 세션 재로드 검증 프로세스 구축

**의미:**
- 엔진의 핵심 무결성(Hash/Storage/Atlas)이 실제 런타임 사이클에서 안정적으로 유지됨을 실증
- 향후 기능 추가 시의 회귀 테스트를 위한 표준 데이터 세트 및 검증 하네스 확보

**LOCK 확인:**
- `snapshotId` 및 `atlasFingerprint` 식별자 격리 준수
- 검증 실패 시 `PersistSession` 재시도 금지 정책 적용
- 가디언 Findings의 해시 입력 제외 원칙 재검증 완료

---

#### PRD-029: Persist Proposal (Ask-to-Commit)

상태: ✅ COMPLETED (2026-02-28)

**구현 완료 사항:**
- `InterventionRequired(source="PLANNER")` 기반 제안-승인 표준 흐름 구현
- `(conversationId, turnId, targetRootId)` 3-tuple 멱등성 검증 로직 도입
- `evidence.conversationTurnRefs(minItems:1)` 강제를 통한 근거 기반 영속화 확립
- `PersistSession` 이전 DB write 0회 보장 및 해시 격리 검증 완료

**의미:**
- 플래너의 권한 경계(Authority Boundary)를 명확히 하고, 사용자의 명시적 승인 하에만 상태를 확정하는 안전 장치 확보
- 중복 영속화 방지 및 결정론적 세션 이력 관리 체계 완성

**LOCK 확인:**
- `executePlan` 내부 직접적인 DB write 차단 준수
- 3-tuple 기반 멱등성 판별 SSOT 확정
- 제안 생성 행위의 `PlanHash` 독립성 유지

---

#### PRD-033: Policy Registration Engine (Decision -> Policy Promotion)

상태: ✅ COMPLETED (2026-03-01)

**구현 완료 사항:**
- CLI 기반 정책 등록 엔진(Registration Executor) 구현 완료
- `PolicyEntity` 스키마 및 결정론적 `PolicyHash` 사양 확정
- `(rootId, version)` 기반의 엄격한 버전 체인 및 Idempotency 규칙 적용
- Eligibility(상태)와 Registration Execution(행위)의 명확한 경계 분리
- **Target Architecture 명시:** Registration Executor는 구현 완료(현재 CLI로 실행). 웹 런타임에서는 post-run에서 eligibility/materialization까지만 자동으로 생성되며, 실제 registration execution 자동화는 후속 과제로 Gap 관리.

**의미:**
- 승인된 결정을 시스템 정책으로 승격할 수 있는 공식적인 "등록 관문" 확보
- 정책의 이력 관리 및 버전 재현성을 보장하는 데이터 레이어 완성

**LOCK 확인:**
- `executePlan` 루프 외부에서만 등록 실행 보장
- `PersistSession` 트랜잭션과 독립적인 원자적 트랜잭션 처리
- `policy.*` scope 결정을 유일한 승격 트리거로 사용

---

#### PRD-034: Policy Modification & Conflict Resolution Flow

상태: ✅ COMPLETED (2026-03-02)

**구현 완료 사항:**
- POLICY 위반 감지 시 `InterventionRequired`를 통한 구조화된 충돌 보고서 및 선택지 제시 로직 구현
- 사용자 승인/거부/수정 입력에 따른 `DecisionVersion` 신규 생성 및 체인 관리 확립
- 정책 수정 시 기존 결정을 Overwrite하지 않고 신규 버전을 생성하는 이력 보존(Audit Trail) 메커니즘 적용
- 정책 변경은 DecisionVersion으로 커밋되며, 정책 효력(adoption)은 차기 세션에서만 반영 (Next-session effect)
- 현 세션의 ExecutionPlan은 재계산/변경하지 않음 (No retroactive mutation)

**의미:**
- 시스템의 가이드라인(Policy)이 고정된 벽이 아니라, 사용자와의 협의를 통해 진화할 수 있는 유연한 거버넌스 루프 완성
- 지원되는 정책 수정 계약(KEEP/MODIFY/REGISTER) 범위 내에서는 코드 수정 없이 대화+결정으로 정책을 진화시킬 수 있는 루프를 확보.

**LOCK 확인:**
- 정책 수정 시 항상 신규 `DecisionVersion` 생성 및 `parentVersion` 연결 준수 (Append-only)
- SAFETY 클래스(보안/파괴적 행위)는 수정 흐름에서 원천 차단 유지
- `KEEP_POLICY`는 정책 진화 이벤트가 아니며, 감사 로그(`POLICY_ACKNOWLEDGED`)만 생성
- `PlanHash` 계산 규칙에 영향 없음 (No PlanHash change)

---

#### PRD-035: Policy Decision Core Unlock & Wiring Completion

상태: ✅ COMPLETED (2026-03-02)

**구현 완료 사항:**
- `policy.<profile>.<mode>` 형식의 엄격한 3-segment 가드 및 prefix allowlist 도입 완료
- `interventionResponse.action` (MODIFY/REGISTER/KEEP) → `PersistDecision` 배선 공식화
- 정책 수정 시 `registeredPolicyRootId`만을 유일한 SSOT Seed로 사용하는 root 고정 메커니즘 확립
- `KEEP_POLICY` 선택 시 결정 생성 없이 오직 감사 로그(`POLICY_ACKNOWLEDGED`)만 남기는 invariant 준수
- 정책 외 일반 실행 시 `PlanHash` 알고리즘 회귀 없음(Regression Pass) 확인

**의미:**
- 엔진 코어의 잠금을 해제하여 PRD-034의 정책 수정 흐름이 실제 런타임에서 종단 간(E2E) 실행 가능해짐 (Core unlock: policy scope validation + intervention wiring)
- 사용자 개입 채널과 결정 영속화 레이어 간의 배선이 완료되어 "대화를 통한 정책 진화"의 기술적 토대 완성

**LOCK 확인:**
- `executePlan` 내부 DB 직접 쓰기 금지 유지
- `PlanHash` 계산 시 정책 결정 데이터(intervention findings) 제외 원칙 고수
- `APPROVE`/`REJECT` 신호는 결정 계층으로 승격되지 않고 오직 게이트 제어로만 작동
- SAFETY 클래스 위반은 수정 흐름에서 원천 차단 유지

---

구현 순서 (완료):
1) PRD-032 (Live Validation Harness & Seed Data: 검증 완료)
2) PRD-033 (Policy Registration Engine: 엔진 구축 완료)
3) PRD-034 (Policy Modification Flow: 정책 수정 루프 확정)
4) PRD-035 (Core Unlock & Wiring Completion: 코어 배선 및 잠금 해제 완료)

---

### **4. Phase 9 – 인지 지능 고도화 (Letta Anchor 연동) 🔵 계획**
- **목표**: 대화 압축 중 Anchor 자동 감지 및 Retrieval 시 원문 확인 강제 워크플로우 구현.
- **의미**: "기억하는 수석 아키텍트"로서의 인지 뼈대 완성.

---

### **5. Phase 10 – 에이전틱 거버넌스 확립 (Agent Separation) 🔵 계획**
- **목표**: Research(Gemini)와 Implementation(Codex)의 물리적 역할 분리 및 근거 기반 승인 루프 강제.
- **의미**: 추측에 의한 구현을 차단하고 설계 정합성을 수호하는 시스템 신뢰도 확보.

---

### **6. Phase 11 – 멀티모달 및 범용 인터페이스 🔵 계획**
- **목표**: `InputEvent` 및 `Output Artifact` 추상화, 멀티모달 지원 메시지 스키마 도입.
- **의미**: 도메인 중립성을 넘어 인터페이스 중립성을 확보하여 범용 오케스트레이터로 진화.

---

### **7. Phase 12 – Infrastructure Forward-Slot Preparation 🔵 계획**

이 단계는 기능 구현 단계가 아니다. 확장 불가능성을 제거하기 위한 구조 정비 단계이다.

---

## ✅ Phase 12-A — Structural Safety Seal (Completed)

**상태:** ✅ Completed (2026-02-25)

**핵심 결과:**
- Seal-A/B/C/D 구조적 경계 봉인 확정
- Guardian Sync/Async Split 구현 완료
- Policy BLOCK → Non-blocking + Core-driven intervention
- HookClass 기반 분기 체계 도입
- 실행 흐름 제어 권한은 Safety Hook에만 허용

#### PRD-024: Structural Safety Seal ✅ 완료

---

## ✅ Phase 12-B — Domain Pack Library & Infrastructure Preparation

**상태:** ✅ Completed (2026-02-28)

#### PRD-028: Domain Pack Library + Pack Validation
- **구현 내용**:
  - AtlasDomainPack v1 스키마 표준화 (`scan_budget`, `conflict_points` 등)
  - `PolicyInterpreter` 단계에서의 Fail-fast Validation 엔진 구현
  - Domain Pack의 ExecutionPlan inline 주입 및 Hashing 격리 보장
  - Top-level allowlist 자동 마이그레이션 로직 포함
- **의미**:
  - 도메인 지식의 파편화를 막고 구조화된 팩 단위의 관리/배포 체계 확립
  - 런타임 진입 전 설정 오류를 차단하여 시스템 신뢰도 향상

- Future Vault/PII Isolation Slot: Decision 구조에 `vaultRefs` 확장 필드 사전 확보 (외부 암호화 계층 대비, PlanHash/AtlasHash와 payload 결합 금지).

## Phase X — Multi-Domain Orchestrator (Planned)

- 목적: 유저 입력 기반 자동 도메인 라우팅 레이어 도입
- 원칙: Router-only (Commit / WorkItem 상태 변경 권한 없음)
- 정책: Confidence 기반 자동 전환 + 애매 시 사용자 확인
- 전제: PRD-026/025/022/028 안정화 이후 착수
- 비고: 엔진 SSOT 및 Enforcer 체계를 침해하지 않는 상위 UX 레이어

---

## **IV. 번들 전략 로드맵** *(2026-02-26 신규 추가)*

> 시스템 완성 이후 번들 경제로 확장하는 단계별 전략이다. 시스템 구현이 선행되어야 하며, 코딩 번들이 첫 번째 검증 케이스가 된다.

### **Step 1 — 코딩 번들 자기 검증**
- 본인의 코딩 워크플로우를 첫 번째 번들로 온보딩
- AI 코딩 병목(매 PRD마다 레포 전체 스캔 반복) 해소 여부 직접 검증
- "이거 없으면 불편하다"는 느낌이 오면 다음 단계 진행

### **Step 2 — 회사 직원 베타 테스트**
- 다양한 도메인(개발/기획/운영 등)으로 번들 구조화 패턴 수집
- 도메인별 온보딩 플레이북 초안 작성
- 실패 케이스 안전하게 수집 및 시스템 개선

### **Step 3 — 번들 마켓 공개 & 생태계 형성**
- 성공 케이스 기반으로 공개
- 전문가가 자신의 워크플로우를 번들로 올리고 수익화하는 구조 제공
- 사용량 임계점 도달한 번들에 대한 내부 플래그 시스템 운영

### **Step 4 — 번들 저작권 매입 & B2B 패키징**
- 검증된 번들의 로직 사용 권리 매입 (개인 데이터 제외)
- 현금 + 무료 이용권 조합으로 전문가 만족도 확보
- 도메인별 번들 합성 (예: 법률 전문가 N명의 Decision 큐레이션 → 법률 도메인 번들)
- 기업 대상 B2B 패키징 및 판매

### **Step 5 — 소비자 단순화**
- B2B에서 검증된 번들을 "딸깍" 수준으로 단순화
- 일반 소비자용 비서 엔진으로 이식

---

## **Appendix**

### **A. PRD 상태 매핑 (Full History)**

| 번호 | 제목 | 상태 | 해당 Phase |
|:---|:---|:---|:---|
| PRD-001 | Core Orchestration Engine Base | COMPLETED | Phase 1 |
| PRD-002 | Domain Router & Mode Config | COMPLETED | Phase 1 |
| PRD-003 | Basic Session State Structure | COMPLETED | Phase 1 |
| PRD-004 | Session Persistence | COMPLETED | Phase 1 |
| PRD-005 | Decision Evidence Engine | COMPLETED | Phase 3 |
| PRD-006 | Storage Layer SQLite v1 | COMPLETED | Phase 1 |
| PRD-007 | Step Contract Lock | COMPLETED | Phase 1 |
| PRD-008 | PolicyInterpreter Contract | COMPLETED | Phase 1 |
| PRD-009 | LLM Provider Routing | COMPLETED | Phase 6 |
| PRD-010 | Session Lifecycle UX | COMPLETED | Phase 6 |
| PRD-011 | Secret Injection UX | COMPLETED | Phase 6 |
| PRD-012 | Provider Model Override UX | COMPLETED | Phase 6 |
| PRD-012A | Deterministic Plan Hash | COMPLETED | Phase 5.5 |
| PRD-013 | Minimal Web UI Observer | COMPLETED | Phase 6 |
| PRD-014 | Web UI Framework Introduction | COMPLETED | Phase 6 |
| PRD-015 | Chat Timeline Rendering v2 | COMPLETED | Phase 6 |
| PRD-016 | Session Management Panel | COMPLETED | Phase 6 |
| PRD-017 | Provider/Model/Domain UI Control | COMPLETED | Phase 6A |
| PRD-018 | Bundle Promotion Pipeline | COMPLETED | Phase 5.5 |
| PRD-019 | Dev Mode Overlay | COMPLETED | Phase 6A |
| PRD-020 | Extensible Message Schema | PLANNED | Phase 11 |
| PRD-021 | Core Extensibility Patch (Execution Hook & Strategy Port) | COMPLETED | Phase 6.5 |
| PRD-022 | Guardian Enforcement Layer | COMPLETED | Phase 7 |
| PRD-023 | Retrieval Intelligence Upgrade | COMPLETED | Phase 8 |
| PRD-024 | Phase 12-A Structural Safety Seal | COMPLETED | Phase 12-A |
| PRD-025 | Decision Capture Layer | COMPLETED | Phase 7.5 |
| PRD-026 | Atlas Index Engine | COMPLETED | Phase 7 |
| PRD-027 | WorkItem Completion & VERIFIED Engine | COMPLETED | Phase 7.5 |
| PRD-028 | Domain Pack Library + Pack Validation | COMPLETED | Phase 12-B |
| PRD-029 | Persist Proposal (Ask-to-Commit) | COMPLETED | Phase 8.5 |
| PRD-030 | Guardian YAML Wiring | COMPLETED | Phase 8.5 |
| PRD-031 | Guardian Rule Set Implementation | COMPLETED | Phase 8.5 |
| PRD-032 | Live Validation Harness & Seed Data Stabilization | COMPLETED | Phase 8.5 |
| PRD-033 | Policy Registration Engine | COMPLETED | Phase 8.5 |
| PRD-034 | Policy Modification & Conflict Resolution Flow | COMPLETED | Phase 8.5 |
| PRD-035 | Policy Decision Core Unlock (scope allowlist + intervention wiring) | COMPLETED | Phase 8.5 |

### **B. Definition of Done (DoD)**
모든 단계는 [01 Master Blueprint](./01_Master_Blueprint.md)의 철학을 준수해야 하며, Core 수정 없이 번들/정책 수준에서 확장이 가능해야 함.

---
*Last Updated: 2026-03-02 (PRD-035 CLOSED)*

---

## Phase-8 (Operational Hardening – Deferred)

다음 항목들은 기능 완성 이후 운영 안정성 강화를 위해 재검토할 사항이다:

- Atlas ensureInitial 동시성 제어 (Advisory Lock 도입 여부)
- Atlas Stale 장기 누적 감시 및 자동 복구 전략
- 대규모 레포지토리 스캔 성능 스트레스 테스트
- Snapshot 재빌드 오케스트레이션 전략

본 항목은 현재 기능 설계를 변경하지 않으며,
운영 하드닝 단계에서만 다룬다.
