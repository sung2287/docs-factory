> Reference: PRD-024 (Seal Only)
> This document does not override SSOT.

# C-024: Seal Compliance Intent Map

본 문서는 PR Review 시 변경 사항이 PRD-024의 봉인 조건을 준수하는지 판단하기 위한 기준을 제공한다.

## 1. 위반 매핑 테이블

| Seal | 변경 유형 | 허용 여부 | 이유 | Reject 기준 |
|:---|:---|:---:|:---|:---|
| **Seal-A** | Receipt 기반 로직 제어 | **REJECT** | 영수증은 결과물이지 제어 신호가 아님 | Receipt의 특정 필드 값에 따라 Step 실행 여부가 결정되는 경우 |
| **Seal-B** | 기존 버전 번들 덮어쓰기 | **REJECT** | 버전 체인의 불변성 훼손 | 동일 버전 번들 ID에 대해 데이터가 변경되는 경우 |
| **Seal-C** | Guardian 내 GraphState 수정 | **REJECT** | 가디언은 상태 변이 권한이 없음 | Guardian 코드 내에서 State Mutation 메서드가 호출되는 경우 |
| **Seal-C** | Guardian BLOCK으로 실행 즉시 중단 | **REJECT** | BLOCK은 메타데이터 신호일 뿐 | Guardian 결과가 return/throw로 연결되는 경우 |
| **Seal-C** | Guardian이 writable state reference 획득 | **REJECT** | Snapshot 입력 원칙 위반 | Guardian 코드가 GraphState/ExecutionPlan을 직접 수정하거나 writable reference를 보유하는 경우 |
| **Seal-C** | HookClass가 명시적 필드가 아닌 휴리스틱 기반 분기 | **REJECT** | 단일 분기 기준 위반 | reason 문자열, validator_id 패턴 등으로 Sync/Async를 판단하는 경우 |
| **Seal-D** | 무제한 그래프 탐색 | **REJECT** | 시스템 가용성 위협 및 경계 훼손 | 분석 범위가 정의된 Subgraph를 넘어서거나 Loading Order를 무시하는 경우 |

## 2. Hook 판단 매트릭스

| Hook Type | BLOCK 의미 | 실행 중단 가능 여부 | 개입 필요 상태 기록 | 허용 계층 |
|:---|:---|:---:|:---:|:---|
| **Safety Hook** | 시스템 무결성 위반 | **YES** | 필요 시 (Fail-Fast) | Runtime Core |
| **Policy Hook** | 정책/거버넌스 부적합 | **NO** | **YES** | Guardian Layer |

Hook 분기 기준은 반드시 명시적 HookClass 필드로 결정되어야 하며, 휴리스틱 기반 분기는 허용되지 않는다.

## 3. Execution Flow vs Governance Signal 분리 매핑

| Trigger | Expected Behavior | Reject Condition | 책임 계층 |
|:---|:---|:---|:---|
| **Step 완료** | 결과 기록 및 Receipt 생성 | Receipt 데이터가 다음 Step의 Input으로 직접 주입됨 | Core Engine |
| **Guardian 검사** | 비동기 검증 및 Signal 생성 | 검증 결과가 나올 때까지 실행 루프가 동기적으로 대기함 | Guardian/Policy |
| **구조적 변경** | 버전 생성 및 Pinning | 기존 세션의 Pin 정보가 전역 설정 변경으로 자동 갱신됨 | Session Manager |
| **영향도 분석** | 지정된 범위 내 탐색 | 분석을 위해 비활성 모델이나 금지된 레이어를 로드함 | Structural Analyzer |
