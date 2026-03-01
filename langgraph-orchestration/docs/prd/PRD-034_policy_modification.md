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
E. GuardianAudit is audit-only storage.

---

## 4. Target Behavior

When POLICY finding occurs:

### Phase 1: Structured Conflict Capture
- Preserve full ValidatorFinding structure (validator_id, class, status, evidenceRefs, logic_hash).
- Attach structured findings to GraphState (internal only).
- Expose structured conflict report to UI via extended DTO.

### Phase 2: User Choice
User selects one:

1) KEEP_POLICY
   - Acknowledge finding
   - Continue without modification
   - Record POLICY acknowledgement audit (distinct from SAFETY block semantics)

#### KEEP_POLICY 의미 명확화

KEEP_POLICY는 단순 audit-only acknowledgement가 아니다.

KEEP_POLICY는 다음 의미를 가진다:

- 해당 POLICY finding에 대해 "정책 변경 없음"을 명시적으로 선언하는 행위
- AuditSink에 POLICY_ACKNOWLEDGED 기록
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

All branches must preserve authority boundary.

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

- PersistSession commit of a policy-scoped DecisionVersion creates **eligibility** only.
- Registration execution occurs only via CLI or post-run boundary administrative task, outside executePlan and outside PersistSession transaction.
- `Decision.scope` matching `policy.*` is the single authoritative promotion condition. No other signal (WorkItem state, Guardian findings, or Planner output) may trigger Policy Registration.

## 6. Terminology
- **Eligibility:** A `policy.*` DecisionVersion committed via `PersistSession` creates an externalizable `PolicyRegistrationRequest`. This is a state of eligibility, not a registry write.
- **Registration Execution:** An administrative operation under PRD-033 authority (CLI or post-run task) that writes the `PolicyRegistry` in its own transaction boundary.
- **Promotion:** Terminology deprecated in PRD-034/033 to avoid confusion. Use "Eligibility" or "Registration Execution" instead.

---

## 7. 설계 일관성 검증 체크리스트

- POLICY finding 단독으로 PersistSession 차단되지 않음
- persistProposal gate 외에 신규 차단 로직 추가 없음
- PlanHash 계산 규칙 변경 없음
- executePlan 루프 내 신규 DB write 없음
- Policy Registration Eligibility는 PersistSession 이후에만 발생
- KEEP_POLICY는 정책 진화 이벤트가 아님
- MODIFY_POLICY / REGISTER_POLICY 선택 시에만 persistProposal gate 활성화됨
