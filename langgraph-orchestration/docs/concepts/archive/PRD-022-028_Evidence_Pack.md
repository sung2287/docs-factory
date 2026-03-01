PRD-023~028 Evidence Pack (Repo 조사 기반 요약)

> PRD-025 and PRD-026 are now CLOSED and treated as architectural invariants.
> Subsequent PRD-022/023/027/028 설계 시 이 항목들은 재검증 대상이 아니다.
> Atlas Snapshot Determinism, Budget FailFast Classification, and Decision-Loop Isolation are now architectural invariants.
> ⚠ Concurrency, Default Allowlist Policy, and Stale Accumulation require Phase-8 hardening confirmation but do not invalidate PRD-026 invariants.

0) 공통 결론 3줄 (SSOT/삽입지점/해시)

Cycle End SSOT는 PersistSession Step: Atlas 갱신/스냅샷 커밋의 기준점은 여기로 고정.

Atlas 저장은 SQLite 신규 테이블이 안전 축: 파일 SSOT는 원자성 깨짐 위험이 큼.

Plan Hash(PRD-012A)와 Atlas Hash와 완전 분리: Atlas 해시를 plan hash 입력에 넣으면 철학/UX 충돌이 큼.

(Exit Criteria 상에서도 PRD-026은 Atlas 4대 인덱스 + cycle 종료 갱신 + budget enforcer + deterministic 재현을 요구함. 

EXIT_CRITERIA_PRD023-028

)

1) 레포 “핵심 코드 지형도” (PRD-023~028 공통으로 건드리게 될 구역)
A. 실행/라이프사이클 (Cycle 시작~종료)

src/core/plan/plan.types.ts : ExecutionPlanV1, GraphState(상태 SSOT) 정의

src/core/plan/plan.executor.ts : executePlan 메인 루프, validators/postValidators 흐름

runtime/orchestrator/run_request.ts : 진입점, 번들 핀 고정, 세션 해시 검증, runGraph 호출

runtime/graph/graph.ts : runGraph, executePlan 래핑

runtime/graph/plan_executor_deps.ts : executePlan에 주입되는 deps 구성

B. 상태 mutation/핵심 Step 실행부

src/core/plan/step.registry.ts : applyPatch 기반 불변 업데이트(상태 누적의 핵심)

src/core/plan/plan.handlers.ts : RepoScan/Retrieval 등 Step executor 구현

C. 해시/핀(결정론)

src/session/execution_plan_hash.ts : computeExecutionPlanHash (plan+policy+metadata → stable stringify → sha)

src/session/stable_stringify.ts : 해시 입력 직렬화 안정화

src/session/bundle_pin.store.ts : bundle pin 저장/로드

(telemetry 기록도 run_request에서 함께 수행되는 것으로 조사됨)

D. 스캔(예산 강제 삽입 후보)

src/plugin/repository/scanner.ts : scanRepository / walkDirectory (실제 FS 순회)

조사 결과: 현재 budget abort 로직은 없음(Abort NONE) → 여기 넣으면 Fail-fast 전파는 설계상 가능.

E. SQLite 저장/버전 체인

src/adapter/storage/sqlite/sqlite.storage.ts : 스키마/테이블 정의(Decision/Evidence 등)

src/adapter/storage/sqlite/sqlite.stores.ts : DecisionStore/EvidenceStore + createNextVersionAtomically(버전 체인 원자성)

조사 결과: root별 active 단일 보장(UNIQUE WHERE is_active=1), 트랜잭션(BEGIN/COMMIT), evidence link(M:N) 구조.

### 0.1 Minimum Engine Completion Set
다음 3개 PRD가 엔진의 최소 작동 세트(Core Set)를 구성한다.
- **PRD-026 CLOSED**
- **PRD-025 CLOSED** (DESIGN_CONFIRMED까지)
- **PRD-022 CLOSED** (Guardian Enforcement Layer implemented 2026-02-27)

2) PRD별 “구현 시 필요한 근거” 요약
PRD-026 Atlas Index Engine (선행 기반)
--- (중략) ---
### 🔵 PRD-022 — Guardian Enforcement Layer (Engine Core Set)

**Status: CLOSED (2026-02-27)**

**Implementation Confirmed By:**
- ValidatorFinding 타입 도입
- runValidators → policyFindings 반환 구조 확정
- executePlan → intervention.reasons append-only 추출
- persistSession → cycle-end evidence 저장 전용
- Determinism integration test 통과 (logic_hash 기반)

**Role**
- Execution Hook 기반 안전 검증 레이어
- Decision/WorkItem 상태 변경 트리거 금지 (단방향 조회만 허용)
- InterventionRequired 신호 생성 전용

**Dependency Alignment**
- Atlas 조회는 PRD-026 API만 사용
- Decision Commit은 PRD-025 Enforcer 경로만 사용
- Atlas → Decision/WorkItem 역방향 트리거 금지 (LOCK-C 준수)

**Structural Coupling with PRD-025**
- STRONG/LOCK 충돌 시 자동 Commit 금지
- Guardian은 DecisionProposal 단계에서 개입 가능
- StepResult mutation 금지
- PlanHash + logic_hash 기반 결정론적 재현 보장

### 2.x Guardian Deterministic Invariant (Locked)

- 동일 ExecutionPlan + 동일 validator signature → 동일 validatorFindings 생성
- stale conflict downgrade 규칙은 deterministic해야 함
- validatorFindings는 GraphState에 append-only로 유지
- Plan Hash에 Guardian 결과 포함 금지

**Invariant Alignment (PRD-025 & PRD-022)**
- PRD-025 Invariants (INV-4: Evidence Integrity, INV-7: Version Immutability)는 PRD-022의 Hook Contract와 상호 보완적이다.
- Guardian은 Hook 시점에서 INV-7을 준수하여 기존 상태를 변조하지 않으며, 위반 발견 시 INV-4에 따라 Evidence 기반 Intervention을 생성한다.

PRD-023 Retrieval Intelligence Upgrade (PRD-026 완료 후)

Exit Criteria(핵심 6개):

온보딩 시 4대 인덱스 생성

cycle 종료 fingerprint 기반 update + REVALIDATION_REQUIRED 표시

budget enforcer 작동(max_files/max_bytes 차단)

조회 API가 PRD-022/025에서 사용 가능

실행 중 mutate 금지 테스트 보장

동일 레포 + 동일 pin에서 deterministic 해시 재현 

EXIT_CRITERIA_PRD023-028

삽입 지점/금지 지점(조사 결론):

금지: executePlan step loop 도중 / pre-flight validators / plan resolve 시점

후보: PersistSession 기준 post-cycle (가장 SSOT에 붙음), 또는 run_request의 runGraph 직후(단, StepContract 고려)

저장 위치(조사 결론):

repository_snapshots 테이블/메서드는 “정의는 있으나 실사용 흔적 없음(UNUSED/IDLE)”

그래서 Atlas는 신규 atlas_indices 테이블 분리 필요성 HIGH (기존 snapshot 테이블 확장보다 안전)

해시 결합 리스크(조사 결론):

Atlas Snapshot Hash를 plan hash에 포함하면 session hash mismatch가 잦아져 UX 충돌 위험 → 분리 유지가 정답
(문서의 LOCK-D가 이걸 해결하는 방향. 

PRD-026_Atlas_Index_Engine

)

Budget Enforcer 근거:

1순위 삽입: scanner.ts의 walkDirectory 내부(실시간 max_files/max_bytes 체크 후 throw)

상위 전파: executePlan은 에러를 FailFast/CycleFail로 전파 가능한 구조로 조사됨.

PRD-025 Decision Capture Layer + WorkItem + Completion Policy (후행)

(Exit Criteria 요약은 PRD-025 항목 참고: proposal 자동 생성, 옵션 B 저장정책, evidenceRefs/changeReason 없으면 commit 거부, 버전 체인/active 포인터 이동, WorkItem 상태 전이 가드, STRONG/LOCK 충돌 시 자동 commit 금지. 

EXIT_CRITERIA_PRD023-028

)

**확정된 아키텍처 결정 사항(Section 6)은 설계 시 불변 전제로 간주함.**

PRD-025 구현 시 필수로 연결될 레포 포인트

DecisionVersion 체인 생성/active 전환: sqlite.stores.ts의 원자적 버전 생성 로직

Evidence link(M:N): decision_evidence_links (FK 강제)

WorkItem 상태 전이 가드는 PRD-025 범위(향후 PRD-027로 VERIFIED 확장)

PRD-026과의 결합 근거

PRD-025의 commit은 결국 Decision DB를 변경함 → PRD-026의 Decision Index 동기화 입력이 됨.

단, “Decision 변경 → Atlas 갱신 → Atlas 기반 판단 → Decision 자동 변경” 같은 순환 트리거는 금지 (PRD-026 LOCK-C로 방지 방향. 

PRD-026_Atlas_Index_Engine

)

PRD-022 Guardian Enforcement Robot (PRD-026 기반 소비자)

(Exit Criteria 요약: Hook 삽입, 위반 시 InterventionRequired 생성(차단이 아니라 신호), deterministic 재현(logic_hash/signature), Evidence 저장 연동, 회귀 테스트, plan hash 연동 기록. 

EXIT_CRITERIA_PRD023-028

)

PRD-026이 Guardian에 주는 근거

Guardian은 ConflictPoints를 “어디서” 가져와야 함 → PRD-026 ConflictPoints Index 조회 API가 SSOT 제공.

Hook 계약상 StepResult mutation 불가 → Atlas update를 Hook로 하지 않는 게 맞음(조사에서도 Hook 구현 불가 결론).

PRD-023 Retrieval Intelligence Upgrade (PRD-026 완료 후)

(Exit Criteria 요약: 기존 hierarchical 유지, Strategy Port로 교체 가능, semantic/hybrid 최소 1개 + 지표 근거, 로딩 순서 유지(Policy→Structural→Semantic), 선택이 bundle/pin에 고정. 

EXIT_CRITERIA_PRD023-028

)

필수 근거 포인트

Retrieval core 진입: src/core/decision/decision_context.service.ts (context loading/merge)

Strategy 교체: PRD-021 Strategy Port (코드 위치는 레포에 존재)

Atlas는 Retrieval의 “검색 범위 축소/후보 생성”에 쓰되, plan hash에 결합하지 않음.

PRD-027 WorkItem Completion & VERIFIED 판정 (PRD-025 후행)

(Exit Criteria: completion_policy 평가기, auto_verify_allowed=true 자동 VERIFIED, false면 사용자 확인, 상태 전이 강제, 코딩 도메인 실제 케이스 통과. 

EXIT_CRITERIA_PRD023-028

)

필수 근거 포인트

WorkItem 상태 전이 강제(IMPLEMENTED→VERIFIED→CLOSED)

Evidence/Conflict/Contract clear를 completion_policy로 외부화

Atlas(026)가 제공하는 ConflictPoints/Contract 재검증 상태가 VERIFIED 판정 근거로 쓰임.

PRD-028 Domain Pack Library + Pack Validation (2번째 도메인 진입 시)

(Exit Criteria: 스키마 검증, core 수정 없이 교체, 실패 시 로딩 차단, 2개 pack 공존/격리, 버전 관리/pin 유지. 

EXIT_CRITERIA_PRD023-028

)

필수 근거 포인트

scan_budget / allowlist / blocklist / completion_policy 등은 Pack 쪽으로 외부화됨

PRD-026의 Budget Enforcer는 Pack 규칙의 “강제 집행 계층”으로만 동작해야 함.

3) PRD-026 설계 문서에서 이미 확정된 LOCK 요약 (후속 PRD 근거로 중요)

PRD-026 문서에 포함된 핵심 보강 LOCK들:

Atlas는 파생 인덱스(SSOT 아님), 충돌 시 Session/Decision 우선

PersistSession 성공 후 Atlas 갱신 시도, 실패해도 세션 롤백 없음(telemetry 기록)

Decision↔Atlas 순환 트리거 금지

Plan Hash와 Atlas Hash 완전 분리

Snapshot Hash 범위 분리(repoStructureHash/decisionStateHash/compositeHash)

Budget Enforcer는 executePlan 루프 구조 변경 금지 

PRD-026_Atlas_Index_Engine

## 5) PRD-026 Finalized Architectural Decisions (Do NOT Re-Scan)

다음 항목들은 PRD-026 설계에서 확정된 사항이며,
이후 PRD-023/025/027/028 설계 시 재조사 없이 전제 조건으로 사용한다.

### 5.1 Cycle-End SSOT 확정
- Atlas 갱신 기준점은 **PersistSession 성공 직후**로 고정한다.
- executePlan 루프 내부 삽입 금지.
- validators/pre-flight/plan resolve 단계 삽입 금지.

### 5.2 Storage Strategy 확정
- Atlas는 SQLite 내 신규 `atlas_indices` 테이블군으로 관리한다.
- `repository_snapshots`는 UNUSED로 간주하며 설계 의존 금지.
- 파일 기반 SSOT 전략은 공식적으로 기각됨.

### 5.3 Hash Architecture 확정
- Plan Hash(PRD-012A)와 Atlas Hash는 완전 분리.
- snapshotId = compositeHash 기반.
- compositeHash = repoStructureHash + decisionStateHash.
- createdAt 및 시간 기반 필드는 해시에 포함하지 않음.
- stable stringify + 사전순 필드 정렬 의무.

### 5.4 Budget Enforcer 확정 위치
- scanner.ts의 walkDirectory 내부에서 실시간 예산 체크.
- 초과 시 BudgetExceededError throw (Fail-fast).
- executePlan 루프 구조 변경 금지(Core-Zero-Mod).

### 5.5 Decision ↔ Atlas 순환 방지 확정
- Decision 변경 → Atlas 갱신은 허용.
- Atlas 조회 → Decision 자동 변경은 금지.
- Atlas는 파생 인덱스이며 SSOT가 아니다.

### 5.6 Failure Policy 확정
- PersistSession 성공 후 Atlas 실패 시 Stale 허용.
- 세션 롤백 금지.
- Telemetry에 실패 기록 의무.

### 5.7 SnapshotId Deterministic Invariant (강화)

- snapshotId는 반드시 compositeHash 기반으로 결정론적으로 생성되어야 한다.
- 동일 compositeHash → 반드시 동일 snapshotId 반환.
- snapshotId는 DB auto-increment, UUID v4, timestamp 기반 생성 방식을 사용해서는 안 된다.
- snapshotId는 재빌드 시 drift가 발생해서는 안 된다.
- SQLite rowid 또는 createdAt 값에 의존하는 구현은 금지한다.

이 규칙은 멀티 환경/재빌드/백업 복구 시 동일 Snapshot 재현을 보장하기 위한 불변 조건이다.

### 5.8 Budget Enforcement Error Classification 확정

- BudgetExceededError는 FailFast 범주로 분류한다.
- CycleFail 또는 Intervention으로 downgrade 되어서는 안 된다.
- executePlan 상위 계층에서 swallow(무시)되어서는 안 된다.
- 예산 초과는 정책 위반이 아니라 “구조적 안전 차단”으로 간주한다.

이로써 PRD-025/027 상태 전이 흐름과 혼합되는 것을 방지한다.

### 5.9 Guardian / Completion Policy 경계 강화

- Guardian(PRD-022) 및 Completion Policy(PRD-027)는 Atlas 조회 결과를 직접 Decision 변경 트리거로 사용할 수 없다.
- Atlas 기반 판단은 반드시 사용자 승인 또는 명시적 Enforcer 집행을 거쳐야 한다.
- Atlas 조회 → Decision 자동 변경 루프는 아키텍처 위반으로 간주한다.

이 조항은 PRD-026 LOCK-C의 실질적 방어 규칙이다.

### 5.10 Phase-8 Hardening Notes (Non-Blocking Review Required)

아래 항목들은 PRD-026 구현 정합성 감사 이후 도출된
"구조적으로 안전하지만 장기적으로 재확인 필요한 영역"이다.

이 항목들은 현재 시스템 동작을 막지 않으며,
PRD-025/027/028 이후 Phase-8 하드닝 단계에서 재검토 대상이다.

---

#### (1) ensureInitial Concurrency Safety

- 동시 요청 환경에서 Atlas 초기 빌드가 중복 실행될 가능성 검토 필요.
- snapshotId는 compositeHash 기반 UNIQUE 제약을 가져야 한다.
- 동시 실행 시 동일 snapshotId로 수렴해야 하며, 부분 저장이 발생해서는 안 된다.
- Race Condition 가능성은 현재 설계상 LOW로 판단되나, 멀티 인스턴스 환경 도입 시 재검토 필요.

---

#### (2) Budget Allowlist Default Policy Clarification

- allowlist가 비어있는 경우의 기본 정책(DEFAULT-ALLOW vs DEFAULT-DENY)은
  PRD-028 Domain Pack 철학과 일치하도록 명시적으로 확정해야 한다.
- 현재 구현 동작은 문서화되어야 하며, 정책 확정은 PRD-028 범위로 이관한다.
- blocklist 우선순위는 항상 유지되어야 한다.

---

#### (3) Atlas Stale Accumulation Strategy

- PersistSession 성공 후 Atlas 갱신 실패 시 Stale 허용 정책은 유지된다.
- 장기 Stale 누적 시 자동 복구 전략은 현재 범위에 포함되지 않는다.
- Phase-8에서 다음을 검토한다:
  - Stale 상태 지속 시간 추적 여부
  - 자동 재빌드 트리거 도입 여부
  - Telemetry 경고 강화 기준 정의

---

이 섹션은 PRD-026의 LOCK-A/B/C/D를 수정하지 않으며,
기존 불변 조건을 약화시키지 않는다.

### 5.11 PRD-023~028 Scope Reminder (Design Hint Only)

다음 항목들은 023~028 범위 내 설계 시 반드시 재검토 대상이다:

- PRD-028: allowlist 기본 정책(DEFAULT-ALLOW vs DEFAULT-DENY) 공식 확정 필요
- PRD-025: Decision commit 이후 Atlas Index 미러링 지연 허용 범위 명시 필요
- PRD-027: VERIFIED 판정 시 Atlas Stale 상태가 판단에 미치는 영향 정의 필요

본 항목은 설계 확정이 아니라 “재검토 힌트”이며,
PRD-026의 LOCK 구조를 변경하지 않는다.

## 6) PRD-025 Finalized Architectural Decisions (Do NOT Re-Scan)

다음 항목들은 PRD-025 설계에서 확정된 사항이며,
이후 PRD-022/023/027/028 설계 시 재조사 없이 전제 조건으로 사용한다.

### 6.1 WorkItem → Decision Version UUID Binding (Non-Negotiable)
- WorkItem은 반드시 decisions.id (version UUID)를 참조한다.
- root_id 참조는 금지한다(Active 포인터 이동으로 근거 버전이 암묵적으로 drift).
- WorkItem.decision_id는 생성 시점 버전에 영구 고정(INV-1).

### 6.2 WorkItem State Storage Policy (Explicit Exception)
- WorkItem.status는 예외적으로 mutable overwrite를 허용한다.
- 모든 상태 전이는 work_item_transitions에 append-only로 기록한다(감사 SSOT).
- Non-Overwrite 원칙은 Decision/Evidence에만 적용되며 WorkItem으로 확장 금지.

### 6.3 Dependency Direction (Unidirectional, LOCK-C Aligned)
- 의존 흐름은 단방향: WorkItem → Decision Commit → (Cycle End) → Atlas Update
- 금지: Atlas → WorkItem 변경, Atlas → Decision 자동 변경, WorkItem → Atlas 직접 갱신

### 6.4 WorkItem Status Space Forward Slot (SQLite Migration Risk Avoidance)
- WorkItem.status CHECK는 전체 상태 공간을 미리 선언한다:
  PROPOSED, ANALYZING, DESIGN_CONFIRMED, IMPLEMENTING, IMPLEMENTED, VERIFIED, CLOSED
- PRD-025에서는 전이 가드로 앞 3개 상태만 도달 가능하게 제한한다.
- 나머지 상태는 PRD-027 이전 도달 불가능(코드 가드가 실질 경계).

### 6.5 Proposal-driven Conditional WorkItem Creation (Atomic)
- DecisionProposal에 create_work_item:boolean (default true) 포함.
- Decision Commit과 WorkItem 생성은 단일 트랜잭션 경계로 묶는다.
- create_work_item=false이면 Decision만 커밋하고 WorkItem은 생성하지 않는다.
- WorkItem 생성 실패 시 Decision Commit 롤백(원자성 보장).

### 6.6 Atlas Mirroring Delay & Stale Policy Alignment
- Decision 변경은 Atlas Index에 즉시 반영되지 않는다.
- Atlas 갱신은 PersistSession 성공 이후 Cycle End에서만 수행된다.
- Atlas 갱신 실패 시 Stale 허용, Decision/WorkItem 트랜잭션 롤백 금지(telemetry 기록).

### 6.7 FailFast Separation (BudgetExceededError)
- BudgetExceededError는 FailFast로 분류된다.
- FailFast는 WorkItem 상태 전이를 트리거하지 않는다(상태머신 외부 계층).

### 6.8 Schema Hardening Notes (Non-controversial)
- work_items: FK decisions(id) ON DELETE RESTRICT
- work_item_transitions: FK work_items(id) ON DELETE RESTRICT
- 인덱스:
  idx_work_items_decision_id (work_items.decision_id)
  idx_work_item_transitions_work_item_id (work_item_transitions.work_item_id)

### 6.9 Structured Reason Contract (Non-Negotiable)

- 모든 Decision Commit은 구조화된 reason 객체를 반드시 포함해야 한다.
- reason이 없으면 Commit은 BLOCK(InterventionRequired) 처리된다.
- reason은 단순 문자열이 아니라 최소 구조를 가진다.

최소 스키마(v1):

reason = {
  type: "CONSISTENCY" | "RISK" | "SECURITY" | "PERFORMANCE" | "UX" | "MAINTAINABILITY" | "OTHER",
  summary: string,
  tradeoff?: string,
  evidenceRefs?: string[]
}

LOCK:
- reason.summary는 trim 후 빈 문자열 불가
- reason.type은 enum 외 값 금지
- DecisionVersion은 reason을 SSOT로 영속 저장해야 한다
- Atlas는 reason 내용을 SSOT로 저장하지 않는다 (파생 인덱스 원자가 유지)

> These decisions are now locked post-implementation and validated by integration tests (commit 75c6aef).

## 6.x Engine Core Set 확정

현재 Engine Core Set은 다음 3개 PRD로 구성된다:

- PRD-026 Atlas Index Engine
- PRD-025 Decision Capture Layer (DESIGN_CONFIRMED까지)
- PRD-022 Guardian Enforcement Layer

이 3개는 상호 구조적으로 연결되며,
이후 PRD-023/027/028 설계 시 전제 조건으로 간주한다.

4) 다음 설계 채팅에서 바로 쓰는 “핵심 논점 체크리스트”

**PRD-022/027/028 설계 시 아래 PRD-025/026 확정 사항을 직접 참조할 것:**

Atlas update는 PersistSession 기준으로 묶는다(SSOT 정렬)

Atlas 저장은 SQLite 신규 테이블로 간다(원자성/정합성)

Plan hash에는 Atlas를 절대 포함하지 않는다

Budget abort는 walkDirectory에서 throw 기반 fail-fast로 한다

repository_snapshots는 현재 UNUSED로 간주하고 설계 의존하지 않는다

PRD-025/027의 VERIFIED 판정 근거는 Atlas(Conflict/Contract 상태) + Evidence로 구성

WorkItem은 반드시 Decision Version UUID(id)에 바인딩한다 (root_id 금지)

Decision Commit + WorkItem 생성은 단일 원자적 트랜잭션으로 처리한다

Evidence Pack Updated — PRD-022 integrated into Engine Core Set (2026-02-27)

---

# 🔒 7) Cross-PRD Common Contract (PRD-023 / PRD-027 / PRD-028)

이 섹션은 PRD-023, PRD-027, PRD-028 동시설계를 가능하게 하기 위한
공통 계약(Shared Interface Contract)을 정의한다.

이 계약은 기존 PRD-025/026 Finalized Decisions를 수정하지 않으며,
추가적인 상호 침범을 방지하기 위한 경계 정의다.

---

## 7.1 Retrieval Output Contract (PRD-023 Boundary)

PRD-023은 검색 품질을 개선할 수 있으나,
출력 스키마를 변경해서는 안 된다.

### RetrievalResultV1 (Locked Shape)

{
  decisions: DecisionVersion[],
  evidence: EvidenceRecord[],
  anchors?: AnchorRecord[],
  conflictPoints?: ConflictPoint[],
  metadata: {
    strategy: string,
    latency_ms?: number
  }
}

LOCK:

- 필드 삭제 금지
- 필드 의미 변경 금지
- PlanHash 입력에 Retrieval 결과 포함 금지
- Strategy 교체는 Bundle/Pin 단에서만 허용

PRD-023은 내용 품질(정밀도/재현율)만 개선 가능하며,
shape 변경은 금지한다.

---

## 7.2 Completion Policy Interface (PRD-027 Boundary)

PRD-027은 WorkItem VERIFIED 판정을 담당한다.

CompletionPolicyV1은 다음 입력만 사용할 수 있다:

{
  workItem: WorkItem,
  decision: DecisionVersion,
  guardianFindings: ValidatorFinding[],
  atlasState: {
    conflictClear: boolean,
    contractClear: boolean
  },
  evidence: EvidenceRecord[]
}

LOCK:

- CompletionPolicy는 Decision 또는 WorkItem을 직접 수정할 수 없다.
- CompletionPolicy는 Atlas를 직접 갱신할 수 없다.
- CompletionPolicy는 Retrieval을 강제 호출할 수 없다.
- 반환값은 다음으로 제한된다:

{
  status: "ALLOW" | "REQUIRE_CONFIRMATION" | "BLOCK",
  reason: string
}

VERIFIED 상태 전이는 Enforcer 계층에서만 수행한다.

---

## 7.3 Evidence Sufficiency Rule (PRD-028 Boundary)

PRD-028은 Evidence의 "충분성 정의"를 외부화한다.

EvidenceSufficiencyV1:

{
  minEvidenceCount: number,
  requiredTypes?: string[],
  allowExternalRefs?: boolean
}

LOCK:

- Evidence 충분성 기준은 Domain Pack에서만 정의한다.
- Core는 기준을 해석하지 않고 집행만 한다.
- EvidenceRecord는 append-only 원칙 유지.
- Evidence 변경이 Atlas를 자동 변경해서는 안 된다.

---

## 7.4 Dependency Direction Lock

의존 방향은 다음과 같이 고정한다:

PRD-028 (Evidence Rule)
        ↓
PRD-027 (Completion Policy)
        ↓
PRD-023 (Retrieval Improvement)

금지 방향:

- Retrieval → Completion 자동 트리거 금지
- Atlas → WorkItem 자동 변경 금지
- Completion → Atlas 직접 수정 금지

---

## 7.5 Determinism Preservation Rule

다음은 반드시 유지되어야 한다:

- 동일 ExecutionPlan + 동일 Pin → 동일 Completion 결과
- Retrieval 전략 변경은 Bundle 교체 시에만 발생
- CompletionPolicy는 시간 기반 값(Date.now 등) 사용 금지
- Random 값 사용 금지
- AtlasHash는 PlanHash와 분리 유지

---

## 7.6 Stale Handling Policy Alignment

Atlas가 Stale 상태일 경우:

- CompletionPolicy는 VERIFIED 자동 승인 금지
- REQUIRE_CONFIRMATION으로 downgrade 가능
- FailFast(BudgetExceededError)는 Completion 흐름에 포함되지 않는다

---

END OF SECTION
