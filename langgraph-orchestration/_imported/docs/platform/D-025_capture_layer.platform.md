# **D-025 — Capture Layer Platform Spec**
> Platform Enforcement & Storage Specifications

---

## 1. Enforcer Rules (Validation & Commit)

플랫폼은 결정(Decision)이 영속성 경계에 도달하기 전에 다음 규칙을 강제해야 한다.

### 1.1 Enforcement Policy (LOCK)

- **Structured Reason Validation:** 플랫폼은 `reason` 객체가 `B-025` 계약의 스키마를 준수하는지 반드시 검증해야 한다.
- **Validation Details:**
  - `reason.type`은 유효한 Enum 값이어야 한다.
  - `reason.summary`는 앞뒤 공백 제거 후 비어 있지 않아야 한다.
  - `reason` 객체가 누락된 경우 커밋은 반드시 차단되어야 한다.
- **Evidence Verification:** 플랫폼은 루트 `evidenceRefs`가 비어 있지 않음을 반드시 확인해야 한다.
- **Error Handling:** 검증 실패 시 해당 위반은 `BLOCK` 범주로 처리되며, 시스템은 `InterventionRequired` 상태로 전이되어야 한다.

### 1.2 Commit Sequence (Architectural)

검증은 실행 계획(Plan Execution)과 영속성 계층(Persistence) 사이의 경계에서 발생한다. Capture Layer 검증이 성공하지 않는 한 어떠한 결정도 영속 저장될 수 없다.

---

## 2. Storage & Persistence Rules

### 2.1 DecisionVersion 레코드 저장

- **JSON Storage:** `reason` 객체는 `DecisionVersion` 레코드에 전체 JSON 구조로 영속 저장된다.
- **Extension Slot (vaultRefs):** `DecisionVersion` 테이블은 `vaultRefs` (JSON array) 컬럼을 nullable로 허용한다. (Future-compatible)
- **PII Isolation:** Vault payload는 별도 저장소(Vault Layer)로 분리되며, 본 테이블에는 식별자(Refs)만 저장한다.
- **Metadata Exclusion:** `conversationTurnRef`는 입력 메타데이터이며, `decisions` 테이블의 영속 모델에 포함되지 않는다.

### 2.2 Atlas Indexing & Storage Responsibility

- **PRD-026과의 연동:** Atlas의 `DecisionIndex`는 검색 최적화를 목적으로 하며, `reason` 객체의 전체 페이로드를 저장하지 않는다.
- **Responsibility Boundary:** PRD-025는 검증 및 기록 정책을 정의한다. Atlas 동기화 및 인덱싱은 PRD-026의 Cycle-End 프로세스의 책임으로 남는다.
- **Vault Filtering:** Atlas 인덱싱 로직은 `vaultRefs` 내부 데이터를 인덱싱하지 않으며, 존재 여부만 메타데이터로 인지한다.

### 2.3 Plan Hash Calculation (Exclusion)

- **Plan Hash Isolation:** 구조화된 `reason`, `vaultRefs` 및 모든 런타임 결정 페이로드(Decision Payload)는 `Execution Plan Hash` 계산에 포함되어서는 안 된다.
- **Rationale:** 사유 문구 또는 PII 참조의 변경이 실행 계획의 해시를 변경하지 않도록 보장하여, 불필요한 전체 재검토를 방지한다.

### Plan Hash Boundary Invariant (LOCK)

- Execution Plan Hash는 **Plan 구조(steps의 타입/순서/구성, 정책/메타데이터)** 만을 해싱 대상으로 한다.
- `steps[].payload` 및 런타임 결정 페이로드(예: `reason`, `vaultRefs`, `conversationTurnRef`, `evidenceRefs`)는 **해시 입력에서 항상 제외**된다.
- 이 불변 조건은 테스트로 고정되며, payload의 문구/값 변경은 `PLAN_HASH_MISMATCH`를 유발해서는 안 된다.

---

*작성일: 2026-02-27 | 상태: DRAFT (Hash Boundary Invariant Declared; pending code+tests) | D-025 UPDATED with abstract enforcement and storage rules*
