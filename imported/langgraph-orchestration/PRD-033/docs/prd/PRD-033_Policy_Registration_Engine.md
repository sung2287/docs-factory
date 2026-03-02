# PRD-033: Policy Registration Engine

Status: PARTIAL

**Status Note:**
- Automatic post-run registration executor is REQUIRED architecture.
- Current implementation is CLI-only.
- Web post-run automatic registration execution is declared as the Product SSOT.
- CLI is an operator tool that invokes the same Registration Executor.

구현 완료 범위:
- policy_registry 테이블 DDL (schema v4)
- PolicyRegistryStore (register / deprecate / resolve)
- CLI 기반 policy:register / deprecate / resolve
- pre-run resolveActivePolicy() (runtime 실행 전 읽기 경로)

미구현 범위:
- PersistSession 성공 이후 자동 Eligibility 생성 경로
- post-run registration executor (auto-registration)
- scope 기반 자동 승격 로직
- outbox/administrative boundary executor

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

- No automatic promotion triggered by CompletionPolicy.
- No registration execution triggered by InterventionRequired resolution.
- No registry write during executePlan.
- No registry write during PersistSession.

## 5. Hard Invariants
- **Registration Isolation:** Registration MUST NOT execute inside the `executePlan` step loop or `PersistSession` transaction.
- **Administrative Access:** CLI is an operator tool invoking the same executor logic as the automatic post-run path.
- **Eligibility Boundary:** `PersistSession` MUST NOT emit eligibility artifacts. Eligibility emission is permitted ONLY at the Post-Run Boundary, after `PersistSession` commit success and after `runGraph()` returns.
- **Transaction Boundary:** Registration MUST NOT mutate the decision SSOT in the same transaction as a plan execution. It must use its own atomic transaction.
- **Idempotency:** Idempotency is scoped strictly to `(rootId, version)`.
Hash equality alone MUST NOT imply cross-root or cross-version reuse.
Identical `policyHash` values under different `rootId` chains are permitted and MUST NOT be deduplicated automatically.
- **State Independence:** Registration must not depend on or be blocked by an `InterventionRequired` state in any active session.
- **PROHIBITED:**
  - Any implicit registry write as part of `PersistSession` handlers.
  - Any registration execution inside `executePlan` (including preflight, pre-persist loop, or completion policy evaluation).
  - PersistSession MUST NOT emit eligibility.
  - PersistSession MUST NOT write to policy_registration_outbox.
  - No outbox write may occur inside executePlan.
  - No outbox write may occur inside PersistSession.

Eligibility establishment occurs at PersistSession commit time,
but materialization (outbox persistence) MUST occur exclusively at the Post-Run Boundary.

### Post-Run Execution Boundary (LOCK)

Registration Execution MUST occur only at the Post-Run Boundary defined as:

- After `runGraph()` successfully returns.
- After `PersistSession` has completed and returned `{ persisted: true }`.
- Before `storageLayer.storage.close()` is invoked.
- Outside `executePlan`.
- Outside any `PersistSession` transaction.

This boundary is the only permitted automatic execution window.

Registration MUST NOT execute:
- Inside `executePlan`
- Inside `PersistSession`
- Inside completion policy evaluation
- Inside pre-persist loop

## 6. Terminology
- **Eligibility:** A committed `policy.*` DecisionVersion makes the run eligible for `PolicyRegistrationRequest` emission. The actual emission MUST occur only at the Post-Run Boundary. Eligibility is a state of eligibility, not a registry write.
- **Registration Execution:** An administrative operation under PRD-033 authority (CLI or post-run task) that writes the `PolicyRegistry` in its own transaction boundary.
- **Promotion:** Terminology deprecated in PRD-034/033 to avoid confusion. Use "Eligibility" or "Registration Execution" instead.

### Eligibility Artifact Definition (LOCK-A)

- A committed `policy.*` DecisionVersion establishes eligibility.
- Eligibility MUST be materialized as a `PolicyRegistrationRequest` at the Post-Run Boundary only.
- PersistSession MUST NOT create or persist PolicyRegistrationRequest.
- PersistSession MUST NOT enqueue outbox entries.
- CompletionPolicy transitions MUST NOT create eligibility.
- Eligibility emission MUST occur strictly after:
  1. PersistSession commit success
  2. runGraph return
  3. Before `storageLayer.storage.close()`

This ensures:
- No hidden coupling to session commit
- No registry mutation during execution loop
- Explicit administrative boundary

## 7. Lifecycle
- **Draft:** Policy defined in local config or proposed in memory.
- **Registered:** Policy committed to the registry, eligible for selection.
- **Deprecated:** Policy remains in registry but is no longer eligible for new sessions.
- **Version Chain:** Each policy follows a strict `rootId` and incremental `version` sequence.

### Eligibility Emission Rule (LOCK)

When a `DecisionVersion` is committed via `PersistSession`
and `Decision.scope` starts with `"policy."`,
an Eligibility artifact (`PolicyRegistrationRequest`) MUST be emitted.

Rules:

- Eligibility emission MUST occur only at the Post-Run Boundary,
after `PersistSession` commit success AND after `runGraph()` returns,
and before `storageLayer.storage.close()` is invoked.
- Eligibility MUST be persisted as an outbox-style artifact.
- Eligibility emission MUST NOT trigger registry writes directly.
- CompletionPolicy transitions MUST NOT emit eligibility.

Eligibility is a state declaration, not execution.

### Execution Ordering Guarantee (LOCK-A)

1. DecisionProposal created
2. PersistSession commit success
3. runGraph returns
4. Eligibility emitted at Post-Run Boundary (outbox persisted)
5. Registration Executor consumes outbox
6. Registry write committed
7. Next run resolves updated policy

Active ExecutionPlan instances MUST NOT be mutated mid-run.

Policy changes take effect at the next run start.

PersistSession commit success alone does NOT authorize eligibility emission.
Eligibility emission is a Post-Run administrative action.

## 8. Administrative Boundary (Current vs Target)

Current Implementation State:
- Registration execution exists only via explicit CLI command.
- No automatic post-run executor is implemented.
- No eligibility outbox emission path is implemented.

Target Product Architecture:
- Web post-run automatic registration execution is the default product path.
- CLI is an operator tool invoking the same executor.
- Exactly one Registration Executor implementation must exist.

Eligibility emission is considered an administrative boundary action and is not part of the execution loop nor part of PersistSession responsibilities.

### Outbox Requirement (LOCK)

PolicyRegistrationRequest MUST be persisted in a durable outbox table.

Options explicitly rejected:
- Memory-only emission (PROHIBITED)
- Immediate registry write during PersistSession (PROHIBITED)

Auto-registration execution MUST:

1. Consume outbox entries.
2. Execute Single Registration Executor.
3. Mark outbox entry as processed.

Outbox processing MUST be retry-safe and idempotent.

### Product SSOT Declaration

Web post-run automatic registration execution is the default product path.

CLI registration is:

- A manual administrative trigger
- Not the system of record
- Not a parallel implementation

Registry state consistency MUST NOT depend on manual CLI invocation.

## 9. Single Registration Executor (LOCK)

There MUST exist exactly one Registration Executor implementation:

```typescript
registerPolicyFromRequest(request: PolicyRegistrationRequest)
```

This executor MUST enforce:

- Version-scoped idempotency (rootId, version)
- Hash conflict rejection
- Independent transaction boundary
- No dependency on active session state

Both:
- CLI `policy:register`
- Web post-run automatic execution

MUST invoke this same function.

Parallel or duplicated registration implementations are prohibited.

## 10. Exit Criteria
- Deterministic `PolicyHash` specification defined.
- Registration boundary explicitly defined as an external or post-run operation.
- Implementation design preserves `PersistSession` invariants.
- Atlas interaction defined as read-only or non-blocking post-run update.
- [ ] Post-Run Boundary explicitly defined in documentation
- [ ] Eligibility emission rule locked
- [ ] Outbox architecture declared
- [ ] Single Registration Executor declared
- [ ] Web SSOT path declared
- [ ] CLI declared as administrative trigger only
- [ ] No registry writes inside executePlan
- [ ] No registry writes inside PersistSession
- [ ] Idempotency rules enforced at executor level

Dependency Guard:

- Status reflects current implementation reality.
- Target Architecture defines intended final structure.
- Dependent PRDs (e.g., PRD-034) MUST NOT assume
  automatic registration execution unless Exit Criteria
  explicitly confirm its implementation.
