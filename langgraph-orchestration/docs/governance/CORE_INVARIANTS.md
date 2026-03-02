# CORE INVARIANTS (Cross-PRD)

Purpose: 탐색 피로를 줄이기 위해, "깨지면 안 되는 축"만 1페이지로 고정한다.
Rules:
- 설명(why)과 배경은 ADR로 보낸다. 여기에는 규칙만 둔다.
- 규칙은 짧게, 검증 가능하게 쓴다.

## 1) SSOT Anchors
- [RULE] PersistSession 성공 이후만 cycle-end mutation(Atlas update 등)을 허용한다. (Evidence: runtime/persistence/session_persist.ts#createPersistSessionHandler)
- [RULE] DecisionVersion은 overwrite 금지. 항상 새 버전 생성 + active 포인터 이동.
- [RULE] WorkItem.status는 예외적으로 mutable overwrite 허용(transition log는 append-only). (Evidence: src/adapter/storage/sqlite/sqlite.stores.ts#appendTransitionAtomic)

## 2) Hash Separation
- [RULE] PlanHash(PRD-012A) 입력에 AtlasHash, snapshotId, Guardian findings를 포함하지 않는다. (Evidence: src/session/execution_plan_hash.ts#computeExecutionPlanHash)
- [RULE] DomainPack(PRD-028) 내용은 RepoScan payload에 포함되나, PlanHash 계산에서 명시적으로 제외되어 도메인 지식 변경이 플랜 식별자를 깨뜨리지 않아야 한다. (Evidence: src/session/execution_plan_hash.ts#normalizeExecutionPlanForHash)
- [RULE] validators/postValidators는 PlanHash 입력에 포함된다. (Evidence: src/session/execution_plan_hash.ts)
- [RULE] snapshotId는 deterministic(compositeHash 기반)이어야 하며 시간/UUIDv4/rowid 기반 금지. (Evidence: src/atlas/atlas.hash.ts#createAtlasSnapshotId)

## 3) Authority Boundaries
- [RULE] Planner(LLM)은 실행 권한이 없다. Enforcer(Core)가 정책/예산/allowlist로 집행한다.
- [RULE] Guardian/CompletionPolicy는 Decision/WorkItem/Atlas를 직접 mutate 할 수 없다(신호/판정만). (Evidence: src/core/plan/plan.executor.ts#executePlan)

## 4) Circular Trigger Ban
- [RULE] Decision → (cycle end) → Atlas update는 허용.
- [RULE] Atlas 조회 결과로 Decision/WorkItem 자동 변경 트리거는 금지.
- [RULE] executePlan 루프 내부에서 Atlas write/update를 수행하지 않는다. (Evidence: src/core/plan/plan.executor.ts#executePlan)
- [RULE] PolicyRegistry mutation MUST occur only at Post-Run Boundary and MUST NOT execute inside executePlan or PersistSession.

## 5) FailFast Classification
- [RULE] BudgetExceededError는 FailFast로 분류되며 Intervention/CycleFail로 downgrade 금지. (Evidence: src/atlas/budget/budget.enforcer.ts)

## 6) Determinism
- [RULE] 동일 ExecutionPlan + 동일 Pin → 동일 결과(Guardian findings / completion verdict 포함).

---

## PRD-029 -- Persist Proposal Authority Boundary
Status: CLOSED (2026-02-28)

- [RULE] Planner는 상태 변경 권한이 없으며 `InterventionRequired(source="PLANNER")` 신호만 생성할 수 있다.
- [RULE] `PersistSession` 호출은 Enforcer(Core)만 수행한다.
- [RULE] `evidence.conversationTurnRefs(minItems:1)` 없는 Proposal은 영속화 금지.
- [RULE] Idempotency 판별은 `(conversationId, turnId, targetRootId)` 3-tuple 기준으로만 수행한다.
- [RULE] turnId 단독 기준 멱등 판별 금지.
- [RULE] PersistProposal 생성은 PlanHash 입력에 영향을 주지 않는다.

## 8) Policy Modification & Scope Strictness
- [RULE] `policy.*` scope MUST follow the exact structure `policy.<profile>.<mode>` (exactly 3 segments). Any other segments length MUST be rejected as `DECISION_SCOPE_INVALID`. (Evidence: src/core/decision/decision.scope.ts)
- [RULE] `MODIFY_POLICY` MUST use `registeredPolicyRootId` from `PolicyRef` as the sole SSOT for `targetRootId`. Planner-provided `rootId` MUST be ignored to prevent cross-chain contamination. (Evidence: src/core/plan/plan.handlers.ts#toPersistProposal)
- [RULE] `REGISTER_POLICY` MUST NOT store `policyKey` inside `DecisionReason`. It stores only seed fields (`targetValidatorId`), and the derived `policyKey` is materialized only at the Post-Run Boundary.
- [RULE] `interventionResponse.action` (MODIFY/REGISTER/KEEP) MUST NOT be derived from LLM text parsing; it MUST flow as structured data from the WebSubmitInput channel.
