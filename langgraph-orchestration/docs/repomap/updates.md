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

## 2026-02-28 PRD-033 (Planned)
- SSOT/Anchor change: 승인된 Decision 기반 활성 Policy SSOT 승격 체계 도입
- Entry/Touchpoint change: `src/core/decision/policy_promotion.service.ts` (신규 승격 엔진)
- Contract/Interface change: Decision ↔ Policy 버전 매핑 및 추적성 계약 확립

---

## 2026-03-01 PRD-034 (DESIGN DRAFT)
- SSOT/Anchor change: 정책 수정 시 신규 DecisionVersion 생성을 통한 버전 체인 SSOT 유지 (overwrite 금지)
- Entry/Touchpoint change: `src/session/intervention_handler.ts` (사용자 정책 수정 루프), `src/core/plan/plan.executor.ts` (구조화된 POLICY 위반 보고서 생성)
- Contract/Interface change: `GraphIntervention` 스키마 확장 (`policyFindings` 필드 추가), 3-way 사용자 응답(KEEP/MODIFY/REGISTER) 계약 확정

---

## 2026-02-28 PRD-032
- SSOT/Anchor change: `freshSession` 기반 결정론적 재현성 검증 표준 SSOT 확립
- Entry/Touchpoint change: `runtime/cli/prd032_validate_seed.ts` (검증 자동화 스크립트), `docs/governance/SEED_DATA_SPEC.md` (데이터 명세)
- Contract/Interface change: `ValidationResultV1` 식별자 격리(snapshotId vs atlasFingerprint) 계약 확정
