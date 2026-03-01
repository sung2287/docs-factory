# D-023 — Retrieval Strategy Port Platform Spec

## 1. DI Layer Injection Point
- **위치**: `src/di/strategy_resolver.ts` 내 `resolveDecisionContextProvider`
- **역할**: 설정된 `strategy_id`에 해당하는 클래스 인스턴스를 주입(Dependency Injection). 해당 지점은 고정이며 변경할 수 없다.

## 2. Strategy Registry Structure
- 플랫폼은 `StrategyRegistry`를 통해 사용 가능한 모든 전략을 관리한다.
- 신규 전략(`hybrid_v1`)은 `RetrievalResultV1` 인터페이스를 완벽히 구현해야 레지스트리에 등록 가능하다.

## 3. Metric Collection Slot
- 모든 검색 요청은 `took_ms`, `strategy_id`, `fallback` 여부를 측정하여 기록할 수 있는 Hook을 포함해야 한다.
- 해당 메트릭은 성능 예산(1200ms) 및 품질 관리의 근거가 된다.

## 4. Determinism Enforcement
- 외부 벡터 DB 또는 검색 엔진 연동 시, 결과를 결정론적으로 정렬하기 위한 `SortBy(id)` 등의 후처리가 보장되어야 한다.
- 시간 기반(Timestamp) 또는 무작위 가중치 기반 정렬은 허용되지 않는다.
- 동일 입력에 대해 Failover 발생 여부 또한 결정론적으로 재현되어야 한다.

## 5. Runtime Override Prohibition
- `src/core/decision/decision_context.service.ts`를 포함한 모든 Core 모듈은 실행 도중 주입된 Provider를 교체하거나 전략을 변경하는 로직을 포함해서는 안 된다.

## 6. Test Requirements
- **Determinism Test**: 동일 입력을 N번 반복 수행하여 검색 결과 순서 및 내용의 완전한 일치를 확인한다.
- **Compatibility Test**: `hierarchical_sql`과 `hybrid_v1` 결과가 GraphState merge 로직에 의해 정상적으로 통합되는지 검증한다.
- **Failover Test**: `hybrid_v1` 장애 상황을 모사하여 `fallback: true` 설정 및 Telemetry 기록 여부를 검증한다.
- **Quality Regression Test**: Baseline 대비 Recall regression 5% 초과 여부 및 STRONG Decision 누락 여부를 체크한다.

---
*Platform Spec generated for PRD-023. Following ABCD spec.*
