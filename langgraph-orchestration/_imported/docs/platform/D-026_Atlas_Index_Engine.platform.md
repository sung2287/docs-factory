# **D-026 — Atlas Index Engine Decisions**
> Reference: PRD-026 (Atlas Index Engine)
> Status: DESIGNED | Core-Zero-Mod Guaranteed

---

## 1. Architectural Decisions

### 1.1 Atlas as a Derived Index
- **Decision**: Atlas는 SSOT가 아닌 파생 인덱스(Derived Index)로 위치시킨다.
- **Rationale**: 세션(PRD-004) 및 결정(PRD-005) 데이터와의 중복 저장을 피하고, 원본 데이터의 무결성을 보장하기 위해 Atlas는 조회 성능 최적화 계층으로만 한정한다.
- **Consequence**: Atlas 데이터 소실 시, 세션 및 결정 DB로부터 언제든지 재빌드가 가능하다. Atlas Stale 상태가 허용되므로 시스템 가용성이 높아진다.

### 1.2 Dedicated `atlas_indices` Table in SQLite
- **Decision**: Atlas 인덱스를 SQLite 내 별도의 `atlas_indices` 관련 테이블군으로 관리한다.
- **Rationale**: 대규모 인덱스 조회 성능을 확보하고, 결정 DB와의 트랜잭션 분리를 용이하게 하기 위함이다.
- **Consequence**: 별도 테이블 관리를 통해 인덱스 갱신 실패가 원본 DB 무결성에 미치는 영향을 최소화한다.

### 1.3 Reject File-based SSOT
- **Decision**: 인덱스 원천 정보를 파일 기반으로 관리하는 방안을 거부한다.
- **Rationale**: 파일 시스템 기반의 동시성 제어 및 조회 복잡도가 높으며, 이미 존재하는 SQLite 인프라를 활용하는 것이 비용 효율적이다.
- **Consequence**: 데이터 정합성 보장이 용이하며, 기존 백업 및 복구 체계를 그대로 활용한다.

### 1.4 Reject Runtime Hook Implementation
- **Decision**: Atlas 조회를 별도의 Runtime Hook으로 구현하지 않고, API 서비스 레이어로 제공한다.
- **Rationale**: Hook은 실행 흐름(executePlan)에 개입하여 성능 및 복잡도를 높일 수 있으나, API는 필요한 시점에만 호출되므로 "Core-Zero-Mod" 원칙에 더 부합한다.
- **Consequence**: Runtime Core와의 결합도가 낮아져 독립적인 업데이트 및 테스트가 가능하다.

---

## 2. Hash Design Decisions

### 2.1 Complete Separation of Plan Hash and Atlas Hash
- **Decision**: `Plan Hash`와 `Atlas Hash`를 완전히 분리하여 계산한다.
- **Rationale**: 실행 계획의 결정론(Plan Hash)은 인덱스 상태(Atlas Hash)에 의존해서는 안 된다. 인덱스는 단순히 조회 속도와 범위를 돕는 도구일 뿐, 실행 로직의 본질이 아니기 때문이다.
- **Consequence**: 인덱스가 Stale 하거나 갱신되더라도 실행 계획의 해시는 변하지 않아, 캐시 히트율(PRD-012A)을 유지할 수 있다.

### 2.2 Hash Domain Separation (Structure vs State)
- **Decision**: `repoStructureHash`와 `decisionStateHash`로 도메인을 분리한다.
- **Rationale**: 레포지토리의 물리적 구조 변경(코드 수정)과 논리적 상태 변경(결정 추가)을 구분하여 감지하기 위함이다.
- **Consequence**: 세밀한 무결성 검증이 가능하며, 특정 도메인의 변경 시 필요한 인덱스만 효율적으로 갱신할 수 있다.

---

## 3. Failure Handling Decisions

### 3.1 Atlas Stale Tolerance Policy
- **Decision**: Atlas 갱신 실패 시 일시적인 Stale 상태를 허용하고 세션 저장을 우선한다.
- **Rationale**: Atlas는 파생 인덱스이므로, 인덱스 갱신 실패 때문에 SSOT인 세션 저장이 롤백되는 것은 시스템 안정성을 저해하기 때문이다.
- **Consequence**: 서비스 연속성을 보장하되, Stale 상태를 모니터링하여 후행적으로 동기화할 수 있는 구조를 확보한다.

### 3.2 Compulsory Telemetry for Failure
- **Decision**: 모든 Atlas 갱신 실패를 Telemetry에 기록하도록 강제한다.
- **Rationale**: Stale 상태가 조용히 누적될 경우, Atlas 기반 감사 및 조회 데이터의 신뢰성이 훼손될 수 있기 때문이다.
- **Consequence**: 장애 인지 속도를 높이고 인덱스 불일치 문제를 조기에 발견할 수 있다.

---

## 4. Rejected Alternatives

### 4.1 Internal Index Update within Steps
- **Rejected**: Graph Step 내부에서 인덱스를 직접 갱신하는 방식.
- **Reason**: Step Contract(PRD-007)를 수정해야 하며, 실행 중 Atlas 상태가 변할 경우 동일 Cycle 내에서의 조회가 비결정론적으로 변할 위험이 있다.

### 4.2 Runtime Mutation during Execution
- **Rejected**: 실행 흐름 도중에 Atlas를 동적으로 수정하는 방식.
- **Reason**: Runtime Core의 "Non-blocking" 및 "Zero-Mod" 원칙을 위반하며, 실행 추적이 복잡해진다.

### 4.3 Coupling Plan Hash with Atlas Hash
- **Rejected**: Plan Hash 입력값에 Atlas 상태를 포함하는 방식.
- **Reason**: 사소한 인덱스 갱신에도 모든 실행 캐시가 무효화되어 성능 저하를 유발한다. (PRD-012A 철학 위배)

---
*LOCK-A/B/C/D compliant. No implementation code included.*
