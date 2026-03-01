# B-029 — persist_proposal.contract

## 1. PersistProposal 타입 정의

### 1.1 Payload 구조 분기 (LOCKED)

PersistProposal.payload는 any 타입을 사용할 수 없다.

```ts
type PersistProposal =
  | {
      type: "DECISION"
      payload: DecisionPersistPayload
      evidence: EvidenceRef
      idempotency_key: IdempotencyKey
    }
  | {
      type: "WORK_ITEM_TRANSITION"
      payload: WorkItemTransitionPayload
      evidence: EvidenceRef
      idempotency_key: IdempotencyKey
    }

interface EvidenceRef {
  /**
   * WHY: 최소 1개 이상의 참조가 있어야만 결정의 근거가 성립함
   * minItems: 1 (LOCK)
   */
  conversationTurnRefs: string[]
  reason: string
}
```

- any 타입 사용 금지
- conversationTurnRefs는 최소 1개 이상 필수

## 2. Evidence Gate 규칙
- 모든 `PersistProposal`은 반드시 `evidence.conversationTurnRefs(minItems: 1)`를 포함해야 한다.
- 참조가 누락되거나 유효하지 않은 형식인 경우 `PersistSession` 진입을 차단한다.

- conversationTurnRefs.length < 1 인 경우:
  → PersistSession 진입 전 BLOCK 반환
  → reason: "EVIDENCE_REF_REQUIRED"
- 단일 string 필드 사용 금지
- 배열(minItems:1)로만 허용

## 3. IdempotencyKey 정의
- `IdempotencyKey`는 `(conversationId, turnId, targetRootId)`의 결합으로 구성된다.
- 시스템은 저장소 레벨에서 이 키의 유일성을 보장해야 한다.

## 4. InterventionRequired 확장
- `source: "PLANNER"` 속성을 추가하여 가디언(GUARDIAN) 발생 신호와 구분한다.
- Planner의 개입 요청은 사용자에게 '제안 확인' UI를 트리거한다.

## 5. PersistSession 진입 조건
- 사용자의 명시적 승인(`InterventionResponse.action === 'APPROVE'`)이 확인된 경우에만 실행된다.
- 🔒 **LOCK**: `PersistSession` 이전 단계에서 어떠한 형태의 DB 쓰기 행위도 금지한다.

## 6. 명시적 제약 사항
- **Overwrite 금지**: 기존 `DecisionVersion`을 직접 수정하는 행위는 엄격히 금지된다.
- **PlanHash 영향 금지**: 제안 데이터는 `ExecutionPlan` 해시 계산에서 명시적으로 제외된다.
- **DomainPack 유지**: 영속화 과정에서 도메인 팩을 다시 로드하거나 검증을 우회하지 않는다.
