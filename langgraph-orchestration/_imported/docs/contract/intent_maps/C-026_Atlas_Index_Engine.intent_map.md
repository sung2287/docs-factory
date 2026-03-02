# **C-026 — Atlas Index Engine Contract**
> Reference: PRD-026 (Atlas Index Engine)
> Status: DESIGNED | Core-Zero-Mod Guaranteed

---

## 1. Atlas Query API Contract

모든 Atlas 조회 인터페이스는 다음의 제약 조건을 **반드시(MUST)** 준수해야 한다.

- **Read-Only Guarantee**: `AtlasQueryAPI`는 조회 이외의 어떠한 상태 변경(Update, Insert, Delete) 권한도 가질 수 없다.
- **Caching Compliance**: `fingerprint` 기반의 캐싱 알고리즘을 사용하며, 원문 파일이 변경되지 않은 경우 조회 결과는 동일해야 한다.
- **Budget Exemption**: Index 자체 조회는 `scan_budget`을 소비하지 않는다.

### Required API
- `queryDecisions(domain: string, keywords: string[])`
- `queryConflictPoints(domain: string, changeTypeId: string)`
- `queryContracts(keywords: string[])`
- `queryArtifacts(pointers: string[])`
- `getSnapshotHash(bundlePin: string)`

---

## 2. Atlas Snapshot Contract

- **SnapshotId Creation Rule (Reinforced)**:
  - `snapshotId`는 반드시 `compositeHash`를 기반으로 결정론적으로 생성되어야 한다.
  - 동일한 `compositeHash`가 생성되는 경우, `snapshotId` 또한 동일해야 한다.
  - `snapshotId`는 시간(createdAt), 세션 ID, 환경 변수 등 비결정적 요소에 의존해서는 안 된다.
  - `bundlePin` 및 `repoRef`는 snapshotId의 의미적 식별자 역할을 할 수 있으나, snapshotId의 최종 값은 `compositeHash`로부터 파생되어야 한다.
- **compositeHash Boundary**: `repoStructureHash`와 `decisionStateHash`를 결합하여 계산하며, 동일한 레포지토리와 Pin 조건에서 동일한 해시 결과가 보장되어야 한다.
- **Deterministic Requirement**: 4대 인덱스의 필드가 동일한 경우 `compositeHash`는 100% 결정론적으로 재현 가능해야 한다.

---

### SnapshotId Deterministic Construction Rule

- **Stable Serialization Requirement**: `snapshotId`, `repoStructureHash`, `decisionStateHash`, `compositeHash` 계산 시 입력 데이터는 반드시 **stable stringify 규칙**을 따라 직렬화되어야 한다.
- **Field Order Determinism**: 객체 필드 순서는 사전순(lexicographical order)으로 정렬되어야 하며, 환경 의존적 key ordering은 허용되지 않는다.
- **Time Isolation**: `createdAt` 필드는 해시 계산에 포함되어서는 안 된다. (해시는 상태 기반이며 시간 기반이 아니다.)
- **Hash Input Boundary**:
  - `repoStructureHash` 입력: Structure Index + Contract Index 데이터만 포함
  - `decisionStateHash` 입력: Decision Index + ConflictPoints Index 데이터만 포함
  - `compositeHash` 입력: 위 두 해시만 포함 (원문 데이터 직접 포함 금지)

- **MUST NOT**: 환경 변수, 세션 ID, 실행 시각, telemetry 데이터 등 비결정적 요소를 해시 입력에 포함해서는 안 된다.

---

## 3. Index Update Contract

- **Cycle-End Sync**: Atlas 갱신은 반드시 `PersistSession`이 성공한 직후, 즉 Cycle 종료 시점에만 수행되어야 한다.
- **No Mutation during Execution**: `executePlan` 루프 실행 중에는 어떠한 Atlas 인덱스 데이터도 직접 수정하거나 갱신할 수 없다. (Read-Only context 보장)
- **Fingerprint Verification**: Artifact의 `fingerprint`가 변경된 경우에만 해당 항목에 대해 `REVALIDATION_REQUIRED` 표시를 갱신한다.

---

## 4. Budget Enforcer Contract

- **Enforcement Scope**: LLM의 `artifact_requests`에 대해 `max_files`, `max_bytes`, `max_hops` 한도를 엄격히 강제해야 한다.
- **Fail-Fast on Over-Budget**: 예산 초과 요청이 발생할 경우, Enforcer는 즉시 요청을 차단하고 `BudgetExceededError`를 기록해야 한다.
- **Core-Zero-Mod**: Budget Enforcer는 `executePlan` 루프의 구조나 Step 실행 순서를 변경하지 않으며, 오직 요청 검증 레이어에서만 동작한다.
- **Allowlist / Blocklist Integrity**: Domain Pack에 정의된 `allowlist` 이외의 경로나 `blocklist`에 포함된 파일에 대한 접근 요청은 즉시 차단되어야 한다.

---

## 5. Cross-PRD Compatibility Clause

- **PRD-004/005/006/007 Impact**: Atlas는 해당 PRD들의 SSOT 데이터를 활용하지만, 이들의 원본 데이터 구조를 수정하지 않는다.
- **PRD-012A (Plan Hash) Isolation**: **MUST NOT** include Atlas 관련 해시(snapshotHash, indexHash)를 `computeExecutionPlanHash`의 입력값에 포함하지 않는다.
- **PRD-021/024 Compatibility**: Atlas 인덱스 구조는 코어 확장성 및 워커 관리 패치와 상호 운용 가능해야 하며, 이들의 인터페이스를 침해하지 않는다.

---

## 6. Failure & Telemetry Contract

- **Failure Priority**: Atlas 갱신 실패는 `PersistSession`의 무결성에 영향을 주지 않아야 한다.
- **Telemetry Obligation**: Atlas 갱신 실패 시, 최소한 (시각, 원인, 이전 정상 Snapshot ID)를 Telemetry에 기록해야 한다.
- **Stale Recognition**: `getSnapshotHash`는 현재 상태가 Stale(최신 세션 미반영)인지 여부를 명시적으로 반환할 수 있어야 한다.

---
*LOCK-A/B/C/D compliant. No implementation code included.*
