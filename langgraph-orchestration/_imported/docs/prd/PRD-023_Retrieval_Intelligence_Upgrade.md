# PRD-023: Retrieval Intelligence Upgrade

## 1. Objective
본 PRD의 목적은 `DecisionContextProviderPort` 기반의 전략 주입 구조를 활용하여 의사결정 맥락(Decision Context) 검색의 품질을 고도화하는 것이다. 기존의 계층적 SQL 검색을 유지하면서도, 의미론적(Semantic) 검색이 결합된 하이브리드 전략을 도입하여 복잡한 도메인에서의 검색 정합성을 향상시킨다.

## 2. Non-Goals
- 실시간 인덱스 업데이트 (Atlas Cycle-End 원칙 유지)
- 검색 결과를 Plan Hash 계산에 포함 (PRD-012A 분리 원칙 유지)
- 실행 중 사용자에게 검색 전략 선택권 부여 (Runtime Override 금지)

## 3. Architecture Overview: Strategy Port
`DecisionContextProviderPort`를 통해 검색 로직을 추상화한다. Core 런타임은 특정 검색 엔진의 구현 상세를 알 필요 없이, 주입된 전략으로부터 표준화된 `RetrievalResultV1`을 전달받는다. 이 결과는 기존의 GraphState merge 로직과 완전한 호환성을 유지해야 한다.

## 4. Strategy Selection Model
- **Default Strategy**: `hierarchical_sql` (기존 안정화된 계층 검색)
- **Additional Strategy**: `hybrid_v1` (Semantic + SQL 결합)
- **Binding**: 검색 전략은 세션 시작 시 Bundle/Pin 레벨에서 결정되며, 세션 도중 변경될 수 없다.

## 5. Failure & Failover Policy
- **Automatic Fallback**: `hybrid_v1` 검색 실패 또는 타임아웃 발생 시, 시스템은 사용자 개입 없이 즉시 `hierarchical_sql`로 폴백한다.
- **Metadata Flag**: 폴백 발생 시 `metadata.fallback` 필드를 `true`로 설정한다.
- **Logging**: 폴백 발생 시 반드시 Telemetry에 기록하고, Evidence로 남겨 사후 분석이 가능하도록 한다.

## 6. Determinism Rules
- 동일한 Atlas 인덱스와 동일한 쿼리에 대해, 동일 전략은 반드시 동일한 순서의 검색 결과를 반환해야 한다.
- Failover 발생 여부는 동일 입력 조건에서 동일하게 재현 가능해야 한다.
- 검색 엔진 내부의 무작위성(Randomness)은 배제되어야 한다.

## 7. Performance & Quality Gate
- **Latency Budget**: Retrieval 단계 단독 기준 p95 지연 시간은 **1200ms 이하**여야 한다.
  (LLM 추론 시간 및 후속 실행 단계는 포함하지 않는다.)
- **Quality Gate**:
    - **Precision@k**: 기존 Baseline(`hierarchical_sql`) 이상의 정확도를 유지해야 한다.
    - **Recall Policy**: Baseline 대비 Recall regression > 5%는 허용되지 않는다.
    - Baseline에서 반환되던 **STRONG Decision** 누락 발생 시,
      해당 전략(hybrid_v1)은 품질 검증 단계에서 BLOCK 처리되며,
      세션 실행은 자동으로 hierarchical_sql로 폴백되어 계속 진행된다.

## 8. LOCK Section
- **Strategy Selection**: Bundle/Pin 기반으로 결정론적으로 고정된다.
- **Plan Hash Isolation**: Retrieval 결과 및 `took_ms`, `runtime metric` 등은 Plan Hash 계산에 영향을 주지 않는다.
- **Atlas Boundary**: Retrieval 수행 중 Atlas 인덱스에 대한 쓰기(Mutate) 행위는 엄격히 금지된다.
- **Guardian Boundary**: Guardian은 Retrieval 과정을 Read-Only로만 관찰할 수 있다.
- **Plan Hash Drift 완전 차단**: Strategy implementation 변경(hybrid 내부 알고리즘 개선 포함)은 Bundle version 변경 없이 Plan Hash에 영향을 주어서는 안 된다. Retrieval 전략의 내부 점수 계산, 정렬 로직 개선, 임계값 조정 등은 세션 해시(Session Hash) 드리프트를 유발해서는 안 된다.
- **CompletionPolicy 경계 명시**: Retrieval 결과는 WorkItem 상태 전이를 직접 트리거할 수 없다. Retrieval은 컨텍스트 제공 계층이며, 상태 전이는 반드시 CompletionPolicy/Enforcer 계층을 통해서만 수행된다.

## 9. Exit Criteria
- `hybrid_v1` 전략의 p95 레이턴시 1200ms 이하 달성 증명.
- Baseline 대비 Quality Gate(Recall/Precision) 준수 지표 제시.
- 실패 상황에서 `hierarchical_sql`로의 무중단 폴백 및 Telemetry 기록 확인.
- **GraphState merge 회귀 테스트 통과** 및 기존 전략과의 완전 호환 확인.
- 동일 입력 N회 반복 시 결과 순서의 완전 일치 보장.
