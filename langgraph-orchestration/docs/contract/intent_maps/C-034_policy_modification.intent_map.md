# C-034 — Intent Map: Policy Modification

**INT-034-01: Report Policy Conflict**
- **Trigger**: `POLICY` finding
- **Outcome**: Structured conflict attached to intervention

**INT-034-03: Modify Existing Policy**
- **Trigger**: `action=MODIFY_POLICY`
- **Outcome**: `DecisionProposal` generated; `persistProposal` gate activated.

**INT-034-04: Register New Policy**
- **Trigger**: `action=REGISTER_POLICY`
- **Outcome**:
  - `DecisionProposal` generated (new policy draft intent)
  - `persistProposal` gate activated
  - Policy root allocation deferred to PRD-033 at promotion time

**INT-034-05: Approval Flow**
- **Trigger**: User `APPROVE`
- **Outcome**: `PersistSession` commits `DecisionVersion`.

**INT-034-07: No Policy Change Acknowledged**
- **Trigger**: `action=KEEP_POLICY`
- **Outcome**:
  - `AuditSink` records `POLICY_ACKNOWLEDGED` (policy acknowledgement record)
  - `DecisionVersion` 생성 없음
  - 정책 상태 유지
  - POLICY_ACKNOWLEDGED MUST NOT reuse SAFETY block record types (BLOCK_KEY / INFORMED_BLOCK / MIN_PERSIST).

**INT-034-08: Policy Registration Eligibility Created**
- **Trigger**:
  - `PersistSession` successfully commits a `DecisionVersion`
  - AND `Decision.scope` matches `policy.*`
- **Outcome**:
  - A `PolicyRegistrationRequest` becomes **eligible** for PRD-033 processing
  - This is NOT a registry write and MUST NOT be considered 'promotion' or 'registration'.
  - Registration MUST be executed only via:
    - explicit CLI command, OR
    - post-run lifecycle boundary task (outside executePlan and outside PersistSession transaction)
  - Policy adoption is allowed starting next session only (no retroactive effect)

**INT-034-09: Execute Policy Registration (Administrative)**
- **Trigger**:
  - An eligible `PolicyRegistrationRequest` is submitted via CLI / post-run boundary
- **Outcome**:
  - PRD-033 registers the policy version in `PolicyRegistry` (idempotent rules apply)
  - PRD-033 idempotency/version-conflict rules are enforced at execution time.
  - No mutation of any active session’s `ExecutionPlan`

