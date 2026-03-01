# B-028 — Domain Pack Contract
> AtlasDomainPack v1 Type Definition & Validation Rule

## 1. Domain Pack Entity Structure (v1)

```typescript
type AtlasDomainPackV1 = {
  schema_version?: "v1";  // If undefined, treated as "v1"
  scan_budget?: {
    max_files?: number;
    max_bytes?: number;
    max_hops?: number;
    allowlist?: string[];
    blocklist?: string[];
  };
  conflict_points?: Array<{
    conflictPointId: string;               // Required
    title?: string;                        // Optional (fallback to id)
    riskLevel?: "low" | "medium" | "high"; // Default: "medium"
    relatedDecisionRootIds?: string[];
    relatedArtifactPointers?: string[];
  }>;
};
```

🔒 LOCK-028-TYPE-ALIGN:
PRD-028 스키마는 src/atlas/atlas.types.ts의 AtlasDomainPack 구조와 구조적으로 정렬되어야 한다.

🔒 LOCK-028-OPTIONAL-FIELDS:
AtlasDomainPackV1의 모든 필드는 optional이며, 존재하는 경우에만 유효성 검사를 수행한다.

## 2. Validation Rule Matrix

| Field | Type | Rule | Error Condition |
|:---|:---|:---|:---|
| `schema_version` | String | If null/undefined, treat as "v1" | N/A |
| `scan_budget.max_*` | Number (optional) | If present, must be >= 0 | `DOMAIN_PACK_VALIDATION_ERROR` |
| `scan_budget.allowlist` | String[] (optional) | If present, must be array of strings | `DOMAIN_PACK_VALIDATION_ERROR` |
| `conflict_points` | Array (optional) | If present, each entry must include `conflictPointId` | `DOMAIN_PACK_VALIDATION_ERROR` |

## 3. Error Code Standards

🔒 LOCK-028-4-SPEC: 모든 도메인 팩 검증 실패는 아래 접두사로 통일한다.
- `DOMAIN_PACK_VALIDATION_ERROR: <Specific Reason>`

## 4. Backward Compatibility & Migration Rules

- **Legacy Pack Handling**: `schema_version` 필드가 없는 파일 로딩 시, 런타임에서 `schema_version: "v1"`을 명시적으로 보정한 후 후속 프로세스에 전달한다.
- **Top-level Migration Strategy**:
  - `allowlist`가 최상위(top-level)에 존재할 경우 `scan_budget.allowlist`로 자동으로 이관하고 경고 로그를 출력한다.
  - 두 위치 모두 존재할 경우 `scan_budget.allowlist`를 우선하며, top-level은 무시하고 경고를 출력한다.
  - 향후 minor 버전에서 top-level 필드는 완전 제거될 예정이다.

## 5. Persistence & Hashing Contract

- **ExecutionPlan Payload**: Domain Pack은 `resolved inline` 형태로 `ExecutionPlan`의 `RepoScan` 페이로드에 포함된다.
- **Hash Integrity**: 
  - ExecutionPlan hash 계산은 `computeExecutionPlanHash()` 호출을 통해 수행된다.
  - `normalizeExecutionPlanForHash()` 단계에서 각 step의 `id` + `type`만 추출하며, Payload(domainPack 포함)는 정규화 단계에서 명시적으로 제외된다.
  - 따라서 DomainPack 내용의 변경이나 inline 주입은 hash 불변성을 깨뜨리지 않는다.
