# D-032 -- live_validation_harness.platform

## 1. Execution Boundary
- Seed runs utilize the `runtime/cli/run_local.ts` entry point.
- Modification of the `executePlan` core loop structure is strictly prohibited during validation.

## 2. Persistence Boundary
- Mid-plan writes for `PersistDecision` are permitted (as per current architecture).
- Atlas index updates MUST only occur after successful `PersistSession`.
- Dependency on `GuardianAudit` table or PRD-031 logic is forbidden for this harness.

## 3. Hash Boundary
- `step.payload` remains excluded from PlanHash.
- `guardianFindings` remains excluded from PlanHash.
- The declaration order of `validators` MUST be included in PlanHash.

## 4. Failure Policy
- PlanHash mismatch results in immediate Fail-fast.
- snapshotId mismatch results in immediate Fail-fast.
- Retry after validation failure is prohibited to preserve SSOT determinism guarantees.

## 5. Governance Alignment (Post-031)

The live validation harness operates under the verified governance constraints introduced by PRD-031.
GuardianAudit persistence is physically separated from SSOT and Atlas update boundaries.
No additional guard logic is required within the harness layer.
