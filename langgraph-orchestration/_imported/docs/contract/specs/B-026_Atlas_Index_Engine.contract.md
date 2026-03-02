# **B-026 — Atlas Index Engine Blueprint**
> Reference: PRD-026 (Atlas Index Engine)
> Status: DESIGNED | Core-Zero-Mod Guaranteed

---

## 1. System Positioning

Atlas Index Engine은 레포지토리의 구조와 결정 상태를 효율적으로 조회하기 위한 **파생 인덱스 계층(Derived Index Layer)**이다.

- **Non-SSOT Property**: Atlas는 Session(PRD-004) 및 Decision(PRD-005)으로부터 추출된 데이터의 인덱스일 뿐이며, 원천 데이터가 아니다.
- **Runtime Relationship**: Runtime Core 외부에서 동작하며, `artifact_requests` 검증 시 Budget Enforcer로 개입하고 Cycle 종료 시점에만 상태를 동기화한다.
- **Memory Relationship**: Decision DB(SQLite)의 상태를 `Decision Index`로 미러링하여 검색 성능을 최적화한다.

---

## 2. Component Architecture

### 2.1 AtlasIndexBuilder
- 레포지토리 최초 온보딩 시 Artifact와 Contract 파일을 스캔하여 초기 4대 인덱스를 생성한다.
- Domain Pack의 `allowlist`를 준수한다.

### 2.2 AtlasIndexUpdater
- Cycle 종료 시점(`PersistSession` 이후)에 변경된 Artifact의 fingerprint를 비교하여 인덱스를 갱신한다.
- `REVALIDATION_REQUIRED` 플래그를 관리한다.

### 2.3 AtlasSnapshotHasher
- `repoStructureHash`, `decisionStateHash`, `compositeHash`를 결정론적으로 계산한다.
- 머클 트리(Merkle Tree) 구조를 활용하여 무결성을 검증한다.

### 2.4 PartialScanBudgetEnforcer
- `artifact_requests`에 대해 `max_files`, `max_bytes`, `max_hops` 예산을 강제한다.
- 예산 초과 시 즉각적인 실행 차단(Safety Abort)을 수행한다.

### 2.5 AtlasQueryAPI
- PRD-022/023/025 등 외부 컴포넌트가 Atlas 인덱스를 조회할 수 있는 단일 인터페이스를 제공한다.
- **Read-Only**: Atlas 상태를 변경하는 기능은 포함하지 않는다.

### 2.6 Persistence Layer (SQLite)
- `atlas_indices` 테이블군을 통해 인덱스 데이터를 영구 저장한다.
- Snapshot 이력 및 Diff 데이터를 관리한다.

---

## 3. Lifecycle Diagram

### 3.1 Initial Build Flow
1. Repository Onboarding Request
2. Load Domain Pack (Budget & Allowlist)
3. Scan Artifacts -> Build `Structure Index`
4. Scan Contracts -> Build `Contract Index`
5. Sync Decision DB -> Build `Decision Index`
6. Initialize `ConflictPoints Index`
7. Generate Initial `Atlas Snapshot Hash`

### 3.2 Cycle Update & Persist Sequence
1. Runtime Execution Cycle Completion
2. **Step: PersistSession (SSOT Commit)**
3. IF PersistSession SUCCESS:
   - Compare Artifact Fingerprints
   - Sync New DecisionVersions to `Decision Index`
   - Update `ConflictPoints` & `Atlas Snapshot Hash`
   - Log Update Telemetry
4. IF Atlas Update FAIL:
   - Keep Previous Snapshot (Stale Allowed)
   - Record Failure Telemetry (Last Good Snapshot ID)

---

## 4. Hash Domain Separation

Atlas Hash는 Plan Hash와 완전히 분리되어 관리된다.

- **repoStructureHash**: 레포지토리의 물리적 구조(Artifact, Contract) 변경만 감지.
- **decisionStateHash**: Decision DB의 논리적 상태 변경만 감지.
- **compositeHash**: 위 두 해시를 결합한 전체 Atlas 무결성 식별자.
- **Plan Hash (PRD-012A) Isolation**: `computeExecutionPlanHash`는 Atlas 해시를 입력값으로 받지 않는다. 인덱스 상태는 실행 계획의 결정론에 영향을 주지 않는다.

---

## 5. Failure Policy

- **Stale Tolerance**: Atlas 갱신 실패는 세션 저장을 롤백하지 않는다. Atlas는 파생 데이터이므로 일시적인 Stale 상태를 허용하되, 세션 무결성을 최우선한다.
- **Telemetry Obligation**: 모든 Atlas 갱신 실패는 반드시 시스템 로그 및 Telemetry에 기록되어야 하며, 자동 복구 시도를 위한 트리거로 활용된다.

---

## 6. Core-Zero-Mod Guarantee

본 설계는 Runtime Core의 수정을 요구하지 않는다.

- **No New Steps**: `executePlan` 루프 내에 Atlas 전용 Step을 추가하지 않는다.
- **Hook Invariant**: 기존 Execution Hook 구조를 변경하지 않으며, Enforcer는 `artifact_requests` 처리 로직 내의 Validator로만 존재한다.
- **Loop Invariant**: Atlas 갱신은 `PersistSession` 이후의 사이드 이펙트로 처리되어 메인 실행 루프의 복잡도를 증가시키지 않는다.

---
*LOCK-A/B/C/D compliant. No implementation code included.*
