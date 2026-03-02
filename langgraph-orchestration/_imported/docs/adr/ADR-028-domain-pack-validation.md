# ADR-028: Domain Pack Library Validation in PolicyInterpreter

## Context
PRD-028 introduces Domain Pack Library loading (`policy/packs/<packId>/<version>/pack.json`) and requires fail-fast validation before runtime execution. Existing plan hash behavior must remain unchanged.

## Decision
- Place Domain Pack fail-fast validation at `PolicyInterpreter.resolveExecutionPlan()`.
- Split runtime flow into three explicit stages:
  - Resolve: file path + JSON parse (`domain_pack.resolver.ts`)
  - Validate: schema/default/migration checks (`domain_pack.validator.ts`)
  - Materialize: inline inject validated pack into `RepoScan.payload.domainPack`
- Keep `computeExecutionPlanHash()` and `normalizeExecutionPlanForHash()` unchanged.
- Keep optional-field validation policy: only validate fields when present.
- Keep top-level `allowlist` backward compatibility via migration to `scan_budget.allowlist` and warning log.

## Rationale
- Validation at interpreter boundary blocks malformed packs before graph/core runtime starts, reducing propagation of invalid state.
- Resolve/Validate/Materialize separation keeps single-responsibility boundaries and independent error contracts.
- Hash exclusion structure already ignores payloads (including Domain Pack), so inline injection before hash is safe and preserves existing hash invariants.
- Optional-field policy allows incremental schema adoption without forcing unrelated fields into legacy packs.

## Migration Strategy
- If `schema_version` is missing, runtime defaults to `"v1"`.
- If top-level `allowlist` exists, migrate to `scan_budget.allowlist`.
- If both exist, `scan_budget.allowlist` wins and top-level is ignored.
- Emit `DOMAIN_PACK_TOP_LEVEL_ALLOWLIST_MIGRATED` warning when migration path is used.

## Consequences
### Positive
- Fail-fast safety is deterministic at plan construction time.
- Existing hash/pin flows remain stable.
- Multiple pack IDs/versions remain path-isolated in the library tree.

### Negative
- New policy startup failures can occur for malformed pack files that were previously ignored.
- Policy authors must keep pack references (`packId/version`) valid.
