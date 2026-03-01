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

### 3.1 Root Allocation Constraints
- The Planner MUST NOT fabricate `rootId` values.
- The UI MUST NOT submit `rootId` values.
- `rootId` is assigned only at promotion/registration time under PRD-033 authority.

**If action == KEEP_POLICY:**
- Record `GuardianAudit` `POLICY_ACKNOWLEDGED`.

## 4. Hash and Session Handling

- Policy modification does NOT mutate current `ExecutionPlan`.
- Change takes effect only in next session.
- If `PlanHash` differs in next run, normal mismatch handling applies.
- No retroactive mutation of current session state.

## 5. Registration Eligibility vs Execution (PRD-033 Compatibility)

- `PersistSession` committing a `DecisionVersion` with `scope="policy.*"` creates **eligibility** for registration.
- Eligibility is NOT an implicit registration trigger.
- The actual registration write to `PolicyRegistry` MUST occur only under PRD-033 authority and ONLY via:
  1) explicit CLI invocation, OR
  2) post-run boundary execution outside `executePlan` and outside the `PersistSession` transaction boundary.
- **PROHIBITED:** Any implicit registry write as part of `PersistSession` handlers.
- **PROHIBITED:** Any registration execution inside `executePlan` (including preflight, pre-persist loop, or completion policy evaluation).

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

### 6. Audit Type Semantics

- `POLICY_ACKNOWLEDGED` is distinct from SAFETY `BLOCK_KEY` or `INFORMED_BLOCK`.
- It represents explicit acknowledgement of a POLICY-class finding without policy evolution.
- It MUST NOT imply execution halt semantics.
- `INFORMED_BLOCK` is reserved for SAFETY/HARD-BLOCK semantics and MUST NOT be emitted by `KEEP_POLICY`.
