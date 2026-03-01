# EVIDENCE MAPS (Accumulated)

Purpose: PRD 설계/리뷰 시 "어디가 위험/충돌 포인트인지"를 얇게 기록한다.
Rules:
- PRD별 1~2페이지를 넘기지 않는다.
- '어디를 봐야 하는지'는 RepoMap(Where)로 보낸다.
- 여기에는 '깨질 수 있는 지점/금지 삽입/SSOT anchor/해시 영향'만 적는다.
- 사후 작성은 RECONSTRUCTED로 명시한다.

Template per PRD:
- Scope: (이번 PRD에서 건드리는 축 3줄)
- Touchpoints: (핵심 파일/모듈 5~10개)
- Forbidden: (삽입 금지 지점/금지 방향)
- SSOT/Hash Impact: (영향 여부 + 규칙)
- Regression Risks: (회귀 위험 3~5개)
- Tests/Evidence: (통과 근거 포인터)

---

## Session Lifecycle & Enforcement
Status: RECONSTRUCTED
Scope:
- 세션 로딩, Pin 검증, 실행 후 상태 보존의 전체 흐름 제어.
- 로컬 파일 스토어와 런타임 스냅샷 간의 동기화 보장.
Touchpoints:
- src/session/session.lifecycle.ts#runSessionLifecycle
- runtime/orchestrator/run_request.ts#runRuntimeOnce
- src/session/file_session.store.ts#FileSessionStore
- runtime/orchestrator/runtime.snapshot.ts#getRuntimeSessionSnapshot
Forbidden:
- 실행 루프(executePlan) 내부에서 session.save() 직접 호출 금지.
- Pin 검증 없이 세션 상태를 런타임에 주입하는 행위 금지.
SSOT/Hash Impact:
- CORE_INVARIANTS §1 RULE (PersistSession anchor) 참조.
- PlanHash 불일치 시 세션 로딩 차단 (Strict Enforcement).
Regression Risks:
- 세션 덮어쓰기로 인한 과거 이력 소실.
- Pin 불일치 상태에서 Atlas 업데이트가 발생하는 경우.
Tests/Evidence:
- runtime/cli/prd004_smoke_persist.ts

---

## Deterministic Hashing Architecture
Status: RECONSTRUCTED
Scope:
- 동일 입력(Plan+Pin)에 대해 동일한 식별자(Hash/Id) 생성을 보장.
- Atlas 구조와 Execution Plan의 해시 영역을 엄격히 분리.
Touchpoints:
- src/session/execution_plan_hash.ts#computeExecutionPlanHash
- src/atlas/atlas.hash.ts#computeAtlasHashes
- src/session/stable_stringify.ts#stableStringify
- runtime/bundle/sorted_map_hash.ts#hashSortedMap
Forbidden:
- 해시 입력값에 timestamp, random UUID, rowid 포함 금지.
- PlanHash 계산에 Atlas 핑거프린트/snapshotId 포함 금지 (§2 RULE).
SSOT/Hash Impact:
- CORE_INVARIANTS §2 RULE (Hash Separation) 참조.
Regression Risks:
- 환경 차이(OS 경로 구분자 등)로 인한 해시 불일치.
- Guardian findings가 해시에 포함되어 재현성이 깨지는 경우.
Tests/Evidence:
- tests/session/execution_plan_hash.test.ts

---

## PRD-026 — Atlas Index Engine
Status: RECONSTRUCTED
Scope:
- 리포지토리 스캔 결과와 결정(Decisions)을 결합하여 Atlas 인덱스 구축.
- PersistSession 이후 결정론적 snapshotId 생성 및 저장.
Touchpoints:
- src/atlas/atlas.updater.ts#AtlasIndexUpdater
- src/atlas/atlas.builder.ts#buildAtlasDatasetFromScan
- src/atlas/atlas.store.ts#AtlasStore
- src/atlas/atlas.hash.ts#computeAtlasHashes
- src/plugin/repository/scanner.ts#scanRepository
Forbidden:
- executePlan 도중 Atlas 인덱스 직접 수정 금지.
- BudgetEnforcer 우회하여 대규모 파일 스캔 시도 금지.
SSOT/Hash Impact:
- compositeHash(repoStructure + decisionState) 기반 snapshotId SSOT.
Regression Risks:
- snapshotId 생성 시 입력 데이터 정렬 불일치로 인한 해시 오류.
- Scan Budget 초과 시 인덱스 불완전 생성 및 무결성 깨짐.
- Atlas update 실패 시 세션 영속화 데이터와의 상태 불일치.
Tests/Evidence:
- runtime/cli/prd005_smoke.ts
- src/atlas/atlas.hash.ts

---

## PRD-025 — Decision Capture Layer
Status: RECONSTRUCTED
Scope:
- 사용자 확정 기반 Decision Versioning 및 Evidence 연결.
- Version chain 보존 및 active pointer 이동 관리.
Touchpoints:
- src/adapter/storage/sqlite/sqlite.stores.ts#DecisionStore
- src/adapter/storage/sqlite/sqlite.storage.ts#createSQLiteStorageLayer
- runtime/persistence/session_persist.ts#createPersistSessionHandler
- src/core/plan/plan.handlers.ts#PersistDecision
- src/core/decision/decision_context.service.ts (Retrieval 진입 — PRD-023 Strategy 교체 경계)
Forbidden:
- 기존 Decision record 직접 overwrite (UPDATE) 금지.
- EvidenceRef 없이 Decision 생성 금지 (§3 RULE).
SSOT/Hash Impact:
- Decision ID는 snapshotId 생성의 입력값 (decisionStateHash).
Regression Risks:
- DecisionVersion chain 연결 시 previousVersionId 누락으로 인한 히스토리 단절.
- Active version pointer가 존재하지 않거나 무효화된 버전을 가리키는 현상.
- 복수 세션 병렬 실행 시 SQLite 트랜잭션 충돌로 인한 버전 충돌.
Tests/Evidence:
- runtime/cli/prd004_smoke_persist.ts
- src/adapter/storage/sqlite/sqlite.stores.ts

---

## PRD-022 — Guardian Enforcement Robot
Status: RECONSTRUCTED
Scope:
- 실행 전후(Preflight/Post) 정책 및 안전 가드레일 집행.
- 위반 사항을 InterventionRequired 신호로 변환하여 Core에 전달.
Touchpoints:
- src/core/plan/plan.executor.ts#runValidators
- src/core/plan/plan.types.ts#ValidatorFinding
- src/core/plan/validator.registry.ts
- src/adapter/storage/sqlite/sqlite.stores.ts#GuardianEvidenceStore
- runtime/graph/plan_executor_deps.ts#PlanExecutorDeps (Guardian 주입 경계)
Forbidden:
- Guardian이 GraphState를 직접 mutate (applyPatch 제외) 하는 행위 금지.
- Enforcer의 승인 없이 실행 차단 로직 직접 수행 금지 (§3 RULE).
SSOT/Hash Impact:
- logic_hash 기반 검증 결과 재현성 확보.
Regression Risks:
- logic_hash 검증 실패로 인해 정상적인 실행 단계가 예기치 않게 차단됨.
- PersistSession 도중 에러가 발생하여 Guardian findings가 소실되는 현상.
- Intervention 상태가 잘못 적용되어 실행 루프가 무한 반복되거나 중단됨.
Tests/Evidence:
- runtime/cli/prd005_smoke.ts
- src/core/plan/plan.executor.ts

---

## PRD-023 — Retrieval Intelligence Upgrade
Status: CLOSED (2026-02-28)
Scope:
- Hierarchical/Hybrid 검색 전략 포트 및 교체 가능한 구조.
- 품질 게이트(Quality Gate) 및 하이브리드 전략의 Failover 메커니즘.
- Retrieval 결과의 해시 격리 및 결정론적 순서 보장.
Touchpoints:
- src/core/decision/decision_context.service.ts
- src/di/strategy_resolver.ts
- src/core/plan/plan.handlers.ts#RetrieveDecisionContext
- src/di/provider_ids.ts
Forbidden:
- Core 로직(plan.executor) 내부에서 특정 검색 전략에 의존하는 하드코딩 금지.
- 검색 결과가 PlanHash에 포함되는 행위 금지 (§2 RULE).
SSOT/Hash Impact:
- 검색 결과는 GraphState에 패치되나 PlanHash 불변성 유지.
Regression Risks:
- 전략 전환 시 결과 순서 불일치로 인한 LLM 응답 변동.
- Failover 미작동 시 특정 검색 엔진 장애가 전체 중단으로 확산.
Tests/Evidence:
- tests/integration/prd_023_retrieval_intelligence_upgrade.test.ts

---

## PRD-027 — WorkItem Completion & VERIFIED
Status: CLOSED (2026-02-28)
Scope:
- WorkItem 상태 머신(IMPLEMENTED -> VERIFIED -> CLOSED).
- Domain Pack 기반 Completion Policy Evaluator 집행.
- 자동 검증(auto_verify_allowed) 및 개입(Intervention) 흐름.
Touchpoints:
- src/adapter/storage/sqlite/sqlite.stores.ts#WorkItemStore
- src/core/plan/plan.executor.ts#runCompletionPolicy
- src/core/plan/plan.types.ts#CompletionPolicyResultV1
Forbidden:
- 상태 머신을 우회한 임의의 status UPDATE 금지.
- Evaluator 판정 없이 VERIFIED 상태 전이 금지.
SSOT/Hash Impact:
- WorkItem 상태는 Atlas 인덱스의 snapshotId에 직접 영향 없음.
Regression Risks:
- 상태 전이 로직 오류로 인한 WorkItem 고착(Stuck).
- Evaluator의 잘못된 판정으로 미완성 작업이 VERIFIED로 처리됨.
Tests/Evidence:
- tests/integration/prd_027_workitem_completion.test.ts

---

## PRD-028 — Domain Pack Library & Validation
Status: CLOSED (2026-02-28)
Scope:
- Domain Pack Library 관리 (policy/packs) 및 런타임 Resolve.
- PolicyInterpreter 단계에서 Pack 스키마 검증 및 RepoScan payload에 inline 주입.
- Top-level allowlist 마이그레이션 및 Optional 필드 유효성 검증.
Touchpoints:
- src/policy/interpreter/policy.interpreter.ts#injectDomainPacks
- src/policy/domain_pack/domain_pack.validator.ts#validateDomainPack
- src/policy/domain_pack/domain_pack.resolver.ts#resolveDomainPack
- runtime/orchestrator/run_request.ts#resolveAtlasDomainPack
- src/session/execution_plan_hash.ts#normalizeExecutionPlanForHash
Forbidden:
- ExecutionPlan hash 계산에 domainPack 내용을 포함하는 행위 금지 (§2 RULE).
- deepFreeze 이후 payload를 mutate 하거나 ref 기반으로 파일을 다시 읽는 행위 금지.
SSOT/Hash Impact:
- RepoScan payload가 도메인 지식의 SSOT이나, Hash 불변성은 id+type으로만 유지.
Regression Risks:
- Migration 로직 오류로 인한 budget(allowlist) 누락.
- Multi-pack 공존 시 전역 상태 오염으로 인한 격리 실패.
- JSON 파싱 오류 시 Fail-fast 실패로 런타임 불안정 초과.
Tests/Evidence:
- tests/policy/domain_pack_library_validation.test.ts
- src/policy/domain_pack/domain_pack.validator.ts

---

## PRD-030 — Guardian YAML Wiring
Status: CLOSED (2026-02-28)
Scope:
- ModeDefinition 스키마 확장 및 가디언(pre/post) 선언 지원.
- PolicyInterpreter 단계에서의 가디언 주입 및 PlanHash 일관성 확보.
Touchpoints:
- src/policy/interpreter/yaml.loader.ts
- src/policy/interpreter/policy.interpreter.ts
- src/session/execution_plan_hash.ts
- runtime/orchestrator/run_request.ts
Forbidden:
- PlanHash 입력에서 가디언 선언 순서를 무시하는 정렬 행위 금지.
- 개별 Step 하위로 가디언을 배치하는 행위 금지 (Root level 전용).
SSOT/Hash Impact:
- 가디언 선언 정보는 PlanHash의 필수 입력 요소 (LOCK-030-2).
Regression Risks:
- 가디언 선언 누락 시 위반 사항 차단 실패 (Silent failure).
- PlanHash 불일치로 인한 기존 세션 로딩 실패.
Tests/Evidence:
- YAML -> ExecutionPlan 주입 (정책 인터프리터 테스트)
- PlanHash에 validators/postValidators 포함 + 순서 민감성 (해시 테스트)
- NOTE: 라이브 BLOCK 실증은 allowStub/validator 선언 부재로 당시 검증 불가 → PRD-031/032에서 수행.

---

## PRD-031 — Guardian Rule Set Implementation
Status: CLOSED (2026-02-28)
Scope:
- stub validator 교체 및 실제 정책 로직 구현.
- Production-grade 가디언 집행 로직(BLOCK) 실증.
Touchpoints:
- src/core/plan/validator.registry.ts (등록)
- src/policy/guardian/validators/* (신규 정책 구현 경로)
- src/adapter/storage/sqlite/sqlite.storage.ts (guardian_audit_records table + unique BlockKey index)
- src/adapter/storage/sqlite/sqlite.stores.ts (GuardianAuditStore, insertFirstBlockAtomically, existsBlockKey)
- runtime/graph/deps_factory.ts (validator version mismatch fail-fast wiring)
- src/core/plan/plan.executor.ts (BLOCK/WARN/INFORMED_BLOCK routing + audit writes)
Forbidden:
- 가디언 내부에서 GraphState를 mutate 하거나 StepResult를 변형하는 행위 금지.
SSOT/Hash Impact:
- 가디언 findings는 PlanHash 입력에서 제외 (CORE_INVARIANTS §2 준수).
Regression Risks:
- 오탐(False Positive)으로 인한 정상적인 작업 차단.
Tests/Evidence:
- Guardian BLOCK 발생 로그 스냅샷
- InterventionRequired(source="GUARDIAN") 스냅샷
- 해당 validator 코드 경로 명시

---

## PRD-032 — Live Validation Harness & Seed Data Stabilization
Status: CLOSED (2026-02-28)
Scope:
- 실세션 실행을 통한 DB/Atlas 데이터 축적 및 라이브 검증 unblock.
- 결정론적 재현 시나리오 고정 및 검증 절차 문서화.
Touchpoints:
- runtime/cli/prd032_validate_seed.ts
- runtime/orchestrator/run_request.ts
- tests/integration/prd_032_live_validation_harness.test.ts
- src/session/execution_plan_hash.ts
- runtime/persistence/session_persist.ts
Forbidden:
- 시나리오 실행 중 Core 엔진 구조를 임의로 변경하는 행위 금지.
SSOT/Hash Impact:
- 누적된 Decision/WorkItem 데이터는 Atlas snapshotId 생성의 입력 SSOT임.
Regression Risks:
- 비결정론적 입력으로 인한 시나리오 재현 실패.
- 대량 데이터 축적 시 SQLite 성능 저하 및 교착 상태.
Tests/Evidence:
- Seed Run 실행 로그
- DecisionVersion 조회 결과
- WorkItem 상태 로그
- Atlas fingerprint 스냅샷
- cycle-end 갱신 로그

---

## PRD-029 — Persist Proposal (Ask-to-Commit)
Status: CLOSED (2026-02-28)

Scope:
- Planner 제안을 InterventionRequired로 변환.
- 사용자 승인 기반 PersistSession 집행.
- 3-tuple Idempotency 및 Evidence Gate 강제.

Touchpoints:
- src/core/plan/plan.executor.ts#executePlan
- runtime/persistence/session_persist.ts#createPersistSessionHandler
- src/adapter/storage/sqlite/sqlite.stores.ts
- src/session/execution_plan_hash.ts

Forbidden:
- executePlan 내부 DB write 금지.
- turnId 단독 멱등 판별 금지.
- Evidence 없는 Proposal 영속화 금지.
- Atlas 조회 결과로 자동 Decision 변경 금지.

SSOT/Hash Impact:
- PlanHash 입력 불변 유지 (§2 Hash Separation RULE 참조).
- snapshotId 계산 입력에 turnId 포함 금지.
- PersistSession anchor는 CORE_INVARIANTS §1 RULE 유지.

Regression Risks:
- Evidence Gate 누락으로 인한 무근거 Decision 생성.
- 멱등 키 오류로 중복 DecisionVersion 생성.
- Planner가 Enforcer 권한을 침범하는 경로 발생.
- Intervention 신호가 Guardian 신호와 혼동되는 경우.

Tests/Evidence:
- Idempotent 2회 실행 시 1회만 저장.
- conversationTurnRefs.length < 1 -> BLOCK 확인.
- PersistSession 이전 DB write 0회 보장.

---

## PRD-033 — Policy Registration Engine
Status: PLANNED
Scope:
- 승인된 Decision의 정책 규칙 승격 파이프라인.
- Decision ↔ Policy 간 결정론적 동기화 및 버전 관리.
- 정책 업데이트에 따른 ExecutionPlan 리빌드 메커니즘.
Touchpoints:
- src/policy/interpreter/policy.interpreter.ts
- src/core/decision/policy_promotion.service.ts (신규)
- src/adapter/storage/sqlite/sqlite.stores.ts (PolicyStore 확장)
Forbidden:
- 사용자 승인(PRD-029) 없이 정책 자동 승격 금지.
- 정책 승격 시 기존 세션의 PlanHash를 파괴하는 비결정론적 요소 삽입 금지.
SSOT/Hash Impact:
- 승격된 정책은 차기 세션의 ExecutionPlan 입력 SSOT가 됨.
- 정책 버전과 Decision ID 매핑 유지 필수.
Regression Risks:
- 정책 동기화 오류로 인한 런타임 구성 충돌.
- 리빌드 로직 결함으로 구버전 정책이 계속 적용되는 현상.

---

## PRD-034 — Policy Modification & Conflict Resolution Flow
Status: PLANNED
Scope:
- POLICY 위반 시 사용자 개입(Modification) 루프 구현.
- 정책 수정 시 신규 DecisionVersion 생성 및 감사 추적.
- 구조화된 정책 충돌 보고서 생성 엔진.
Touchpoints:
- src/core/plan/plan.executor.ts (POLICY finding 처리 분기)
- src/session/intervention_handler.ts
- src/adapter/storage/sqlite/sqlite.stores.ts (Version chain 관리)
Forbidden:
- SAFETY 클래스 위반에 대한 수정 허용 금지 (고정 정책 유지).
- 기존 정책 레코드에 대한 직접적인 overwrite (UPDATE) 금지.
SSOT/Hash Impact:
- 수정된 정책은 신규 DecisionVersion으로 관리되며, snapshotId 생성의 입력 SSOT임.
Regression Risks:
- 정책 수정 루프에서 무한 재귀 또는 교착 상태 발생.
- 사용자 응답 지연으로 인한 세션 타임아웃 처리 미흡.
