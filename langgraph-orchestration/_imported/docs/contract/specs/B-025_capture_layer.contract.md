# **B-025 — Capture Layer Contract**
> DecisionProposal Schema + Commit Gate Rules

---

## 1. Data Contract (DecisionProposal)

`changeReason`은 Capture Layer 구조에 포함되지 않는다.
본 계약은 구조화된 `reason` 객체를 새로운 공식 사유 표현 방식으로 정의한다. 또한 향후 PII 격리를 위한 `vaultRefs` 확장 슬롯을 제공한다.

### 1.1 DecisionProposal 항목

- **create_work_item:** (Boolean, Default: true)
- **vaultRefs?:** string[] (Optional extension slot)
- **conversationTurnRef?:** string (Proposal 레벨 입력 전용)

### 1.2 DecisionReason Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "type": {
      "type": "string",
      "enum": ["CONSISTENCY", "RISK", "SECURITY", "PERFORMANCE", "UX", "MAINTAINABILITY", "OTHER"]
    },
    "summary": {
      "type": "string",
      "minLength": 1,
      "maxLength": 1000
    },
    "tradeoff": {
      "type": "string"
    },
    "evidenceRefs": {
      "type": "array",
      "items": { "type": "string" }
    }
  },
  "required": ["type", "summary"],
  "additionalProperties": false
}
```

### 1.3 Extension: Vault References
- **vaultRefs?: string[]**
  - Optional field.
  - Must **NOT** contain sensitive payload directly.
  - Only pointer references (IDs/URIs) allowed.
  - No validation enforced in PRD-025 scope (Future-compatible slot).

### 1.4 Structured Reason Contract (LOCK)

Decision Commit은 구조화된 reason 객체를 반드시 포함해야 한다.
reason이 없으면 Commit은 BLOCK(InterventionRequired) 처리된다.

LOCK:
- reason.summary는 trim 후 빈 문자열 불가
- reason.type은 enum 외 값 금지
- DecisionVersion에 reason은 영속 저장된다
- Atlas는 reason payload를 저장하지 않는다.
- Atlas는 reason의 구조적 필드에 대해 통계적/메타 인덱스만 가질 수 있다.

---

## 2. Commit Gate Rules

결정 커밋 시 다음 비즈니스 규칙이 적용된다.

### 2.1 Rule-001: Required Reason
- `reason` 필드가 누락되었거나 `null`인 경우 커밋을 거부한다.

### 2.2 Rule-002: Type Validation
- `reason.type`은 반드시 정의된 Enum 값 중 하나여야 한다.

### 2.3 Rule-003: Non-Empty Summary
- `reason.summary`는 공백을 제외하고 최소 1자 이상이어야 한다.

### 2.4 Rule-004: Summary Length Limit
- `reason.summary`는 1000자를 초과할 수 없다.

### 2.5 Rule-005: Evidence Required
- `evidenceRefs` 배열은 비어 있을 수 없다 (최소 1개 이상의 근거 필요).

"Evidence 필수 조건은 Commit 시점에 Capture Layer에서 검증된다.
현재 런타임 저장소 계층이 이를 강제한다고 가정하지 않는다."

### Evidence vs Reason Boundary (LOCK)

- `evidenceRefs` (루트)는 DecisionVersion의 공식 근거 집합이다.
- `reason.evidenceRefs`는 사유 설명 보조 필드이며 SSOT가 아니다.
- Commit Gate는 루트 `evidenceRefs`만 필수 조건으로 검사한다.
- Reason 필드만 존재하고 Evidence가 없는 Decision은 허용되지 않는다.

### SSOT Clarification (LOCK)

- Evidence는 Decision의 타당성을 판단하는 SSOT이다.
- Reason은 판단 메타데이터이며 SSOT가 아니다.
- Decision의 재검증 기준은 항상 Evidence에 기반한다.
- Reason은 분류/설명/통계 목적에만 사용된다.

---

## 3. Invariants (LOCK)

- **INV-1:** DecisionVersion ID는 생성 후 변경 불가.
- **INV-6:** conversationTurnRef는 입력 범위의 메타데이터이며, DecisionVersion의 영속 저장 모델에 포함되지 않는다.

---

## 4. Enforcement Policy

- 위 규칙 중 하나라도 위반될 경우 `DecisionVersion` 생성이 금지된다.
- Commit Gate는 해당 위반을 BLOCK 범주로 처리하며, 시스템은 InterventionRequired 상태로 전이된다.

---

*작성일: 2026-02-27 | 상태: DRAFT | B-025 UPDATED with INV-6 fix and LOCKs*
