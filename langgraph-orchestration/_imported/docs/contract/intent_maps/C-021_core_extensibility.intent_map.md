# C-021: Core Extensibility Intent Map

## 1. Intent Context (Why & What)

### 1.1 Why Execution Hook exists
- **도메인별 비즈니스 검증 분리**: Core 로직을 오염시키지 않고 Guardian과 같은 정책 검증을 독립적으로 삽입하기 위함이다.
- **실행 전/후 정합성 확보**: Step 실행 직전의 입력값과 직후의 결과값을 검토하여 정책 준수 여부를 확인하기 위함이다.

### 1.2 What it must NEVER become
- **실행 제어기 (Flow Control)**: Hook은 조건문이나 루프를 대체하는 도구가 아니다.
- **데이터 변조기 (Mutation Layer)**: Hook은 Step의 데이터를 수정하거나 가공하여 다음 단계로 넘기는 역할을 할 수 없다.

### 1.3 Guardian vs Safety Contract distinction
- **Guardian (Hook)**: 정책적 정합성(Policy Compliance)을 체크하며, 위반 시 개입(BLOCK) 신호를 보낸다.
- **Safety Contract (Core)**: 시스템의 무결성(Integrity), 해시, 버전을 체크하며, 위반 시 즉시 차단(Fail-fast)한다.

---

## 2. Intent Behavior Table

| Intent | Trigger | System Reaction | Ownership |
|--------|---------|----------------|-----------|
| 정책 위반 감지 (Policy Violation) | Validator BLOCK 신호 | `status = "InterventionRequired"` 전환, 사용자 개입 대기 | **Domain Pack (Validator)** |
| 실행 흐름 위반 차단 (Flow Integrity) | Hook의 StepResult 수정 시도 | **Safety Contract** 발동, 즉시 중단 (Fail-fast) | **Core** |
| 리트리벌 전략 교체 (Retrieval Strategy) | Bundle Manifest 내 Strategy ID 명시 | `DecisionContextProviderPort`를 통해 해당 전략 활성화 | **Bundle** |
| 메모리 로딩 순서 수호 (Memory Order) | Retrieval 요청 발생 | Policy → Structural → Semantic 순서 강제 | **Core** |
| 결정론적 해시 보장 (Determinism) | ExecutionPlan 생성/해시 계산 | Validator Signature를 해시 대상에 포함 | **Core** |
| 세션 재현성 유지 (Reproducibility) | 세션 재개 (Resume) | Pinned Strategy/Provider ID를 기반으로 환경 복구 | **Bundle / Pin Store** |

---

## 3. Structural Intent Boundaries

### 3.1 Strategy Port Intent Boundary
- **Storage**: 데이터베이스 쿼리, 벡터 검색 등 **데이터를 가져오는 행위**만 추상화한다.
- **Merge Logic**: 가져온 데이터를 **어떤 순서로 합치고 우선순위를 정할지**는 Core의 고유 권한이다.

### 3.2 Bundle-as-a-Unit Protection Intent
- 모든 확장 옵션(Strategy, Provider, Validator)은 **Bundle 단위**로 묶여야 한다.
- Runtime이 임의로 확장 옵션을 변경하는 것은 "Bundle의 무결성"을 해치는 행위로 간주한다.

### 3.3 Determinism as System Identity
- 동일한 ExecutionPlan과 동일한 Validator Signature를 가진 경우에만 동일한 해시를 가져야 한다.
- Validator의 로직 변경(validator_version 또는 logic_hash 변경)이 발생하면 Plan Hash는 반드시 변경되어야 한다.
- Signature 기반 해시는 이를 물리적으로 강제하는 장치이다.
