# ADR-001: Split `runtime/graph/plan_executor_deps.ts` by SoC

## Context
`runtime/graph/plan_executor_deps.ts` had mixed concerns in one file: input normalization, retrieval quality gate, telemetry/evidence emission, deps assembly, and session persistence orchestration.

## Decision
Split the module into concern-focused runtime files while keeping the existing entrypoint compatible:
- `runtime/validation/normalizers.ts`
- `runtime/metrics/quality_gate.ts`
- `runtime/telemetry/emitters.ts`
- `runtime/graph/deps_factory.ts`
- `runtime/persistence/session_persist.ts`

Keep `runtime/graph/plan_executor_deps.ts` as a thin facade that re-exports the existing public API.

## Consequences
- Improved readability and testability by isolated responsibilities.
- Existing import path compatibility is preserved via facade re-export.
- More files and import edges must be maintained.
