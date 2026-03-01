# D-033: Policy Registration Platform Notes

## 1. Safe Write Boundary
Policy registration is strictly decoupled from the core execution loop:
- **CLI-Only Path:** Primary registration occurs via explicit CLI commands outside of a graph run.
- **Post-Run Boundary:** Post-run boundary tasks may CREATE/EMIT a `PolicyRegistrationRequest` payload (Eligibility), but registry write EXECUTION must occur in a dedicated administrative operation (CLI or post-run task), outside the `PersistSession` transaction boundary.
- **Prohibited:** Registration MUST NOT occur within the `executePlan` loop or any `StateGraph` node.

## 2. Component Interaction

### PlanHash Interaction
- PlanHash remains derived exclusively from the materialized ExecutionPlan structure and validator signatures, per existing deterministic hashing rules.
- PolicyHash does NOT directly modify PlanHash.
- PolicyHash influences PlanHash only indirectly through ExecutionPlan materialization during policy resolution.
- No changes to PlanHash derivation are introduced in PRD-033.

### CompletionPolicy
- While `CompletionPolicy` manages `WorkItem` transitions (e.g., to `VERIFIED`), it remains consumer-only regarding the Policy Registry.

### Administrative Audit Separation
- Policy registration is an administrative operation and is not part of execution-cycle GuardianAudit.
- If audit logging is required, it must use a dedicated registry_log or equivalent administrative log mechanism.
- guardian_audit_records remains reserved for execution-cycle evidence only.

### Atlas
- Any updates to Atlas regarding registered policies must be non-blocking and follow the `deps.atlasUpdate` pattern.

## 3. Concurrency & Atomicity
- **Independent Transaction:** Policy registration must use its own atomic transaction.
- **Isolation:** It must not rely on or be bundled within the `PersistSession` transaction. This ensures that a failure in session persistence does not roll back a valid policy registration, and vice versa.

## 4. Implementation Strategy (Analysis)
- The Registry should be implemented as a new table in the SQLite storage layer.
- Migration scripts for the SQLite schema must be idempotent.
- The `PolicyInterpreter` should be refactored to check the Registry before falling back to filesystem-based `modes.yaml`.

## 5. Future Extension (Non-binding)
- **Phase 2:** Implementation of an approval workflow where `Draft` policies require multi-validator signatures before transitioning to `Registered`. This will remain logically separate from the core registration engine defined here.
