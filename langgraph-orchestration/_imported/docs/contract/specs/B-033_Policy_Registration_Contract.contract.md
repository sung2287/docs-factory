# B-033: Policy Registration Contract

## 1. PolicyEntity Schema
The Policy Registry tracks policies using the following logical structure:

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | UUID | Primary key for the specific policy version. |
| `rootId` | String | Logical identifier for the policy (e.g., "GeneralCompliance"). |
| `version` | Integer | Incremental version number within the `rootId`. |
| `domain` | String | Execution domain (e.g., "core", "finance"). |
| `normalizedPolicyBody` | JSON/Text | The canonical representation of the policy logic. |
| `validatorSignatures` | JSON | List of `(validator_id, version, logic_hash)` used for verification. |
| `policyHash` | String | Deterministic hash (see Section 2). |
| `status` | Enum | {Draft, Registered, Deprecated}. |
| `metadata` | JSON | Includes `creator`, `timestamp`, and `sourceRef`. |

## 2. PolicyHash Rules
The `PolicyHash` is derived deterministically from the following components:
- `normalizedPolicyBody`: The logical content of the policy, stripped of whitespace or ephemeral comments.
- `validatorSignatures`: A sorted list of the IDs, versions, and logic hashes of all validators associated with the policy.
- `domain`: The target execution environment.

**Explicit Exclusions:**
- Runtime execution payloads (e.g., specific work item data).
- Ephemeral state (e.g., `lastUsedAt`, `invocationCount`).
- Metadata (e.g., `creator`, `timestamp`).

## 3. Registration Idempotency Rule

### 3.1 Version-Scoped Idempotency

The tuple `(rootId, version)` is the primary uniqueness boundary.

Registration behavior MUST follow:

- If `(rootId, version)` does not exist:
  - Create a new record.

- If `(rootId, version)` exists AND `policyHash` matches:
  - Return the existing `id`.
  - This is considered an idempotent re-registration.

- If `(rootId, version)` exists AND `policyHash` differs:
  - Reject the registration as a version conflict.
  - This MUST be treated as an integrity violation.

### 3.2 Cross-Root Hash Behavior

A matching `policyHash` across different `(rootId, version)` pairs MUST NOT trigger cross-root deduplication.

In other words:

- Identical policy content may exist under different `rootId` chains.
- Hash equality alone MUST NOT cause reuse of an existing record under a different root.

Each `rootId` maintains an independent version chain.

### 3.3 Determinism Guarantee

The registry MUST ensure:

- Version chains are strictly monotonic per `rootId`.
- No implicit merging of version chains is allowed.
- Idempotency is scoped strictly to `(rootId, version)`.

### 3.4 Version Allocation Rule

Version numbers are explicitly provided at registration time.

The registry MUST NOT auto-increment or implicitly assign `version` values.

Registration behavior regarding version progression:

- The caller is responsible for supplying the intended `version`.
- The registry validates monotonic progression but does not compute it.
- If a provided `version` is less than or equal to the highest existing version under the same `rootId`, the registration MUST be rejected.

This ensures:

- No hidden race conditions due to auto-increment semantics.
- Clear separation between version planning and registry validation.
- Deterministic and externally controlled version evolution.

## 4. Resolution Rule
The `PolicyInterpreter` resolves the active policy based on:
1. `domain` match.
2. `status = Registered`.
3. Highest `version` number.

**Constraint:** The resolution must occur at the start of a session or run; it MUST NOT be queried during the `executePlan` step loop to ensure execution consistency.

**Execution Boundary Constraint:**
- Active policy resolution must occur before plan execution begins.
- Policy resolution MUST NOT be invoked inside:
    - executePlan step loop
    - pre-persist loop
    - completion policy evaluation
- Resolution must be deterministic for the lifetime of a single run.
