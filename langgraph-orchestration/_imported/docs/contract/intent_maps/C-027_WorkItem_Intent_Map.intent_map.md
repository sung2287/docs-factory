# C-027 — WorkItem Completion Intent Map
> Intent-based Outcomes for VERIFIED Transition

## 1. Intent Mapping Table

| Intent ID | Intent Name | Description | Outcome |
|:--|:--|:--|:--|
| INT-027-01 | Evaluate Completion | completion_policy로 VERIFIED 가능 여부 평가 | ALLOW / REQUIRE_CONFIRMATION / BLOCK |
| INT-027-02 | Apply Verified Transition | Enforcer가 VERIFIED 전이 적용 | status overwrite + transition append |
| INT-027-03 | Block on Stale | Atlas stale 시 auto-verify 금지 | REQUIRE_CONFIRMATION or BLOCK |

### 🔒 Stale Handling Rule

- atlasState.stale === true 인 경우 auto VERIFIED는 금지된다.
- 최소 REQUIRE_CONFIRMATION으로 downgrade 하거나
  정책에 따라 BLOCK 처리한다.
- stale 상태에서의 자동 전이는 허용되지 않는다.

## 2. Signal Specification

### 2.1 InterventionRequired (REQUIRE_CONFIRMATION)
- Trigger: completion_policy가 REQUIRE_CONFIRMATION 반환
- Payload: { reason, workItemId, decisionId }
- Behavior: 사용자 승인 전 VERIFIED 전이 금지

### 2.2 BLOCK
- Trigger: completion_policy가 BLOCK 반환
- Payload: { reason, workItemId, decisionId }
- Behavior: 상태 전이 금지, 사용자 조치 필요
