# REPO MAP (Where-to-Look Index)

Purpose: PRD 설계/조사 시 "어디를 먼저 볼지" 경계를 고정한다.
Rule:
- 1~2페이지 유지. 과도한 상세는 금지(상세는 PRD/Evidence Map로).
- 변경이 발생하면 먼저 updates.md에 3줄 기록 후, 필요할 때만 본문을 업데이트한다.
- 이 문서는 '현재 지도', updates.md는 '변화 이력'이다.

## Entry Points
- runtime/orchestrator/run_request.ts : run 요청 진입점, pin 검증 후 runGraph 호출 (runRuntimeOnce)
- runtime/cli/run_local.ts : CLI 로컬 실행 진입점, 인자 파싱 및 오케스트레이터 호출 (main)
- runtime/cli/prd005_smoke.ts : 스모크 테스트 실행기, 런타임 주요 기능 검증 (smokeTest)
- src/server/routes/dev_status.route.ts : 서버 상태 확인 API 진입점, 런타임 헬스체크 (devStatusRoute)
- runtime/cli/prd032_validate_seed.ts : PRD-032 라이브 검증 하네스 CLI, 반복 실행 및 재현성 검증 (validateSeedRuns)

## Execution Loop
- runtime/graph/graph.ts : LangGraph 기반 실행 루프, step 전이 및 상태 관리 (runGraph)
- src/core/plan/plan.executor.ts : 코어 실행 엔진, step registry 조회 및 실행 (executePlan)
- runtime/graph/step_executor_registry.ts : 실행 단계별 핸들러 등록 및 조회 (createRuntimeStepExecutorRegistry)
- runtime/graph/plan_executor_deps.ts : 실행 엔진 의존성 구조 정의 (PlanExecutorDeps)

## State Mutation (SSOT)
- runtime/persistence/session_persist.ts : 세션 상태 저장 및 Atlas 업데이트 트리거 (createPersistSessionHandler)
- src/session/session.lifecycle.ts : 세션 생명주기 관리, 로딩/검증/저장 흐름 제어 (runSessionLifecycle)
- runtime/orchestrator/runtime.snapshot.ts : 런타임 세션 스냅샷 로드 및 초기화 (getRuntimeSessionSnapshot)
- runtime/orchestrator/session_namespace.ts : 세션별 네임스페이스 및 파일 경로 관리 (buildSessionFilename)

## Storage / Persistence
- src/adapter/storage/sqlite/sqlite.stores.ts : SQLite 테이블별 스토어 및 트랜잭션 구현 (WorkItemStore/DecisionStore)
- src/adapter/storage/sqlite/index.ts : SQLite 기반 영구 저장소 레이어 생성 (createSQLiteStorageLayer)
- src/session/file_session.store.ts : 파일 시스템 기반 세션 상태 저장소 (FileSessionStore)
- runtime/memory/in_memory.repository.ts : 단기 실행 컨텍스트용 인메모리 저장소 (InMemoryRepository)

## Hash / Determinism
- src/session/execution_plan_hash.ts : 실행 계획의 결정론적 해시 계산 (computeExecutionPlanHash)
- runtime/bundle/sorted_map_hash.ts : 맵 객체의 정렬 기반 일관된 해시 생성 (hashSortedMap)
- src/session/stable_stringify.ts : 키 정렬을 통한 결정론적 JSON 문자열화 (stableStringify)
- runtime/orchestrator/runtime_version.ts : 런타임 버전 및 핑거프린트 관리 (getRuntimeVersion)

## Repo Scan / Budget
- src/plugin/repository/scanner.ts : 리포지토리 파일 스캔 및 변경 감지 (scanRepository)
- src/atlas/budget/budget.enforcer.ts : 스캔 범위(파일 수/용량) 제한 집행 (createScanBudgetEnforcer)
- src/plugin/repository/snapshot_manager.ts : 리포지토리 스캔 결과 스냅샷 관리 (SnapshotManager)

## Atlas (Index / Update Anchor)
- src/atlas/atlas.updater.ts : 세션 저장 후 Atlas 인덱스 동기화 및 업데이트 (AtlasIndexUpdater)
- src/atlas/atlas.builder.ts : 스캔 데이터 기반 Atlas 인덱스 구조 구축 (AtlasIndexBuilder)
- src/atlas/atlas.store.ts : 인덱싱된 아티팩트 조회 및 검색 API (AtlasStore)
- src/atlas/atlas.hash.ts : Atlas 데이터 구조의 무결성 검증용 해시 (computeAtlasHash)

## Contract / Policy Resolution
- src/policy/interpreter/policy.interpreter.ts : 도메인 팩(Domain Pack) 및 모드 정책 해석기, 실행 계획 생성 및 가디언/도메인 인라인 주입 (PolicyInterpreter)
- src/policy/domain_pack/domain_pack.validator.ts : 도메인 팩 스키마 검증 및 마이그레이션 (validateDomainPack)
- src/policy/domain_pack/domain_pack.resolver.ts : 도메인 팩 라이브러리 파일(pack.json) 로드 및 파싱 (resolveDomainPack)
- runtime/llm/provider.router.ts : 정책에 따른 LLM 프로바이더 라우팅 (resolveProviderConfig)
- runtime/graph/deps_factory.ts : 런타임 의존성 주입 및 팩토리 생성 (createRuntimePlanExecutorDeps)
- src/policy/interpreter/yaml.loader.ts : 정책 설정 YAML 파일 로더 및 가디언 선언 해석 (loadYamlFile)
