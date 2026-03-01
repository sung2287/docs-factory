# C-033: Policy Registration Intent Map

| Intent ID | Action | Description |
| :--- | :--- | :--- |
| **INT-033-01** | `Register Policy` | Persist a new policy version to the Registry. |
| **INT-033-02** | `Reject Duplicate` | Prevent registration of conflicting versions or duplicate hashes. |
| **INT-033-03** | `Deprecate Policy` | Mark a policy version as Deprecated to prevent new session adoption. |
| **INT-033-04** | `Resolve Active` | Retrieve the latest Registered version for a given domain. |

## INT-033-01: Register Policy
- **Trigger:** explicit CLI command OR post-run lifecycle boundary task (outside executePlan and outside PersistSession transaction).
- **Preconditions:** Policy body and validator signatures are valid and hashes match.
- **Success Criteria:** Record is created in `PolicyRegistry` with `status = Registered`.
- **Block Conditions:** Version already exists with a different hash.
- **No Side Effects:** Does not mutate active `ExecutionPlan` instances.
- **Constraint:**
  - Registration MUST NOT execute automatically inside PersistSession or executePlan loop.
  - PersistSession may create an eligibility record (or externalizable request) for registration, but MUST NOT perform the registry write.
  - CompletionPolicy transitions MUST NOT create eligibility nor execute registration.

## INT-033-02: Reject Duplicate Registration
- **Preconditions:** A registration request is received for an existing `(rootId, version)` or `policyHash`.
- **Success Criteria:** Return error (if version conflict) or existing ID (if hash match).
- **Block Conditions:** None.

## INT-033-03: Deprecate Policy Version
- **Preconditions:** Policy exists in `Registered` status.
- **Success Criteria:** Status updated to `Deprecated`.
- **No Side Effects:** Does not terminate active sessions using this version.

## INT-033-04: Resolve Active Policy
- **Preconditions:** Domain exists.
- **Success Criteria:** Returns the highest versioned `Registered` policy for the domain.
- **Block Conditions:** Resolution requested inside an `executePlan` loop (Contract violation).
- **Constraint:**
  - Resolution cannot query registry during executePlan loop.

## Explicit Constraints
- Registration MUST NOT execute automatically inside PersistSession or executePlan loop.
- PersistSession may create an eligibility record (or externalizable request) for registration, but MUST NOT perform the registry write.
- CompletionPolicy transitions MUST NOT create eligibility nor execute registration.
