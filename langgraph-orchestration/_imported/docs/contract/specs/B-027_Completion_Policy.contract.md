# B-027 — Completion Policy Contract
> CompletionPolicyV1 Input/Output + 권한 경계

## 1. Objective
WorkItem이 VERIFIED로 전이 가능한지 “평가”하는 정책 인터페이스를 Domain Pack으로 외부화한다.

## 2. Inputs (CompletionPolicyInputV1)

completion_policy는 다음 입력만 사용할 수 있다:

{
  workItem,
  decision,                 // DecisionVersion
  guardianFindings,         // ValidatorFinding[]
  atlasState: {
    stale: boolean,         // adapter를 통해 조회된 값
    conflictClear: boolean,
    contractClear: boolean
  },
  evidence                  // EvidenceRecord[]
}

LOCK:
- completion_policy는 Decision/WorkItem/Atlas를 직접 수정할 수 없다.
- completion_policy는 Retrieval을 강제 호출할 수 없다.
- 시간(Date.now) / 랜덤 사용 금지.

### 🔒 Authority Boundary

CompletionPolicy는 평가자(Evaluator)이다.

금지 사항:
- DecisionVersion 직접 수정
- WorkItem.status 직접 변경
- Atlas 인덱스 수정
- Retrieval 강제 실행
- 외부 I/O 호출
- Date.now / Math.random 등 비결정론 요소 사용

CompletionPolicy는 상태 전이를 직접 수행할 수 없다.
상태 전이는 반드시 Enforcer 계층에서 수행된다.

### 🔒 VERIFIED Enforcement Separation

- ALLOW 반환은 "전이 가능" 의미일 뿐,
  VERIFIED 전이는 Enforcer가 수행한다.
- REQUIRE_CONFIRMATION은 사용자 승인 없이는 전이 불가.
- BLOCK은 전이 금지.

## 3. Outputs (CompletionPolicyResultV1)

반환값은 다음으로 제한된다:

{
  status: "ALLOW" | "REQUIRE_CONFIRMATION" | "BLOCK",
  reason: string
}

LOCK:
- VERIFIED 전이는 정책이 아니라 Enforcer가 수행한다.
- Atlas가 stale=true이면 자동 VERIFIED(ALLOW→auto verify) 금지:
  - 최소 REQUIRE_CONFIRMATION으로 downgrade 하거나 BLOCK.

## 4. Domain Pack Externalization (LOCK)
- completion_policy는 Domain Pack에 정의된다.
- Bundle/Pin 교체 없이는 정책이 바뀌지 않는다.
