# PRD-032 -- Live Validation Harness & Seed Data Stabilization

Status: OPEN
Purpose: System integrity and reproducibility validation through repeat Seed Runs.

## 1. Objective
- Validate system integrity reproducibility via 3+ repeated Seed Run executions.
- Verify accumulation of Decision, WorkItem, and Atlas data.
- Ensure stability of PlanHash and snapshotId across multiple cycles.
- Establish a baseline for system stability using normal execution paths (no Guardian BLOCK).

## 2. Scope
### In-Scope
- CLI-based repeated execution scenarios.
- Session reload and hash verification.
- Atlas fingerprint comparison across runs.
- Database entity presence and relationship integrity validation.

### Out-of-Scope
- Guardian BLOCK verification (belongs to PRD-031).
- Manual override features.
- Reproducibility of LLM response content (textual content).

## 3. Core Decisions
- Reproducibility metrics are limited to Hash, Storage state, and Atlas state levels.
- PersistDecision maintains current structure (mid-execution writes permitted).
- Atlas update is permitted only after a successful PersistSession.
- snapshotId maintains determinism based on compositeHash (repo + decision state).
- Raw LLM response content is explicitly excluded from reproducibility indicators.

## 4. Determinism Definition
Determinism is confirmed if the following are identical across runs:
- PlanHash (Execution Plan identifier).
- snapshotId (Atlas state identifier).
- InterventionRequired status (Source and Type).
- Decision and WorkItem status fields (excluding auto-generated IDs and createdAt timestamps).
- CompletionPolicy verdict consistency MUST be identical across runs.
- InterventionRequired classification (including source) MUST be identical across runs.

## 5. Infinite Loop Non-Dependency
- PRD-032 does not depend on INFORMED_BLOCK logic.
- PRD-032 does not require the presence of the GuardianAudit table.

## 6. Exit Criteria
- Identical PlanHash across 3 consecutive runs with same input.
- Identical snapshotId across 3 consecutive runs with same input.
- Successful verification of Decision/WorkItem data presence in SQLite.
- Successful session reload without hash verification conflicts.
- Documented and reproducible Seed Run procedure exists.
- PlanHash identity MUST hold across 3 consecutive runs with freshSession=true.
- snapshotId identity MUST hold across 3 consecutive runs with freshSession=true.

## 7. Post-PRD-031 Compatibility Verification

PRD-031 implementation has been audited after completion.
The following governance boundaries have been re-validated against the current repository state:

- Hash Separation confirmed: guardianFindings, GuardianAudit records, and Atlas snapshotId are excluded from PlanHash inputs.
- Execution Boundary confirmed: Guardian execution only occurs within executePlan lifecycle.
- Persistence Boundary confirmed: GuardianAudit writes do not trigger PersistSession, SSOT writes, or Atlas updates.
- Loop Prevention confirmed: BlockKey SSOT and INFORMED_BLOCK logic prevent infinite execution without mutating core loop structure.
- PRD-032 Determinism assumptions remain valid.

Audit evidence references:
- src/session/execution_plan_hash.ts
- src/core/plan/plan.executor.ts
- src/adapter/storage/sqlite/sqlite.storage.ts
- runtime/persistence/session_persist.ts

No structural changes required for PRD-032.
