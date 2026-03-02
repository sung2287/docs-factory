# ADR-031: GuardianAudit DB SSOT for BlockKey and audit-only persistence

Status: ACCEPTED
Date: 2026-02-28

## Context
- PRD-031 enables real guardian enforcement.
- PersistSession must not run on BLOCK, but we must preserve block evidence and loop-prevention key.
- System goal requires persistence across restarts; in-memory registry is insufficient.

## Decision
- Introduce GuardianAudit as audit-only persistence path, not SSOT commit.
- Persist BlockKey in DB with unique constraint as SSOT for informed-block detection.
- First BLOCK writes MIN_PERSIST + BLOCK_KEY atomically.
- Subsequent same BlockKey returns INFORMED_BLOCK with no additional writes.

## Consequences
- Positive: Survives restarts.
- Positive: Deterministic and testable.
- Negative: New table/store/wiring.
- Negative: Fail-fast if audit write fails to avoid silent loss.

## Invariants Preserved
- PersistSession never called on BLOCK.
- Guardian does not mutate GraphState/StepResult and does not trigger Atlas update.
- Findings excluded from PlanHash.
- Validator declaration order remains SSOT for PlanHash.

## References
- docs/prd/PRD-031_enforce_guardian_rules.md
- docs/contract/specs/B-031_enforce_guardian_rules.contract.md
- docs/contract/intent_maps/C-031_enforce_guardian_rules.intent_map.md
- docs/platform/D-031_enforce_guardian_rules.platform.md
