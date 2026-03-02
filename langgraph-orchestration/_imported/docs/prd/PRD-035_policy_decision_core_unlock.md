# PRD-035 — Policy Decision Core Unlock & Wiring Completion

**Depends On:** PRD-033, PRD-034

## 0. Background

PRD-034 defined the Policy Modification contract (KEEP/MODIFY/REGISTER) but core engine support is incomplete:
- policy.* scope rejected by DECISION_SCOPE_ALLOWLIST.
- interventionResponse.action not wired to PersistDecision decision.action.
- As a result, MODIFY_POLICY and REGISTER_POLICY are unreachable E2E.

PRD-035 restores engine reachability without altering invariants.

## 1. Problem Statement

The current core prevents:
- Creation of DecisionVersion with scope policy.{profile}.{mode}
- Routing of UI interventionResponse.action into PersistDecision

This makes PRD-034 structurally unreachable.

## 2. Goals

- **G1.** Allow policy.* scope decisions without breaking existing scope invariants.
- **G2.** Deterministically route interventionResponse.action into PersistDecision.
- **G3.** Preserve:
    - PlanHash algorithm
    - PersistSession atomic boundary
    - Append-only Decision chain
    - Registration execution boundary (PRD-033)

## 3. Scope

### IN:
- DecisionScope extension (policy.* prefix rule with minimal guards)
- interventionResponse -> decision.action wiring inside core
- FailFast safety checks for malformed policy scopes
- Backward compatibility for non-policy scopes

### OUT:
- Any PlanHash modification
- Any change to Registration executor
- Any change to Guardian logic
- Any change to Capture Layer schema

## 4. DecisionScope Extension (Selected Strategy: A - Prefix Rule)

### 4.1 Acceptance Rule
DecisionScope MUST allow: `scope.startsWith("policy.")`

### 4.2 Minimal Guards (Mandatory)
The following MUST be enforced:
- Scope must match structure: `policy.<profile>.<mode>`
- Split by ".": `segments.length >= 3`
- segments[1] and segments[2] MUST be non-empty lowercase alphanumeric tokens
- No whitespace allowed
- `policy.` alone MUST be rejected

### 4.3 Runtime Domain Guard
If scope starts with `policy.`:
- Extract `<profile>.<mode>`
- It MUST match current runtime profile + mode
- If mismatch -> `FailFastError("POLICY_SCOPE_DOMAIN_MISMATCH")`
- *Rationale:* Prevents cross-chain contamination.

### 4.4 Type Clarification (Runtime vs TypeScript)

- The existing `DecisionScope` TypeScript union derived from `DECISION_SCOPE_ALLOWLIST` remains unchanged.
- `policy.*` scopes are treated as runtime-validated dynamic extensions.
- TypeScript static type narrowing does NOT expand to include `policy.*`.
- Core MUST validate `policy.*` scopes exclusively through runtime guards defined in this PRD.
- This avoids structural widening of the DecisionScope union and prevents cross-module type ripple.

## 5. Intervention Wiring

### 5.1 Authority Rule
decision.action resolution order:

1. If step payload contains `decision.action`: use it
2. Else if `state.interventionResponse.action` is one of:
       `MODIFY_POLICY`
       `REGISTER_POLICY`
       `KEEP_POLICY`
   then use it
3. Else: undefined

- `APPROVE` and `REJECT` MUST NOT be promoted to `decision.action`.
- `APPROVE` and `REJECT` remain persist-gate-only control signals.

If both sources exist and mismatch: `FailFastError("INTERVENTION_ACTION_CONFLICT")`

Conflict Exception:

- If `decision.action == KEEP_POLICY`
  and `state.interventionResponse.action == APPROVE`,
  this is NOT a conflict.
- `KEEP_POLICY` operates at decision-routing layer.
- `APPROVE` operates at persist-gate layer.
- Layer separation MUST be preserved.

### 5.2 PersistProposal Activation
- `MODIFY_POLICY` and `REGISTER_POLICY` MUST require `persistProposal=true`.
- `KEEP_POLICY` MUST NOT create DecisionProposal.
- `APPROVE` remains gate-only and MUST NOT alter `decision.action`.

### 5.3 No Planner Mutation
Planner MUST NOT be required to emit `decision.action` for policy modification. Core wiring handles intervention channel.

## 6. Invariant Preservation

- `persistProposal` gate remains only blocking mechanism.
- No additional DB writes inside `executePlan` loop.
- PlanHash algorithm unchanged.
- Registration Execution occurs only post-run.
- `KEEP_POLICY` produces exactly one `POLICY_ACKNOWLEDGED` audit record.
- No Decision overwrite allowed.

## 7. Exit Criteria

- `policy.{profile}.{mode}` scope passes validation.
- `MODIFY_POLICY` produces DecisionProposal and commits successfully.
- `REGISTER_POLICY` produces DecisionProposal and eligibility request.
- `interventionResponse.action` triggers routing without YAML modification.
- Existing global/runtime/wms/coding/ui scopes behave identically.
- No `DECISION_SCOPE_INVALID` for valid policy scopes.
- No change in PlanHash for non-policy runs.
