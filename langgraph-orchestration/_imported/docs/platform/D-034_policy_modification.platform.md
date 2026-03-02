# D-034 — Authority & Invariant Guardrails

## 1. Planner Restrictions
- Cannot write to `policy_registry` directly.
- Cannot mutate policy YAML directly.
- Cannot bypass the `Decision` chain.

## 2. Core Requirements
- MUST reject modification if `evidenceRefs` are missing.
- MUST reject overwrite attempts (append-only/versioned).
- MUST preserve version chain integrity.

UI Boundary Rule:
- Planner/UI MUST NOT compute:
  - rootId
  - version numbers
  - policyHash
- All identity and chain derivation MUST occur under PRD-033 authority.

## 3. PersistSession Constraints
- Remains the only commit anchor for session-end mutations.
- No additional writes injected into the `executePlan` loop.

## 4. Audit & Records
- All `KEEP_POLICY` events MUST be recorded as a POLICY acknowledgement record in `AuditSink`. This record type MUST be semantically distinct from SAFETY BLOCK_KEY / INFORMED_BLOCK flows.
- All modification attempts MUST be recorded via the `Decision` version chain.
- `AuditSink` is a passive record store and MUST NOT influence execution control flow.

Audit Isolation Rule:
- POLICY_ACKNOWLEDGED is strictly observational.
- It MUST NOT:
  - affect eligibility
  - affect registration execution
  - affect PlanHash
  - affect PersistSession gating
- guardian_audit_records MUST remain reserved for execution-cycle findings only.

- Reusing `INFORMED_BLOCK` for `KEEP_POLICY` is prohibited in PRD-034 scope.
- If future work attempts reuse, it MUST be a separate PRD + ADR, and MUST include an explicit discriminator and formal equivalence proof. (Out of scope for PRD-034.)

## 5. Registration Execution Boundary Rule

Normative rule set: See PRD-034 'SSOT: Eligibility vs Registration Execution (Normative)'.
This section enforces authority boundaries only.

- Planner/UI MUST NOT allocate policy roots.
- Planner/UI MUST NOT write to the policy registry directly.
- Planner/UI MUST NOT fabricate `rootId` values or bypass the `Decision` chain.

WorkItem 상태 전이(VERIFIED)는 Registration Execution 조건이 아니다.
