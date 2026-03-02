# **PRD-026 — Atlas Index Engine**
> Index Build / Update + Partial Scan Budget Enforcer
> 상태: PLANNED | Phase 7 (PRD-022/025 선행 조건)

---

## 0. 배경 및 목적

PRD-022(Guardian), PRD-023(Retrieval), PRD-025(Capture Layer) 세 개가 모두 Atlas를 읽고 쓰는 구조인데, Atlas 자체를 생성·갱신·조회하는 엔진이 PRD로 존재하지 않았다.

**Atlas가 없으면:**
- PRD-025가 "어디에 Decision을 저장할지" 체계적으로 알 수 없다.
- PRD-022가 "어떤 ConflictPoints를 검사할지" 근거가 없다.
- PRD-023이 "어떤 범위를 검색할지" 인덱스가 없다.

**이 PRD의 목적:**
- Atlas 4대 인덱스를 생성·갱신·조회하는 SSOT 엔진 구현
- 부분 스캔 예산(scan_budget)을 Domain Pack 기반으로 집행하는 Enforcer 구현
- PRD-022/023/025의 공통 기반 레이어 확보

---

## 1. 핵심 원칙 (LOCK)

- Atlas는 **파생 인덱스**이며 원문 데이터를 저장하지 않는다 (pointer + fingerprint만)
- Index 갱신은 **Cycle 종료 시점에만** 수행한다 (실행 흐름 중 Atlas 직접 수정 금지)
- Scan Budget 집행 권한은 **Enforcer(코드)에만** 있다 (LLM이 예산을 직접 변경 불가)
- Atlas는 **결정론적**이어야 한다 (동일 레포 + 동일 Pin → 동일 Index 해시)

### 보강 LOCK (2026-02-26)

**[LOCK-A] Atlas는 파생 인덱스이며 SSOT가 아니다**

Session(PRD-004)과 Decision(PRD-005)이 각각의 SSOT이며, Atlas는 이들로부터 파생된 조회 인덱스다. Atlas 데이터가 Session/Decision과 충돌할 경우 Session/Decision이 항상 우선한다. Atlas를 SSOT처럼 취급하거나 Atlas 기반으로 Decision을 역산하는 구조는 금지한다.

**[LOCK-B] PersistSession과의 원자성 계약**

Cycle 종료 시 세션 저장(PersistSession)과 Atlas 갱신은 다음 순서를 따른다:
1. PersistSession 성공 → Atlas 갱신 시도
2. Atlas 갱신 실패 → Atlas는 이전 Snapshot 유지 (Stale 허용), 세션은 정상 저장 상태 유지
3. PersistSession 실패 → Atlas 갱신 시도하지 않음 (Fail-fast)

Atlas 갱신 실패는 세션 저장을 롤백하지 않는다. Atlas는 파생 인덱스이므로 Stale 상태가 세션 무결성보다 낮은 우선순위를 갖는다.

**Atlas 갱신 실패는 반드시 telemetry/monitoring에 기록된다.** Stale 상태가 조용히 누적되면 감사 레이어의 신뢰성이 훼손된다. 실패 기록은 최소한 다음을 포함한다: 실패 시각, 실패 원인, 마지막 정상 Snapshot ID.

**[LOCK-C] Decision ↔ Atlas 순환 트리거 방지**

Decision 변경이 Atlas 갱신을 트리거하고, Atlas 기반 검사가 다시 Decision 변경을 유발하는 순환 구조를 금지한다. Atlas 갱신은 오직 Cycle 종료 시점의 단방향 흐름으로만 발생하며, Atlas 조회 결과는 Decision 변경의 자동 트리거가 될 수 없다. Decision 변경은 반드시 사용자 확인 또는 명시적 Enforcer 집행을 통해서만 발생한다.

**[LOCK-D] Plan Hash와 Atlas Hash의 완전 분리**

`computeExecutionPlanHash` 입력에 Atlas 관련 필드(snapshotHash, indexHash 등)는 절대 포함되지 않는다. Plan Hash(PRD-012A)는 실행 계획의 결정론적 식별자이며, Atlas Snapshot Hash는 레포 인덱스 상태의 식별자다. 두 해시는 독립적으로 계산되고 독립적으로 검증된다.

---

## 2. Atlas 4대 인덱스 스키마

### 2.1 Structure Index
레포 내 Artifact의 레이어 구조와 주요 진입점을 기록한다.

```json
{
  "structureId": "string",
  "artifactLayer": "string",
  "entryPoints": ["string"],
  "pointer": "string",
  "fingerprint": "string",
  "updatedAt": "ISO8601"
}
```

### 2.2 Contract Index
변경 시 반드시 재검증이 필요한 상위 규칙을 기록한다.

```json
{
  "contractId": "string",
  "title": "string",
  "pointer": "string",
  "fingerprint": "string",
  "revalidationTriggers": ["string"],
  "updatedAt": "ISO8601"
}
```

### 2.3 Decision Index
핵심 결정 목록과 도메인 태그를 기록한다.

```json
{
  "rootId": "string",
  "title": "string",
  "domain": "string",
  "strength": "axis | lock | normal",
  "currentVersionId": "string",
  "pointer": "string",
  "updatedAt": "ISO8601"
}
```

### 2.4 ConflictPoints Index
자주 충돌하는 영역과 관련 Decision/Artifact를 기록한다.

```json
{
  "conflictPointId": "string",
  "title": "string",
  "riskLevel": "low | medium | high",
  "relatedDecisionRootIds": ["string"],
  "relatedArtifactPointers": ["string"],
  "updatedAt": "ISO8601"
}
```

---

## 3. Atlas Snapshot Hash

Atlas 전체 무결성 검증을 위한 해시 구조.

```json
{
  "snapshotId": "string",
  "bundlePin": "string",
  "repoRef": "string",
  "indexHashes": {
    "structure": "string",
    "contract": "string",
    "decision": "string",
    "conflictPoints": "string"
  },
  "compositeHash": "string",
  "createdAt": "ISO8601"
}
```

**원칙:**
- `compositeHash` = 4대 인덱스 해시의 정렬된 머클 구조 해시
- 동일 레포 + 동일 Pin 조건에서 동일 `compositeHash` 보장
- Snapshot은 Cycle 종료 시 생성되며 이전 Snapshot과 비교 가능

**[LOCK] Snapshot Hash 결정론 범위 명시**

compositeHash는 Decision DB 상태를 포함한다. DecisionIndex는 DB 기반이므로 동일 레포라도 Decision이 변경되면 compositeHash가 변경된다. 이는 의도된 동작이다.

해시 범위를 명확히 구분한다:
- `repoStructureHash` = Structure Index + Contract Index 해시만 (레포 구조 변경 감지용)
- `decisionStateHash` = Decision Index + ConflictPoints Index 해시 (Decision 상태 변경 감지용)
- `compositeHash` = `repoStructureHash` + `decisionStateHash` 의 머클 해시 (전체 Atlas 무결성)

두 해시를 분리함으로써 "레포 구조는 그대로인데 Decision만 바뀐 경우"와 "레포 구조가 바뀐 경우"를 구분하여 감지할 수 있다.

---

## 4. Index Build (초기 생성 파이프라인)

레포 최초 온보딩 시 Atlas를 생성하는 흐름.

```
레포 온보딩 요청
  → Domain Pack 로드 (allowlist / scan_budget / conflict 정의)
  → Structure Index 생성 (Artifact 레이어 스캔)
  → Contract Index 생성 (Contract 파일 스캔)
  → Decision Index 생성 (기존 Decision DB 동기화)
  → ConflictPoints Index 생성 (Domain Pack 정의 기반)
  → Atlas Snapshot Hash 생성
  → Atlas SSOT 저장 완료
```

**제약:**
- 스캔 범위는 Domain Pack의 `allowlist`와 `scan_budget` 내로 제한
- LLM은 스캔 범위를 제안할 수 있으나 실행은 Enforcer가 수행
- 빌드 중 오류 발생 시 Fail-fast (부분 완료 Atlas 저장 금지)

---

## 5. Index Update (Cycle 종료 갱신)

매 Cycle 종료 시 Atlas를 갱신하는 흐름.

```
Cycle 종료 신호
  → 변경된 Artifact fingerprint 비교
  → 변경 있음 → REVALIDATION_REQUIRED 표시
  → 변경 없음 → 재검증 생략
  → Decision Index 동기화 (새 DecisionVersion 반영)
  → ConflictPoints Index 갱신
  → Atlas Snapshot Hash 갱신
  → 이전 Snapshot과 diff 기록
```

**제약:**
- Cycle 종료 시점 외 Atlas 직접 수정 금지 (실행 흐름 중 mutate 불가)
- fingerprint 변경이 없는 Artifact는 재검증 생략 (비용 최소화)
- STRONG Evidence의 fingerprint 변경 시 재검증 등급 자동 승격

---

## 6. Partial Scan Budget Enforcer

Domain Pack이 정의한 예산 내에서만 부분 스캔을 허용하는 Enforcer.

### 6.1 Domain Pack scan_budget 구조
```yaml
scan_budget:
  max_files: 20
  max_bytes: 512000
  max_hops: 3        # ConflictPoint 확장 깊이
  allowlist:
    - "src/**"
    - "docs/**"
  blocklist:
    - "node_modules/**"
    - ".env"
```

### 6.2 Enforcer 동작
```
LLM이 artifact_requests 제출
  → Enforcer: allowlist 포함 여부 확인
  → Enforcer: blocklist 제외 여부 확인
  → Enforcer: max_files / max_bytes 초과 여부 확인
  → Enforcer: max_hops 초과 여부 확인
  → 통과 → 부분 스캔 실행
  → 초과 → 요청 차단 + 사유 기록
```

**LOCK:**
- LLM은 scan_budget을 직접 변경하거나 우회할 수 없다
- 차단된 요청은 메타데이터로 기록된다 (감사 가능)
- 예산 초과는 실행 차단이며 Intervention이 아니다 (Safety Contract)
- **Budget Enforcer는 `executePlan` 루프 구조를 변경하지 않는다.** Enforcer는 artifact_requests 검증 단계에서만 동작하며 실행 흐름(Step 순서/구조)에 개입하지 않는다. (Core-Zero-Mod 보장)

---

## 7. Atlas 조회 API

PRD-022/023/025가 공통으로 사용하는 조회 인터페이스.

### 7.1 인터페이스 정의
```typescript
interface AtlasQueryAPI {
  // 관련 Decision 조회
  queryDecisions(domain: string, keywords: string[]): DecisionIndexEntry[]

  // ConflictPoints 조회
  queryConflictPoints(domain: string, changeTypeId: string): ConflictPointEntry[]

  // Contract 조회
  queryContracts(keywords: string[]): ContractIndexEntry[]

  // Artifact 포인터 조회
  queryArtifacts(pointers: string[]): StructureIndexEntry[]

  // Snapshot Hash 조회
  getSnapshotHash(bundlePin: string): AtlasSnapshotHash
}
```

**원칙:**
- 조회 API는 읽기 전용 (write 권한 없음)
- 조회 결과는 캐싱 가능 (fingerprint 기반 무효화)
- 조회 자체는 scan_budget 소비 없음 (Index 조회 ≠ Artifact 스캔)

---

## 8. Planner / Enforcer 역할 분리

| 역할 | 담당 | 권한 |
|:--|:--|:--|
| Atlas 인덱스 읽기 + 관련 항목 선택 | LLM (Planner) | 읽기만 |
| artifact_requests 제출 | LLM (Planner) | 제안만 |
| scan_budget 검증 + 실행 | Enforcer (코드) | 실행 + 차단 |
| Atlas 갱신 | Enforcer (코드) | Cycle 종료 시만 |
| Snapshot Hash 생성 | Enforcer (코드) | 자동 생성 |

**핵심:** LLM은 "무엇을 보고 싶다"까지만 말한다. 실제 읽기와 갱신은 Enforcer가 수행한다.

---

## 9. 타 PRD와의 의존관계

| PRD | 의존 방향 | 내용 |
|:--|:--|:--|
| PRD-025 (Capture Layer) | PRD-026 필요 | DecisionProposal → Atlas Decision Index 갱신 |
| PRD-022 (Guardian) | PRD-026 필요 | ConflictPoints Index 기반 충돌 검사 |
| PRD-023 (Retrieval) | PRD-026 필요 | Atlas Decision Index 기반 검색 범위 결정 |
| PRD-005 (Decision Engine) | 기존 완료 | Decision DB → Decision Index 동기화 대상 |
| PRD-018 (Bundle Promotion) | 기존 완료 | Bundle Pin → Atlas Snapshot Hash 연동 |

---

## 10. Exit Criteria

| # | 종료 조건 | 비고 |
|:--|:--|:--|
| 1 | 레포 최초 온보딩 시 Atlas 4대 인덱스 정상 생성 | Structure / Contract / DecisionIndex / ConflictPoints |
| 2 | Cycle 종료 시 fingerprint 기반 Index Update 정상 작동 | 변경된 Artifact만 REVALIDATION_REQUIRED 표시 |
| 3 | Partial Scan Budget Enforcer 작동 | Domain Pack max_files / max_bytes 초과 요청 차단 확인 |
| 4 | Atlas 조회 API가 PRD-025 / PRD-022에서 사용 가능 | 공통 조회 인터페이스 확인 |
| 5 | 실행 중 Atlas mutate 금지 규칙이 테스트로 보장됨 | Cycle 종료 시점 외 수정 불가 |
| 6 | Atlas 조회 결과 결정론적 재현 가능 확인 | 동일 레포 + 동일 Pin에서 동일 compositeHash 생성 확인 |

**→ 6개 전부 통과 시 PRD-026 CLOSED**

---

## 11. Out of Scope

- Atlas UI / 시각화 (Phase 3 그래프 시각화로 Deferred)
- Semantic 충돌 탐지 (PRD-023 범위)
- Domain Pack Library / Validation (PRD-028 범위)
- 멀티 테넌트 Atlas 격리 (Platformization 단계)

---

*작성일: 2026-02-26 | 상태: 설계 승인 가능 | 선행 조건: PRD-005, PRD-018 완료 | LOCK-A/B/C/D 보강 + Hash 범위 분리 + Telemetry 명시 + Core-Zero-Mod 보장*
