# PRD-033: Policy Registration Engine

## 1. Context
Current policy definitions are managed primarily via filesystem configurations (e.g., `modes.yaml`) and interpreted at runtime. The system lacks a formal, database-backed Policy Registry. While `ExecutionPlan` is derived via the `PolicyInterpreter` and contains `PlanHash` signatures for structural safety, there is no single source of truth (SSOT) for versioned policies that can be promoted or audited independently of the filesystem state.

## 2. Problem Statement
Policies currently lack formal lifecycle management:
- They cannot be versioned or referenced as immutable database entities.
- There is no deterministic registry to track system-level policy evolution.
- The boundary between a proposed policy change and a "registered" (active) policy is implicit rather than explicit.
- Auditing depends on external logs rather than a structured registry of active policy versions.

## 3. Scope (IN)
- **Policy Entity:** Definition of the canonical Policy record.
- **Registration Boundary:** Formalization of the transition where a policy becomes "Registered."
- **PolicyHash Derivation:** Specification of a deterministic hash representing the policy's structural and logical content.
- **Promotion Trigger:** MVP support for explicit CLI-driven registration and promotion.
- **Read Model:** Definition of how the `PolicyInterpreter` resolves the active policy from the registry.

## 4. Scope (OUT)
- Runtime mutation of an active `ExecutionPlan` (plans remain immutable once instantiated).
- Automated self-registration during execution loops.
- Hot-reload semantics for active sessions.
- Cross-domain policy refactoring or migration.

## 5. Hard Invariants
- **Registration Isolation:** Registration MUST NOT execute automatically inside the `executePlan` step loop or `PersistSession` handler.
- **Eligibility Boundary:** `PersistSession` is not an execution trigger for registration writes. It may only produce eligibility artifacts (PolicyRegistrationRequest) for later administrative execution.
- **Post-Run Automatic Registration (Target Architecture):**
  Automatic registration execution is allowed at the post-run boundary
  (after `runGraph` completes and before storage closure).
  It is defined as the default product path but is not yet implemented.
- **Transaction Boundary:** Registration MUST NOT mutate the decision SSOT in the same transaction as a plan execution. It must use its own atomic transaction.
- **Idempotency:** Registration attempts for the same `PolicyHash` must be idempotent.
- **State Independence:** Registration must not depend on or be blocked by an `InterventionRequired` state in any active session.
- **PROHIBITED:**
  - Any implicit registry write as part of `PersistSession` handlers.
  - Any registration execution inside `executePlan` (including preflight, pre-persist loop, or completion policy evaluation).

## 6. Terminology
- **Eligibility:** A `policy.*` DecisionVersion committed via `PersistSession` creates an externalizable `PolicyRegistrationRequest`. This is a state of eligibility, not a registry write.
- **Registration Execution:** An administrative operation under PRD-033 authority (CLI or post-run task) that writes the `PolicyRegistry` in its own transaction boundary.
- **Promotion:** Terminology deprecated in PRD-034/033 to avoid confusion. Use "Eligibility" or "Registration Execution" instead.

## 7. Lifecycle
- **Draft:** Policy defined in local config or proposed in memory.
- **Registered:** Policy committed to the registry, eligible for selection.
- **Deprecated:** Policy remains in registry but is no longer eligible for new sessions.
- **Version Chain:** Each policy follows a strict `rootId` and incremental `version` sequence.

## 7. Exit Criteria
- Deterministic `PolicyHash` specification defined.
- Registration boundary explicitly defined as an external or post-run operation.
- Implementation design preserves `PersistSession` invariants.
- Atlas interaction defined as read-only or non-blocking post-run update.
- [ ] Target-state automatic post-run executor implemented
- [ ] Current-state vs Target-state distinction explicitly documented
- [ ] PRD-034 must not assume auto-registration until this item is complete

## 8. Administrative Boundary (Current State vs Target State)

Current Implementation State:
- Registration execution currently exists only via explicit CLI command.
- No automatic post-run executor is implemented in the runtime.

Target Product Architecture:
- Web post-run automatic registration execution is the default product path.
- CLI remains an operator tool invoking the same executor logic.
- There must be exactly one Registration Executor implementation.

Gap Definition:
- The automatic post-run executor is defined as required architecture,
  but is not yet implemented in the current codebase.
- This gap must be resolved before PRD-034 depends on automatic registration.

Consistency Rule:

- Status reflects implementation reality.
- Hard Invariants may define target architecture.
- Target architecture MUST NOT be assumed by dependent PRDs until Exit Criteria are satisfied.
