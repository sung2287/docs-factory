# REPO MAP UPDATES (Change Log)

Purpose: PRD 완료 시 RepoMap을 매번 재작성하지 않고, 구조적 변경을 3줄로 누적 기록한다.
Format:
- 최소 3개, 최대 5개 bullet
- 아래 3개는 반드시 포함:
  1) SSOT/Anchor change
  2) Entry/Touchpoint change
  3) Contract/Interface change

---

## 2026-02-27 PRD-026
- SSOT/Anchor change: PersistSession 성공 후 Atlas 갱신 SSOT 고정 (executePlan 루프 내 삽입 금지, src/atlas/atlas.updater.ts)
- Entry/Touchpoint change: src/plugin/repository/scanner.ts (BudgetExceededError throw 추가), src/atlas/ 디렉토리 신규 (atlas_indices 테이블군)
- Entry/Touchpoint change: src/core/plan/plan.executor.ts (cycle-end hook 연결 — PersistSession 이후 Atlas 갱신 경계)
- Contract/Interface change: PRD-026 snapshotId = compositeHash(repoStructureHash+decisionStateHash) 결정론 확정, AtlasHash ≠ PlanHash 분리 고정

## 2026-02-27 PRD-025
- SSOT/Anchor change: DecisionVersion overwrite 금지 확정 — createNextVersionAtomically SSOT (src/adapter/storage/sqlite/sqlite.stores.ts)
- Entry/Touchpoint change: sqlite.storage.ts (work_items / work_item_transitions / decision_evidence_links 테이블 추가)
- Contract/Interface change: PRD-025 reason 구조화 계약 v1 (type/summary/tradeoff/evidenceRefs), WorkItem FK → decisions(id) 고정
- Contract/Interface change: DecisionVersion chain + active 포인터 이동 계약 확정

## 2026-02-27 PRD-022
- SSOT/Anchor change: Guardian Hook → InterventionRequired 신호 전용 확정 (StepResult mutation 금지, src/core/plan/plan.executor.ts)
- SSOT/Anchor change: Guardian은 집행 권한 없음 (Enforcer 전담)
- Entry/Touchpoint change: plan.executor.ts (runValidators → policyFindings 반환 구조 확정, persistSession evidence 저장 연동)
- Contract/Interface change: PRD-022 ValidatorFinding 타입 도입, logic_hash 기반 결정론 재현 계약 확정

---

## 2026-02-28 PRD-023
- SSOT/Anchor change: Retrieval 결과는 GraphState stepResults에 보관되나, PlanHash 계산에서는 제외하여 전략 변경 시 세션 해시 불변성 유지 (src/core/decision/decision_context.service.ts)
- Entry/Touchpoint change: src/di/strategy_resolver.ts (검색 전략 동적 주입), src/core/decision/ (Hierarchical/Hybrid 전략 구현)
- Contract/Interface change: RetrievalResultV1 도입 (decisions/evidence/anchors/metadata), Strategy Provider ID 기반 주입 인터페이스 확정

## 2026-02-28 PRD-027
- SSOT/Anchor change: WorkItem 상태 전이는 append-only transition log를 SSOT로 사용 (src/adapter/storage/sqlite/sqlite.stores.ts#appendTransitionAtomic)
- Entry/Touchpoint change: src/core/plan/plan.executor.ts (runCompletionPolicy 및 상태 전이 검증 로직 삽입), src/adapter/storage/sqlite/ (WorkItemStore/TransitionStore 확장)
- Contract/Interface change: CompletionPolicyResultV1 도입 (verdict/auto_verify_allowed), IMPLEMENTED -> VERIFIED 상태 전이 전제 조건 강화

## 2026-02-28 PRD-028
- SSOT/Anchor change: RepoScan payload를 도메인 지식(Budget/ConflictPoints)의 SSOT로 확정 (runtime/orchestrator/run_request.ts#resolveAtlasDomainPack)
- Entry/Touchpoint change: src/policy/domain_pack/ (Resolver/Validator 신규), PolicyInterpreter (injectDomainPacks 추가)
- Contract/Interface change: AtlasDomainPackV1 (schema_version/scan_budget/conflict_points) 계약 확정, top-level allowlist 마이그레이션 규칙 적용
- Contract/Interface change: PlanHash 계산 시 step payload 명시적 제외 계약 (src/session/execution_plan_hash.ts)

---

## 2026-02-28 PRD-030
- SSOT/Anchor change: Guardian YAML(validators/postValidators) 선언 순서를 SSOT로 간주하고 PlanHash 입력에 포함 (LOCK-030-2)
- Entry/Touchpoint change: src/policy/interpreter/yaml.loader.ts (YAML 파싱), src/session/execution_plan_hash.ts (validators 해시 포함)
- Contract/Interface change: ExecutionPlanV1 인터페이스에 validators/postValidators 필드 추가 및 Deterministic Hash 계약 갱신 (docs/contract/specs/B-030_guardian_yaml_wiring.contract.md)

---

## 2026-02-28 PRD-031
- SSOT/Anchor change: GuardianAudit is audit-only persistence separated from PersistSession/SSOT; BlockKey SSOT is enforced via DB unique constraint (no in-memory registry)
- Entry/Touchpoint change: src/adapter/storage/sqlite/sqlite.storage.ts (guardian_audit_records table + unique BlockKey index), src/adapter/storage/sqlite/sqlite.stores.ts (GuardianAuditStore + insertFirstBlockAtomically)
- Entry/Touchpoint change: src/core/plan/plan.executor.ts (BLOCK/WARN/INFORMED_BLOCK flow wiring), runtime/graph/deps_factory.ts (version mismatch fail-fast + deps wiring)
- Contract/Interface change: GuardianAuditRecordV1 and BlockKey 4-tuple (planHash, turnId, validatorId, targetRootId) contract locked; findings excluded from PlanHash

---

## 2026-02-28 PRD-029
- SSOT/Anchor change: `(conversationId, turnId, targetRootId)` 3-tuple 기반 멱등성 검증 SSOT 확정
- Entry/Touchpoint change: `runtime/persistence/session_persist.ts` (PersistSession 핸들러 멱등 처리), `src/core/plan/plan.executor.ts` (제안 생성 및 개입 요청)
- Contract/Interface change: `PersistProposal` 및 `EvidenceRef` (minItems:1) 계약 확정, Planner의 권한 경계(Authority Boundary) 명문화

---

## 2026-03-01 PRD-033
- SSOT/Anchor change: Policy adoption moved to durable outbox + Post-Run Boundary execution (no PersistSession mutation)
- Entry/Touchpoint change: runtime/policy_registration/* (post_run_registration + registration_executor), sqlite outbox schema added
- Contract/Interface change: Single Registration Executor contract enforced; CLI unified to executor path; version-scoped idempotency locked

---

## 2026-03-02 PRD-034
- SSOT/Anchor change: MODIFY_POLICY 시 레지스트리 기반 `registeredPolicyRootId`를 SSOT로 강제하고 LLM 제공 rootId 무시 (LOCK-A)
- SSOT/Anchor change: REGISTER_POLICY 시 Post-Run Boundary에서 시드 기반 결정론적 `policyKey` 생성 (LOCK-B)
- Entry/Touchpoint change: `src/core/plan/plan.handlers.ts` (PersistDecision 단계의 interventionResponse 연동 및 rootId 고정), `src/adapters/web/web.server.ts` (구조화된 액션 파싱)
- Entry/Touchpoint change: `src/core/decision/decision.scope.ts` (`policy.` 계열 스코프 허용 목록 확장)
- Contract/Interface change: `DecisionReason`에 `policyRegistration` 시드 필드 추가, `PolicyRef`에 `registeredPolicyRootId` 필드 추가
- Contract/Interface change: `WebSubmitInput` -> `InterventionResponse` 채널 연동 및 결정론적 액션(APPROVE/MODIFY/REGISTER) 계약 확정
- **Status: CLOSED**

## 2026-03-02 PRD-035
- SSOT/Anchor change: `policy.<profile>.<mode>` 스코프에 대한 엄격한 3-segments 검증 규칙 SSOT 확립
- Entry/Touchpoint change: `src/core/decision/decision.scope.ts` (prefix-based isAllowedDecisionScope 구현)
- Entry/Touchpoint change: `src/core/plan/plan.handlers.ts` (interventionResponse -> decision.action 프로모션 배선)
- Contract/Interface change: `B-035` 정책 결정 코어 잠금 해제 및 배선 완료 계약 확정
- **Status: CLOSED**

---

## 2026-02-28 PRD-032
- SSOT/Anchor change: `freshSession` 기반 결정론적 재현성 검증 표준 SSOT 확립
- Entry/Touchpoint change: `runtime/cli/prd032_validate_seed.ts` (검증 자동화 스크립트), `docs/governance/SEED_DATA_SPEC.md` (데이터 명세)
- Contract/Interface change: `ValidationResultV1` 식별자 격리(snapshotId vs atlasFingerprint) 계약 확정
