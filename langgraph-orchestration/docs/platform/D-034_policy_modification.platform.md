# D-034 — Authority & Invariant Guardrails

## 1. Planner Restrictions
- Cannot write to `policy_registry` directly.
- Cannot mutate policy YAML directly.
- Cannot bypass the `Decision` chain.

## 2. Core Requirements
- MUST reject modification if `evidenceRefs` are missing.
- MUST reject overwrite attempts (append-only/versioned).
- MUST preserve version chain integrity.

## 3. PersistSession Constraints
- Remains the only commit anchor for session-end mutations.
- No additional writes injected into the `executePlan` loop.

## 4. Audit & Records
- All `KEEP_POLICY` events MUST be recorded as a POLICY acknowledgement record in audit storage. This record type MUST be semantically distinct from SAFETY BLOCK_KEY / INFORMED_BLOCK flows.
- All modification attempts MUST be recorded via the `Decision` version chain.

- Reusing `INFORMED_BLOCK` for `KEEP_POLICY` is prohibited in PRD-034 scope.
- If future work attempts reuse, it MUST be a separate PRD + ADR, and MUST include an explicit discriminator and formal equivalence proof. (Out of scope for PRD-034.)

## 5. Promotion Boundary Rule

Policy Registration Engine(PRD-033)은 다음 조건을 모두 만족할 때만 실행 가능하다:

- DecisionVersion이 PersistSession을 통해 커밋됨
- 해당 Decision scope가 "policy.*" 패턴을 가짐
- overwrite가 아닌 version chain append임

WorkItem 상태 전이(VERIFIED)는 Promotion 조건이 아니다.
