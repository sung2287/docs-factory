# C-023 — Retrieval Strategy Intent Map

| Intent ID | Trigger | Expected Outcome | Forbidden |
|:---|:---|:---|:---|
| `INT-R01` | **SelectStrategy** | Bundle/Pin에 명시된 전략 식별 및 로드 | 설정된 `strategy_id`가 레지스트리에 없을 경우 |
| `INT-R02` | **ExecuteRetrieval** | p95 1200ms 이내에 `RetrievalResultV1` 반환 | Atlas 인덱스가 잠금 상태이거나 접근 불가능할 때 |
| `INT-R03` | **EvaluateQuality** | Baseline 대비 지표 하락 없음 (Precision/Recall) | 검색 결과가 비어있거나 스키마 위반 시 |
| `INT-R04` | **FailoverToBaseline** | `hierarchical_sql`로 즉시 전환 및 실행 계속 | 폴백 전략마저 실패할 경우 (System Failure) |

---
*Intent Map generated for PRD-023. Following ABCD spec.*
