# ADR-002: GraphState Concerns Split

## Context
`GraphState` had a large number of optional fields in one interface, which made ownership and lifecycle tracking difficult during reviews and refactors. It was hard to see which step/layer owned each field and when each field could exist.

## Decision
Adopt **Option A**: compose `GraphState` from `GraphStateBase + concern interfaces` in `src/core/plan/plan.types.ts`.

- `GraphStateBase`
- `GraphStateRuntimeScope`
- `GraphStateContextSelection`
- `GraphStateStepExecution`
- `GraphStateRepositoryScan`
- `GraphStateIntervention`
- `GraphStateGuardian`
- `GraphStateCompletion`

Final type is an intersection composition:

```ts
type GraphState = GraphStateBase & ... & GraphStateCompletion
```

Helper aliases were added for readability in step/logic boundaries:

- `GuardianState`
- `RetrievalState`
- `WorkItemState`

## Alternatives Considered
1. Step-specific union decomposition  
Rejected because impact radius is high and would likely force behavior changes across executor/handlers.

2. Move top-level fields into `stepResults`  
Rejected because it changes state semantics and risks snapshot/consumer compatibility.

## Consequences
### Positive
- Type definitions now encode ownership/lifecycle by concern.
- Reviewers can identify field purpose and producers/consumers faster.
- Improves maintainability without touching runtime behavior.

### Negative
- More type declarations to navigate.
- Requires understanding intersection-based composition.

## Compatibility
- Runtime object shape is unchanged (field names preserved).
- Session snapshot compatibility is preserved.
- No Plan Hash input changes.
- No Atlas boundary or mutation timing changes.

## Note
This is an architecture/type-model structure change, so it is recorded as ADR.
