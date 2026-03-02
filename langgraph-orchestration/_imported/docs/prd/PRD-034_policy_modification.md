# PRD-034 — Policy Modification & Conflict Resolution Flow

Status: DESIGN DRAFT
Depends On: PRD-022 (Guardian), PRD-025 (Capture Layer), PRD-026 (Atlas), PRD-033 (Policy Registration Engine)

## 1. Problem Statement

Current system behavior:

- POLICY class findings (WARN/BLOCK) do NOT halt execution.
- applyPolicyIntervention sets status="InterventionRequired" but PersistSession still executes.
- UI receives only string[] reasons, not structured ValidatorFinding.
- No structured modification loop exists for policy evolution.

Goal:

Design a structured, versioned, authority-safe Policy Modification Flow such that:

1) POLICY violations generate structured conflict reports.
2) User may choose:
   - KEEP existing policy
   - MODIFY existing policy
   - REGISTER new policy rule
3) All modifications go through Decision version chain (no overwrite).
4) Planner never mutates policy directly.
5) PlanHash rules remain unchanged.

No Core invariant violations allowed.

---

## 2. Scope

In scope:
- POLICY finding reporting structure
- Intervention DTO extension
- 3-way modification branch
- Decision-based policy modification routing
- Audit trail integration
- Session hash mismatch handling policy

Out of scope:
- Changing PlanHash algorithm
- Altering PersistSession atomic structure
- Core loop redesign
- Direct DB writes from UI

---

## 3. Current Confirmed Constraints (Do Not Violate)

A. PersistSession only legal SSOT anchor for decisions.
B. POLICY findings do not halt execution.
C. persistProposal gate is the ONLY pre-PersistSession blocking mechanism.
D. Decision overwrite is forbidden (version chain only).
E. AuditSink is audit-only storage.

AuditSink writes (including POLICY_ACKNOWLEDGED) are observational records only. They MUST NOT trigger or bypass any execution control flow, including persistProposal gating, PersistSession eligibility creation, or registration execution.

F. Product SSOT Rule
- The Web runtime flow is the product SSOT.
- Any capability available only via CLI is considered operational tooling, not a product feature.
- Registration Execution MUST be reachable from the Web-initiated runtime flow via the post-run lifecycle boundary.
- CLI MAY invoke the same Registration Execution path but MUST NOT be the only functional path.

G. UI Minimal Exposure Rule
- The runtime MUST expose only the minimal policy conflict data required for rendering.
- Internal GraphState fields MUST NOT be exposed wholesale.
- All UI-visible payloads MUST be derived via an explicit mapping layer.
- UI MUST NOT infer relationships between findings, decisions, roots, or chains.
- All linkage fields (validatorId, policyKey, targetRootId, decisionVersionRef) MUST be explicitly provided if needed.

---

## SSOT: Eligibility vs Registration Execution (Normative)

- Definitions
  - **Eligibility:** A `policy.*` DecisionVersion committed via `PersistSession` deterministically yields a `PolicyRegistrationRequest` payload. Eligibility is NOT a registry write. Eligibility implies the existence of a `PolicyRegistrationRequest` but does not imply successful Registration Execution.
  - **Registration Execution:** A separate post-run administrative operation that writes `PolicyRegistry` in its own transaction boundary.

- Normative Rules
  1) Eligibility is created ONLY after a successful PersistSession commit and MUST be anchored to the committed DecisionVersionRef.
  2) Registration Execution MUST occur ONLY at the post-run lifecycle boundary, outside `executePlan` and outside the `PersistSession` transaction.
  3) Default product behavior: Web-initiated runtime flow MUST reach the post-run executor automatically (CLI is operator tooling invoking the same executor, not the only path).
  4) Registration failure MUST NOT roll back or invalidate the committed DecisionVersion; it only delays adoption until it succeeds.
  5) Policy adoption takes effect only in the next session; no retroactive mutation of an active ExecutionPlan.
  6) Decision overwrite is forbidden. Policy evolution is append-only: either append to an existing chain (MODIFY_POLICY) or append as the first version of a new chain (REGISTER_POLICY) under PRD-033 authority.
  7) REGISTER_POLICY MUST NOT overwrite or replace any existing chain.

- Implementation Notes (Non-normative)
  - The PolicyRegistrationRequest may be persisted in an admin/outbox store for retries.
  - Executor MUST treat DecisionVersionRef as source-of-truth; other payload fields are hints/derived.

- Promotion: Terminology deprecated in PRD-034/033 to avoid confusion. Use "Eligibility" or "Registration Execution" instead.

---

## 4. Target Behavior

When POLICY finding occurs:

### Phase 1: Structured Conflict Capture
- Preserve full ValidatorFinding structure (validator_id, class, status, evidenceRefs, logic_hash).
- Attach structured findings to GraphState (internal only).
- Expose structured conflict report to UI via extended DTO.

Conflict View Model Rule:
- A dedicated read-model (PolicyConflictView) MUST be defined.
- The view model MUST contain only:
  - validatorId
  - class
  - status
  - summary/reason
  - evidenceRefs (if applicable)
- Raw internal state structures MUST NOT be passed directly to UI.

### Phase 2: User Choice
User selects one:

1) KEEP_POLICY
   - Acknowledge finding
   - Continue without modification
   - AuditSink records POLICY_ACKNOWLEDGED.
     (MUST be semantically distinct from SAFETY block semantics)

KEEP_POLICY는 다음을 보장해야 한다:
- No mutation of GraphState.status
- No mutation of persistProposal
- No creation of DecisionProposal
- No Eligibility creation
- No Registration Execution trigger
- Exactly one AuditSink record: POLICY_ACKNOWLEDGED

KEEP_POLICY MUST NOT:
- Activate persistProposal gate
- Modify interventionResponse
- Modify WorkItem status
- Trigger post-run registration logic

#### KEEP_POLICY 의미 명확화

KEEP_POLICY는 단순 audit-only acknowledgement가 아니다.

KEEP_POLICY는 다음 의미를 가진다:

- 해당 POLICY finding에 대해 "정책 변경 없음"을 명시적으로 선언하는 행위
- AuditSink records POLICY_ACKNOWLEDGED.
  (MUST be semantically distinct from SAFETY block semantics)
- DecisionVersion은 생성하지 않음
- 정책 상태는 유지됨
- 다음 세션에서도 동일 정책이 적용됨

KEEP_POLICY는 정책 진화 이벤트가 아니다.
MODIFY_POLICY 또는 REGISTER_POLICY만이 정책 진화 이벤트다.

2) MODIFY_POLICY
   - Create DecisionProposal
   - scope: "policy.{profile}.{mode}"
   - strength: "axis"
   - reason.type: CONSISTENCY
   - persistProposal: true
   - Route through existing Ask-to-Commit flow

3) REGISTER_POLICY
   - Requests creation of a new policy chain; root assignment occurs at registration execution.
   - Same persistProposal routing

---

## 5. Commit Policy Clarification (Mandatory Rule)

POLICY finding은 기본적으로 PersistSession을 차단하지 않는다.

정책 수정 흐름(PRD-034)은 "next-session effect model"을 따른다.

즉:

- POLICY finding 발생
- 사용자가 MODIFY_POLICY 또는 REGISTER_POLICY 선택
- DecisionVersion은 PersistSession을 통해 커밋
- 정책 효력은 다음 세션에서만 반영

현재 세션의 ExecutionPlan은 절대 재계산하지 않는다.
PersistSession은 POLICY finding 단독으로는 차단되지 않는다.

이 규칙은 Core invariant C (persistProposal gate is the only blocking mechanism)를 유지하기 위함이다.

단, 사용자가 MODIFY_POLICY 또는 REGISTER_POLICY를 선택하는 경우,
해당 요청은 DecisionProposal을 생성하며 `persistProposal=true`로 설정된다.
이로 인해 기존 persistProposal gate가 활성화되며,
PersistSession은 사용자 승인(APPROVE) 이전에는 차단된다.

이 동작은 새로운 차단 로직을 추가하는 것이 아니라,
기존 Core invariant C (persistProposal gate is the only blocking mechanism)를
그대로 활용하는 것이다.

Normative rule set: See PRD-034 'SSOT: Eligibility vs Registration Execution (Normative)'.

---

## 6. 설계 일관성 검증 체크리스트

- POLICY finding 단독으로 PersistSession 차단되지 않음
- persistProposal gate 외에 신규 차단 로직 추가 없음
- PlanHash 계산 규칙 변경 없음
- executePlan 루프 내 신규 DB write 없음
- Policy Registration Eligibility는 PersistSession 이후에만 발생
- KEEP_POLICY는 정책 진화 이벤트가 아님
- MODIFY_POLICY / REGISTER_POLICY 선택 시에만 persistProposal gate 활성화됨
