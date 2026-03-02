# **C-025 — Capture Layer Intent Map**
> Intent-based Outcomes for Decision Capturing

---

## 1. Intent Mapping Table

| Intent ID | Intent Name | Description | Outcome |
|:--|:--|:--|:--|
| **INT-007** | Commit Proposal | 결정을 최종 확정하여 `DecisionVersion` 생성 시도 | `DecisionVersion` 생성 또는 `BLOCK` |
| **INT-008** | Validate Reason | 제안된 결정 사유의 스키마와 분류 적합성 검증 | `Valid` 또는 `BLOCK` (Invalid → InterventionRequired) |
| **INT-012** | Structured Reason Missing | Commit without structured reason | Commit blocked (InterventionRequired) |

---

## 2. Intent Details (INT-007: Commit Proposal)

결정 제안 커밋 시의 세부 의도 맵.

### 2.1 Success Criteria
- `reason` 및 `evidenceRefs`가 모두 계약(`B-025`)을 준수할 경우 `DecisionVersion`이 성공적으로 생성된다.

### 2.2 Rejection & Block Conditions
다음 조건 중 하나라도 해당할 경우 커밋이 **차단(BLOCK)**된다.

| Condition | Reason | Expected Outcome |
|:--|:--|:--|
| 루트 `evidenceRefs` 누락 또는 빈 배열 | 근거 없는 결정 방지 (SSOT 위반) | `InterventionRequired` 시그널 방출 |
| `reason` 누락 | 사유 없는 결정 방지 | `InterventionRequired` 시그널 방출 |
| `reason` 스키마 위반 | 부정확한 분류 또는 비정상적인 데이터 | `InterventionRequired` 시그널 방출 |

### Evidence Boundary Clarification (LOCK Alignment)

- Commit Gate가 필수 검증 대상으로 삼는 것은 **DecisionProposal 루트의 `evidenceRefs` 필드**이다.
- `reason.evidenceRefs`는 사유 설명을 위한 보조 필드이며 SSOT가 아니다.
- `reason.evidenceRefs`의 존재 여부는 Commit 차단 조건이 아니다.
- Evidence SSOT는 항상 루트 `evidenceRefs`이다.
- Reason은 Evidence를 대체할 수 없다.

**참고:**
- `reason.summary`가 짧거나 부실한 경우 "의미 불충분"으로 간주하나, 스키마 검증(1자 이상)만 통과하면 기술적 차단 사유는 되지 않는다. (승인 보류 권장 사유)
- INT-008에서 Invalid 판정이 내려진 경우, INT-007 Commit Proposal은 BLOCK 처리된다.

---

## 3. Signal Specification

### 3.1 InterventionRequired Signal
- **Trigger:** INT-007 검증 실패 시
- **Payload:** `{ errorType: "BLOCK_VALIDATION", violations: string[], proposal: DecisionProposal }`
- **Behavior:** 런타임은 실행을 일시 중단하고 사용자의 명시적인 수정 또는 승인을 대기한다.

---

*작성일: 2026-02-27 | 상태: DRAFT | C-025 INITIAL DRAFT*
