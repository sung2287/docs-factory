# B-034 — Policy Modification Contract

## 1. Extended Intervention Schema

Add to GraphIntervention:

```json
{
  "required": "boolean",
  "reasons": "string[]",
  "type": "string",
  "policyFindings": "ValidatorFindingV1[]"
}
```

### Rules:
- SAFETY findings never included here.
- Only POLICY class findings included.
- `policyFindings` is read-only view of `runValidators` output.
- `policyFindings` MUST be sourced from the in-core `runValidators` finding snapshot generated inside `executePlan`.
- DTO/UI layers MUST NOT synthesize, filter, or transform findings beyond serialization; SAFETY exclusion MUST be enforced in-core.

Exposure Constraint:
- policyFindings MUST NOT be exposed directly to UI.
- A deterministic transformation to PolicyConflictView MUST occur in-core.
- DTO layer MUST serialize only PolicyConflictView.
- DTO layer MUST NOT transform or synthesize conflict data.

## 2. User Response Schema

```json
{
  "action": "KEEP_POLICY | MODIFY_POLICY | REGISTER_POLICY",
  "targetValidatorId": "string",
  "proposedChange": "string",
  "justification": "string"
}
```

### Validation:
- `MODIFY_POLICY` and `REGISTER_POLICY` require `proposedChange` + `justification`.
- `KEEP_POLICY` requires no payload.

## 3. Decision Routing Rules

**If action == MODIFY_POLICY:**
- Create `DecisionProposal`:
  - `scope`: "policy.{profile}.{mode}"
  - `strength`: "axis"
  - `reason.summary`: justification
  - `reason.type`: "CONSISTENCY"
  - `evidenceRefs`: at least 1
  - `persistProposal`: true
  - `targetRootId`: MUST reference the existing policy decision chain root (no new root allocation).

**If action == REGISTER_POLICY:**
- Root allocation MUST be performed by the Policy Registration boundary (PRD-033) and MUST NOT be performed by the Planner or the UI.
- The initial DecisionProposal for `REGISTER_POLICY` MUST be treated as a "new policy draft intent" and MUST NOT assume a pre-existing policy root.
- The proposal MUST include `policyKey` (human-stable identifier) sufficient for PRD-033 to create a new root chain deterministically.
- For `REGISTER_POLICY`, the resulting committed `policy.*` DecisionVersion MUST produce a `PolicyRegistrationRequest` at Eligibility creation time. Root allocation occurs only during Registration Execution under PRD-033 authority.

Mapping Determinism Rule:
- targetValidatorId MUST deterministically map to a single policy chain.
- The mapping logic MUST reside in-core.
- UI MUST NOT derive rootId or policyKey.
- REGISTER_POLICY MUST require explicit policyKey.
- MODIFY_POLICY MUST require explicit targetRootId (derived in-core).

**If action == KEEP_POLICY:**
- KEEP_POLICY MUST write exactly one audit record: AuditSink.POLICY_ACKNOWLEDGED.
- KEEP_POLICY MUST NOT emit or reuse any SAFETY block record types (BLOCK_KEY / INFORMED_BLOCK / MIN_PERSIST).

## 4. Hash and Session Handling

- Policy modification does NOT mutate current `ExecutionPlan`.
- Change takes effect only in next session.
- If `PlanHash` differs in next run, normal mismatch handling applies.
- No retroactive mutation of current session state.

## 5. Registration Eligibility vs Execution (PRD-033 Compatibility)

Normative rule set: See PRD-034 'SSOT: Eligibility vs Registration Execution (Normative)'.
This section defines only payload shape and local validation constraints.

### 5.1 PolicyRegistrationRequest (handoff payload)
```json
{
  "decisionVersionRef": "string",
  "policyKey": "string",
  "domain": "string",
  "normalizedPolicyBody": "string|json",
  "validatorSignatures": "ValidatorSignature[]",
  "sourceRef": "string"
}
```

- `PolicyRegistrationRequest` MUST be generated after commit and anchored to `decisionVersionRef`.
- `policyKey` MUST be present for REGISTER_POLICY flows.
- `policyKey` SHOULD be present for MODIFY_POLICY flows; if absent, executor MUST derive it deterministically from (scope + targetRootId) without network/IO.
- `decisionVersionRef` MUST be the single authoritative reference; all other fields are derived/verified at execution time.

### 6. Audit Type Semantics

- `POLICY_ACKNOWLEDGED` is distinct from SAFETY `BLOCK_KEY` or `INFORMED_BLOCK`.
- It represents explicit acknowledgement of a POLICY-class finding without policy evolution.
- It MUST NOT imply execution halt semantics.
- `INFORMED_BLOCK` is reserved for SAFETY/HARD-BLOCK semantics and MUST NOT be emitted by `KEEP_POLICY`.
