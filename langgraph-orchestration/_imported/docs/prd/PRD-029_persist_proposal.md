# PRD-029 — persist_proposal

Status: OPEN
Purpose: Planner의 제안을 사용자 확정 후 영속화하는 Option B(Ask-to-Commit) 흐름 정의

## 1. Objective
- Option B (Ask-to-Commit) 모델 고정: Planner는 제안(Proposal)만 생성하고, 실행 권한은 Enforcer에게 위임한다.
- Enforcer가 사용자의 승인을 확인한 후 `PersistSession`을 호출하여 최종 상태를 확정한다.

## 2. Scope
- **Ask-to-Commit 흐름**: Planner의 제안이 `InterventionRequired` 신호로 변환되어 사용자에게 전달되는 과정.
- **Idempotent Persist**: 동일한 작업의 중복 영속화 방지 로직.
- **Evidence Gate**: `conversationTurnRef`를 필수 증거로 요구하는 검증 레이어.

## 3. Non-Goals
- 자동 커밋(Auto-commit) 또는 배경 영속화(Silent mutation).
- 제안 생성 행위로 인한 `PlanHash` 변경.
- Atlas 인덱스 업데이트 트리거의 임의 변경.

## 4. High-Level Flow
1. **Planner**: 실행 결과에 기반하여 `PersistProposal` 생성.
2. **Core**: 제안을 감지하고 `InterventionRequired(source="PLANNER")` 상태로 전환.
3. **User**: 제안된 내용을 검토하고 `Approve` (YES) 수행.
4. **Enforcer**: `PersistSession` 핸들러 호출.
5. **Storage**: `DecisionVersion` 생성 (Idempotent 체크 통과 시).

## 5. Idempotency Model
- **3-tuple Key**: `(conversationId, turnId, targetRootId)`를 고유 식별자로 사용한다.
- **Overwrite 금지**: 이미 존재하는 키에 대해 수정을 시도할 경우 작업을 중단한다.
- **IDEMPOTENT_SKIP**: 동일 키 발견 시 에러가 아닌 '이미 처리됨' 상태로 정상 종료한다.

## 6. Determinism Guarantees
- `turnId`는 일시적인 순번이므로 `PlanHash` 계산 입력에서 제외한다.
- `auto-capture` 설정 여부 등 영속화 정책은 `PlanHash` 식별자에 영향을 주지 않는다.
- 동일 Plan + 동일 Pin + 동일 입력 상태에서는 PersistProposal 생성 결과가 동일해야 하며,
이는 테스트로 검증 가능해야 한다.

### 6.1 turnId Source of Truth (LOCKED)

- turnId는 세션 상태(SSOT)에 포함되는 런타임 부여 식별자이다.
- 동일 세션 재실행 시 동일 turnId가 재사용되어야 한다.
- turnId는 PlanHash 및 snapshotId 계산 입력에 포함되지 않는다.
- turnId 생성/증가는 Deterministic Context 내에서만 수행한다.

## 7. Authority Boundary
- **Planner**: 상태를 변경할 권한이 없으며, 오직 `InterventionRequired` 신호만 발생시킬 수 있다.
- **Enforcer**: 유일하게 `PersistSession`을 통해 SSOT(SQLite/Atlas)를 업데이트할 권한을 가진다.
- **Guardian**: 가디언의 차단 신호와 플래너의 제안 신호는 엄격히 구분하여 처리한다.

## 8. Failure Classification
- **Evidence 부족**: `conversationTurnRef`가 없는 제안은 `BLOCK` 처리한다.
- **Idempotent skip**: 중복 요청은 시스템적으로 '성공'으로 간주한다 (정상 흐름).
- **DB 충돌**: 트랜잭션 오류나 무결성 위반 시 `FailFast`로 분류하여 즉시 중단한다.
