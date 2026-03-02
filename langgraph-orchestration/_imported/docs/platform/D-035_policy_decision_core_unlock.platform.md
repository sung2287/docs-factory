# D-035 — Policy Decision Core Unlock Platform Spec

## 1. Authority Boundaries

- **UI MUST NOT supply:**
    - rootId
    - version
    - policyKey
- **Planner MUST NOT allocate policy roots.**
- **Core MUST ignore planner-provided rootId for policy decisions.**

## 2. Core Safety Requirements

- FailFast on malformed `policy.*` scope.
- FailFast on intervention action conflict.
- FailFast on `MODIFY` without `registeredPolicyRootId`.
- No silent coercion of scope strings.

## 3. Hash Safety

- DecisionScope prefix extension MUST NOT alter PlanHash algorithm.
- Non-policy runs MUST produce identical PlanHash as before.

## 4. Append-only Guarantee

- All policy modifications remain versioned.
- No overwrite path introduced.
