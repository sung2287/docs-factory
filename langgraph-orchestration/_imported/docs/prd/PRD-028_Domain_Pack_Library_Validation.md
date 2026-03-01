# PRD-028 — Domain Pack Library & Validation
상태: DRAFT (Design 예정)

## 1. Objective
- AtlasDomainPack의 스키마 표준화 및 버전 관리 체계 구축
- Domain Pack Library 도입을 통한 재사용성 강화
- PolicyInterpreter 단계에서의 Pack Validation Fail-fast 체계 확립
- 복수 Domain(Multi-tenant/Multi-module) 공존 환경 대비

## 2. Non-Goals
- Retrieval 전략 변경 (PRD-023 범위)
- WorkItem/VERIFIED 상태 머신 변경 (PRD-027 범위)
- Guardian Enforcement 로직 수정 (PRD-022 범위)
- ExecutionPlan Hash 구조 자체의 변경 (필드 추가만 허용)

## 3. Current Architecture Snapshot
- **SSOT**: RepoScan Step Payload가 전체 도메인 지식의 단일 진실 공급원(SSOT)임.
- **Workflow**:
  `PolicyInterpreter` (Pack Validation 수행) -> `ExecutionPlan` 생성 -> `run_request` 실행 -> `AtlasIndexUpdater` (인덱스 반영)

## 4. AtlasDomainPack v1 Schema

```typescript
{
  "schema_version": "v1",
  "scan_budget": {
    "max_files": 0,
    "max_bytes": 0,
    "max_hops": 0,
    "allowlist": [],
    "blocklist": []
  },
  "conflict_points": [
    {
      "conflictPointId": "string",
      "title": "string",
      "riskLevel": "low" | "medium" | "high",
      "relatedDecisionRootIds": ["string"],
      "relatedArtifactPointers": ["string"]
    }
  ]
}
```

🔒 LOCK-028-1: `schema_version` 필드가 명시되지 않은 경우 "v1"로 간주하여 하위 호환성을 유지한다.

🔒 LOCK-028-2: Top-level `allowlist` 필드는 `scan_budget` 하위 필드로 점진적 마이그레이션을 수행한다.

## 5. Validation Policy

🔒 LOCK-028-3: Domain Pack Validation은 `PolicyInterpreter` 단계에서 수행하여 런타임 진입 전 차단한다.

🔒 LOCK-028-4: Validation 실패 시 `DOMAIN_PACK_VALIDATION_ERROR` 접두사를 가진 메시지와 함께 즉시 예외를 발생시킨다 (Fail-fast).

🔒 LOCK-028-VERSION-DEFAULT: schema_version 필드가 없을 경우 런타임은 내부적으로 "v1"로 보정한 뒤 검증 로직을 수행한다. 이는 기존 세션 및 YAML과의 하위 호환성을 보장하기 위함이다.

🔒 LOCK-028-OPTIONAL-FIELDS: AtlasDomainPackV1의 모든 필드는 optional이며, 존재하는 경우에만 유효성 검사를 수행한다.

### 검증 항목:
- `schema_version` 존재 여부 확인 (미존재 시 v1 보정)
- `max_files`, `max_bytes`, `max_hops`는 존재하는 경우 0 이상의 정수(non-negative integer)여야 함
- `allowlist`, `blocklist`는 존재하는 경우 문자열 배열이어야 함
- `conflict_points`는 존재하는 경우 각 엔트리에 필수 필드(`conflictPointId`)가 존재해야 함

## 6. ExecutionPlan & Hashing

🔒 LOCK-028-HASH-FLOW:
- ExecutionPlan hash는 각 step의 `id` + `type` 기반으로 결정된다.
- RepoScan payload는 hash 계산 시 정규화(`normalizeExecutionPlanForHash`) 단계에서 명시적으로 제외된다.
- 따라서 DomainPack의 inline 주입이나 내용 변경은 hash 불변성을 깨뜨리지 않는다.

🔒 LOCK-028-5: Library pack은 로딩 직후 ExecutionPlan의 RepoScan payload에 "resolved inline 주입"되어야 한다.

## 7. Compatibility & Migration Strategy

🔒 LOCK-028-MIGRATION:
- **Top-level allowlist 마이그레이션**:
  - 존재 시: `scan_budget.allowlist`로 자동 이관하고 경고 로그를 출력한다.
  - 중복 시: `scan_budget.allowlist`를 우선하며, top-level은 무시하고 경고를 출력한다.
  - 향후 점진적으로 완전 제거 예정이다.

- **PRD-022~027 충돌 여부**: 없음.
  - PRD-027(WorkItem)의 `decision_id` 바인딩 규칙과 독립적임.
  - PRD-023(Retrieval)의 데이터 소스로 활용될 뿐 로직 간섭 없음.

## 8. Exit Criteria
| # | 조건 | 비고 |
|:--|:--|:--|
| 1 | `schema_version` 기본값(v1) 처리 전략 구현 완료 | |
| 2 | Validation Fail-fast 엔진 동작 확인 | PolicyInterpreter 단계 |
| 3 | Library pack inline 주입 및 ExecutionPlan 생성 검증 | |
| 4 | Top-level `allowlist` 마이그레이션 로직 구현 및 테스트 | |
| 5 | 2개 이상의 Pack 공존 시 충돌 없이 로딩 테스트 완료 | |
