# **🚀 [Master Blueprint] AI 장기기억 저술 SaaS & 메타 팩토리 아키텍처**

이 문서는 LangGraph 시스템의 상위 컨텍스트(Anchor Blueprint)이다.
새로운 설계 제안은 본 문서의 방향을 침해하지 않는 범위 내에서만 허용된다.
본 문서에 명시된 원칙은 PRD 및 구현 문서보다 상위 개념으로 간주된다.

## **I. Core Identity & Non-Negotiables (철학 및 핵심 가치)**

본 시스템은 "99%의 대중에게 창작의 환상을, 1%의 설계자에게 시스템 통제권을" 제공하는 것을 본질로 하며, 어떠한 경우에도 타협할 수 없는 다음의 원칙을 따른다.

*   **시스템의 실체**: 완벽한 결과물은 단일 AI의 지능이 아니라, 백엔드에 설계된 **'결정론적 메타 파이프라인(LangGraph)'**에서 나온다. 사용자는 대화만 하지만, 시스템은 의도를 정해진 스키마에 채워 넣어 세계관을 직조한다.
*   **[LOCK-1] SSOT 분리 선언**: 승격(Promote)되는 대상은 오직 'Workflow Bundle(컨텍스트 스펙)'뿐이다. 유저 데이터(원문/기억/세션)는 번들과 물리적/논리적으로 완전히 격리된다.

### [LOCK-X] Web Runtime Primacy Principle (제품 완결성 기준)

본 시스템에서 기능의 존재는 “웹 런타임(Web Runtime Surface)”에서 사용자에게 작동 가능한 상태를 기준으로 정의한다.

- 웹 인터페이스에서 실행·조작·검증이 불가능한 기능은 제품 기능으로 간주하지 않는다.
- CLI(Command Line Interface)는 개발, 디버깅, 운영, 실험을 위한 보조 계층이다.
- CLI 전용 기능은 Core Feature로 인정되지 않는다.
- CLI는 웹 기능 구현을 위한 중간 단계일 뿐, 완결 상태가 아니다.

### 기능 완결 정의 (Completion Definition Override)

기능의 완료(Complete)는 다음 조건을 모두 충족해야 한다:

1. Web Runtime Surface에서 실제 사용자 플로우로 작동할 것
2. 세션/상태/결정 구조와 정상 통합될 것
3. CLI 없이도 웹 환경에서 동일 기능을 수행할 수 있을 것

위 조건을 충족하지 못하면 해당 기능은 “실험 상태” 또는 “운영 도구”로 분류되며,
제품 기능으로 승격할 수 없다.

LOCK:
설계 단계에서 CLI 중심 구현이 존재하더라도,
웹 런타임 통합이 완료되지 않으면 기능은 완료로 선언할 수 없다.

*   **Runtime의 본질**: 런타임은 기본적으로 실행기(Executor)이며 데이터 평면(Data Plane)이다. 시스템은 기본적으로 비차단(Non-blocking) 원칙을 고수한다. 실행 차단은 번들 정책에 의해 발생하지 않으며, 오직 Runtime Core의 안전 계약(Fallback Contract) 범위 내에서만 제한적으로 허용된다. 정책은 실행을 제안하거나 경고할 수 있으나, Core가 아닌 정책이 직접 실행을 중단시키지 않는다. (상세는 02 참조)

    *   **비차단 원칙의 예외**: Runtime의 비차단 원칙은 “업무 실행 로직”에 적용된다. 단, 번들 무결성, 해시 불일치, 런타임-스키마 호환성 위반과 같은 Core 안전 계약 위반에 한해서는 즉시 Fail-fast를 허용한다. 이 예외는 정책 판단(Policy/Judge)과는 독립적이며, 번들 또는 정책이 실행 차단 권한을 갖는 것을 의미하지 않는다.

### **Guardian Loop Latency Budget Principle (Non-blocking Compatibility)**

Runtime은 비차단(Non-blocking)을 원칙으로 하며, Guardian Loop는 무결성 보장을 위한 수호 레이어이다. 따라서 Guardian Loop의 검증은 다음과 같이 2계층으로 분리되어야 한다:

- **Synchronous (Critical Core Checks)**: 번들 무결성, 해시 불일치, 런타임-스키마 호환성 등 Core-enforced Fallback 범위의 위반만 동기 검사로 처리한다. 위반 시 Fail-fast를 허용한다.
- **Asynchronous (Policy/Heuristic Checks)**: 정책 정합성 평가, 위험도 추정, 사후 감사 준비 등은 비동기 처리로 분리되며, Runtime의 기본 실행 흐름을 차단하지 않는다.

이 분리는 철학적 선택이 아니라 "비차단 원칙"을 보존하기 위한 구조적 계약으로 간주한다.
*   **기억의 SSOT 정의**: 
    *   **Decision**: 의미(Meaning)의 SSOT이며, 운영 DB에 저장되는 버전 관리된 규칙이다.
    *   **Anchor**: 네비게이션 전용(Navigation-only) 힌트이다. (상세는 03 참조)
*   **The Fuel Gauge Principle**: 엔진의 복잡한 내부는 은닉하되, AI의 기억 선명도와 판단 근거는 투명하게 노출하여 사용자에게 통제감을 부여한다. (상세는 IV 섹션 참조)
*   **윤리적 방어망**: 우리는 관계나 글쓰기를 파는 것이 아니라, '의사결정 증폭기'로서 사고의 흔적을 관리하고 결정을 내리기 쉽게 돕는 도구를 제공한다.

본 시스템의 장기 전략은 "결정론적 메타 파이프라인"을 실행 엔진에 국한하지 않고, 결정의 흔적(Decision Trace)을 관리하는 구조로 확장하는 것이다. 그러나 이는 철학 변경이 아니라, 기존 Decision SSOT 선언의 자연스러운 확장으로 간주된다.

### **Identity Evolution Declaration (Explicit Strategic Positioning)**

본 시스템은 단기적으로는 전문가가 재사용 가능한 Workflow Bundle을 설계·수익화하는 **Worker OS**로 기능한다.

그러나 장기적으로는 Decision을 의미 SSOT로 선언한 현재 구조를 확장하여, 실행 단위의 Decision Trace를 관리하는 **AI Decision Infrastructure**로 진화할 수 있는 잠재력을 내재한다.

이 진화는 철학의 변경이 아니라, "결정론적 메타 파이프라인" 선언의 구조적 확장으로 간주된다.

- 단기 포지셔닝: Expert Workflow Bundle 기반 생산성 OS
- 중기 확장: 검증된 Bundle 경제 및 기업 배포 모델
- 장기 잠재력: Decision Trace 및 Execution Evidence 관리 인프라

위 선언은 Blueprint의 상위 철학을 침해하지 않으며, Decision SSOT 원칙과 비차단 Runtime 원칙을 유지한 채 확장 가능성을 명시하는 전략적 포지셔닝이다.

---

## **II. System Architecture Overview (Builder ↔ Runtime)**

워크플로우 설계(Control Plane)와 실제 서비스(Data Plane)를 분리하여 운영 안정성과 확장성을 확보한다.

*   **투트랙 아키텍처**: 설계 앱(Builder)에서 깎고 테스트한 결과를 제품 엔진(Runtime)으로 밀어 넣는 **승격 파이프라인(Promotion Pipeline)** 구조를 가진다.
*   **Workflow Bundle**: 프롬프트, 정책, 루브릭을 하나로 묶은 배포 단위이다.
*   **Core-enforced Fallback**: 정책의 판단이 실패하거나 불확실할 때, 시스템은 정책이 아닌 Core의 안전 계약을 따른다.
*   **Guardian Loop**: 실행 전/후에 정책 정합성을 점검하여 시스템 무결성을 실시간으로 수호한다. (상세는 02 참조)

### **Builder Adoption Strategy (1% 설계자 UX 장벽 완화)**

Builder는 1%의 설계자가 Workflow Bundle을 제작·테스트·승격하는 Control Plane이다. 그러나 초기 시장 진입에서 설계 UX의 난이도는 핵심 리스크이므로, 다음의 전략을 전제로 한다:

- 초기에는 개발팀이 **1st Party Bundles(공식 번들)**을 직접 제작하여 템플릿/패턴 라이브러리를 축적한다.
- Builder는 점진적으로 **No-code/Low-code 노드 연결** 또는 템플릿 기반 편집 UX를 제공하여 설계자의 진입 장벽을 낮춘다.
- 이 과정은 Core를 바꾸지 않으며, 번들 제작 경험을 자산화하여 생태계를 확장하기 위한 제품 전략이다.

---

## **III. Cognitive Architecture & Memory Model**

*   **Planner-Worker & Judge**: 고성능 AI(디렉터)가 지시하고 가성비 AI(워커)가 증거를 수집하며, 판사 AI가 검수를 대행하는 구조이다.

### **1. Cognitive Hierarchy (Top-Level Declaration)**

본 시스템은 단순한 기억 저장 구조가 아니라, 계층적 인지 아키텍처(Cognitive Hierarchy)를 따른다. 이는 AI가 의미를 처리하는 사고 순서를 구조적으로 강제하기 위한 설계다.

인지 계층은 다음과 같이 정의된다:

*   **① Policy Layer (Invariant)**: 시스템의 불변 규칙 계층. Decision이 의미 SSOT로 위치하며, 설계 Drift 감지를 목적으로 한다. 실행 차단 권한은 없다. (상세는 02 참조)
*   **② Structural Memory (Relational Map)**: Decision 간 관계 및 의존성. Domain 기반 위계 구조로서 영향 분석의 설계 지도가 된다. 텍스트가 아니라 “관계”를 기억한다.
*   **③ Semantic Memory (Context Recall)**: Evidence 원문 및 Anchor 네비게이션 힌트. 유사 맥락 탐색을 수행하며 상위 계층을 override할 수 없다.

---

### Decision Origination Contract (Forward-Compatible Declaration)

Decision은 외부 입력(대화, API 호출, 시스템 이벤트 등)으로부터
구조화된 Capture Layer를 통해 생성된다.

이 Capture Layer는 Decision을 직접 저장하지 않으며,
구조화된 Proposal 단계를 거쳐 Memory SSOT 규칙에 따라 Commit된다.

이 선언은 Decision SSOT 철학을 변경하지 않으며,
Decision Trace 인프라 확장의 출발 지점을 명시하기 위한 구조적 슬롯이다.

---

### **2. Entity Mapping (Implementation Alignment)**

인지 계층과 메모리 엔티티는 다음과 같이 매핑된다:

*   **Decision** → Policy Layer
*   **Decision 간 관계 / Scope** → Structural Layer
*   **Evidence / Anchor** → Semantic Layer

Anchor는 Semantic 계층에 속하는 네비게이션 힌트이며, 상위 계층의 로딩 규칙을 절대 우회하지 않는다. (구현 세부는 03 참조)

---

### **3. Memory Ordering Principle (LOCK)**

의미 로딩은 반드시 다음 순서를 따른다:

**Policy Layer → Structural Layer → Semantic Layer**

하위 계층은 상위 계층을 우회하거나 무효화할 수 없다.

### **ExecutionReceipt as Structural Memory Trace (Forward-Compatible Concept)**

Decision이 의미의 SSOT라면, ExecutionReceipt는 실행 단위의 해시 기반 참조 영수증이다.

- 원문 데이터 저장을 확대하지 않는다.
- 해시 기반 참조 구조를 유지한다.
- Receipt는 Core를 복잡하게 만들지 않는다.
- 확장 필드는 Extension Block 구조로만 수용한다.

이는 Phase 3 확장을 위한 구조적 슬롯일 뿐, 현재 Runtime의 비차단 원칙이나 Policy Layer를 변경하지 않는다.

---

## **IV. Product Surface (UI/UX as Structural Expression)**

UI는 단순 프론트엔드 설계가 아니라, LangGraph의 구조 철학이 사용자에게 드러나는 표면 레이어이다. 따라서 UI 구조는 기능이 아니라 시스템 철학의 표현으로 간주한다.

*   **Tri-State Layout**: [네비게이터 - 메인 액션 - 상태 스트립]의 3단 구성을 통해 시스템 구조를 시각화한다.
*   **Project-Folder 세션 구조**: 세션이 특정 프로젝트의 기억과 정책 범위를 상속받도록 하여 의도 중심 인터페이스를 구현한다.
*   **연료 게이지 시각화**: AI의 기억 선명도와 판단 근거(Telemetry)를 투명하게 노출한다.

---

## **V. Expansion & Strategic Roadmap Intent**

*   **전문가 → 대중 확장**: 전문가용 런타임에서 정교한 '정책'과 '관계' 데이터를 수집하여 번들을 고도화하고, 이를 대중용 비서 엔진으로 이식하여 '딸깍' 수준의 품질을 보장한다.
*   **글로벌 확장**: 코어 수정 없이 도메인별/국가별 전용 '번들'을 제작하여 배포하는 전략을 취한다. (상세는 04 참조)

### **AI Worker OS → Decision Infrastructure Evolution Path (Strategic Intent)**

본 블루프린트는 단순한 저술 SaaS 아키텍처를 넘어서, 전문가 워커 OS에서 시작하여 AI Decision Infrastructure로 진화할 수 있는 구조적 잠재력을 내재한다.

이 진화는 기능 확장이 아니라, 기존 Cognitive Architecture와 Decision SSOT 구조의 확장적 적용이다.

#### Phase 1 — Expert Worker OS
- 전문가가 재사용 가능한 Workflow Bundle을 설계하고 수익화한다.
- Runtime은 실행기(Executor)로서 비차단 원칙을 유지한다.
- Bundle Pinning과 Decision Versioning은 자산화의 기반이 된다.

#### Phase 2 — Verified Bundle Economy
- 사고율 낮은 번들 선별
- Risk 메타데이터 축적
- Stable/Canary 분리
- 기업 배포 모델 확립

#### Phase 3 — Decision Evidence Infrastructure
- ExecutionReceipt 기반 실행 영수증 체계
- Decision 변경 체인 추적
- Immutable Audit Artifact 계층 형성
- 기업 감사/GRC 시스템 연동 가능 구조 확보

이 진화 경로는 Core 철학을 변경하지 않는다. 오히려 Decision을 의미 SSOT로 선언한 현재 구조의 필연적 확장이다.

### **Versioning & Backward Compatibility Principle (SSOT Separation Compatible)**

[LOCK-1]의 SSOT 분리 원칙을 유지하면서도, 번들/정책 진화로 인한 사용자 데이터 혼란을 방지하기 위해 다음의 원칙을 전제로 한다:

- Workflow Bundle과 Policy/Decision 변경은 **엄격한 버전 체계(예: Semantic Versioning)**를 따른다.
- 사용자의 프로젝트/세션은 기본적으로 **Bundle Pinning(고정)** 상태를 유지하며, 업그레이드는 사용자 선택(Opt-in)으로 처리한다.
- 업그레이드가 필요한 경우에도, 런타임은 과거 세션의 원문/기억을 "번들에 맞춰 강제 변환"하는 방식이 아니라, **호환 계층(Compatibility Layer) 또는 별도 마이그레이션 툴링**을 통해 단계적으로 처리한다.

이 원칙은 Version Drift를 통제하면서도, 99% 사용자의 지속 사용성을 보장하기 위한 제품/운영 규범이다.

---
*Last Updated: 2026-02-25 (Philosophy Anchor + Feedback Hardening: Latency/Builder/Versioning)*
