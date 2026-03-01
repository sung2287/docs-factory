# B-023 — Retrieval Contract

## 1. RetrievalResultV1 Shape (Locked)
검색 결과는 기존 `hierarchical_sql` 전략 및 GraphState merge 로직과의 호환성을 위해 아래의 구조를 엄격히 준수해야 한다.

```ts
interface RetrievalResultV1 {
  readonly decisions: DecisionVersion[];
  readonly evidence: EvidenceRecord[];
  readonly anchors?: AnchorRecord[];
  readonly conflictPoints?: ConflictPoint[];
  readonly metadata: {
    readonly strategy_id: string;
    readonly took_ms: number;
    readonly fallback?: boolean;
  };
}
```

### Shape Constraints (LOCK)
- **필드 삭제 및 의미 변경 금지**: 기존 Core 엔진의 merge 로직 파손 방지.
- **Top-level 필드 추가 금지**: 확장은 오직 `metadata` 내부에서만 허용한다.
- **Consistency**: 반환되는 데이터 객체들은 시스템의 기존 스키마 정의(`DecisionVersion`, `EvidenceRecord` 등)와 일치해야 한다.

## 2. DecisionContextProviderPort Interface
```ts
interface DecisionContextProviderPort {
  getDecisionContext(query: string, options: RetrievalOptions): Promise<RetrievalResultV1>;
}
```

## 3. Strategy Selection Contract
- 전략 선택의 SSOT는 Bundle Configuration 및 Session Pin 데이터에 존재한다.
- 런타임 어댑터는 세션 초기화 단계에서 결정된 `strategy_id`를 고정하여 사용한다.

## 4. Prohibited Couplings
- **No Direct SQL access from Core**: Core 엔진은 DB에 직접 접근하지 않고 Port를 통해서만 컨텍스트를 획득한다.
- **No Atlas Mutation**: Retrieval 어댑터 내부에서 Atlas 인덱스 갱신 API 호출을 금지한다.

## 5. Telemetry & Evidence Format
- 폴백 발생 시(`fallback: true`) 기록 형식:
  `{ event: "RETRIEVAL_FAILOVER", from: "hybrid_v1", to: "hierarchical_sql", reason: string }`

---
*LOCK-A/B/C/D compliant. Generated for PRD-023.*
