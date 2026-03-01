# C-029 — persist_proposal.intent_map

## Intent Table

| ID | Intent | Success Criteria | Rejection Conditions | Determinism Note |
|:---|:---|:---|:---|:---|
| INT-029-01 | GeneratePersistProposal | Planner가 유효한 증거와 함께 제안 생성 | 증거(conversationTurnRefs) 누락 또는 빈 배열인 경우 | 결과는 Pin에 의해 재현됨 |
| INT-029-02 | ApprovePersist | 사용 승인 후 PersistSession 성공 | 사용자 거절 또는 권한 부족 | 승인 기록은 이력에 보존 |
| INT-029-03 | IdempotentSkip | 이미 저장된 제안 감지 시 스킵 | 키 불일치 시 | 중복 실행 시 결과 불변 |
| INT-029-04 | EvidenceMissingBlock | 증거 없는 제안에 대해 실행 차단 | 유효한 증거(conversationTurnRefs)가 포함된 경우 | 검증 로직은 항상 동일 결과 |

### Intent 상세 규칙

INT-029-01 GeneratePersistProposal
- Success: conversationTurnRefs.length ≥ 1
- Reject: conversationTurnRefs.length === 0
- Determinism: 동일 입력 조건에서 동일 Proposal 구조 반환

INT-029-04 EvidenceMissingBlock
- Condition: conversationTurnRefs.length === 0
- Outcome: BLOCK
- reason: "EVIDENCE_REF_REQUIRED"
