# B-035 — Policy Decision Core Unlock Contract

**Reference:** PRD-035

## 1. DecisionScope Contract Update

`isAllowedDecisionScope(scope)`:
- MUST return `true` if:
    - scope in existing allowlist OR
    - scope satisfies policy prefix rule + guards defined in PRD-035.

DecisionScope type MAY remain union-based, but runtime validation MUST handle policy prefix path.

## 2. Intervention Routing Contract

`PersistDecision` MUST resolve action as:

```
resolvedAction =
    decision.action ??
    (state.interventionResponse.action in
        { MODIFY_POLICY, REGISTER_POLICY, KEEP_POLICY }
        ? state.interventionResponse.action
        : undefined)
```

- `APPROVE` and `REJECT` MUST NOT be elevated to decision.action.
- If both decision.action and promotable interventionResponse.action exist and mismatch:
      FailFast("INTERVENTION_ACTION_CONFLICT").
- Exception: KEEP_POLICY + APPROVE is valid and non-conflicting.

## 3. KEEP_POLICY Contract

- MUST NOT create DecisionProposal.
- MUST write exactly one `POLICY_ACKNOWLEDGED` audit record.
- MUST NOT:
    - mutate `policyRef`
    - generate `policyKey`
    - create new root
    - affect `persistProposal`

## 4. MODIFY_POLICY Contract

- `targetRootId` MUST come from `state.policyRef.registeredPolicyRootId`.
- MUST reject if absent.
- MUST ignore planner-provided `rootId`.

## 5. REGISTER_POLICY Contract

- MUST create DecisionProposal with `policy.*` scope.
- Root allocation remains PRD-033 responsibility.
- `policyKey` generation remains post-run deterministic.
