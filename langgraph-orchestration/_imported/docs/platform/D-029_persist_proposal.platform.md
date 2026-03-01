# D-029 — persist_proposal.platform

## 1. Intervention 발생 위치
- Planner의 결정이 완료된 직후, `executePlan` 루프의 각 단계(Step) 종료 시점에 `InterventionRequired`를 체크한다.

## 2. PersistSession 호출 순서
1. `InMemoryRepository` 상태 확인.
2. `Idempotency` 체크 (저장소 조회).
3. `SQLite` 트랜잭션 시작 및 `Decision` 저장.
4. `AtlasIndexUpdater` 트리거 (부수효과).

### 2.1 SSOT Anchor Rule (LOCKED)

- deps.sessionStore.save() 성공 이후에만
  AtlasIndexUpdater 등 부수효과를 실행한다.
- PersistSession 실패 시 Atlas 업데이트는 수행되지 않는다.
- executePlan 루프 내부에서 직접적인 저장/Atlas 갱신은 금지된다.

## 3. Idempotency 체크 타이밍
- `PersistSession` 핸들러 내부에서 실제 저장 로직을 실행하기 직전에 수행한다.
- 동일 (conversationId, turnId, targetRootId) 3-tuple이 이미 존재하는 경우 IDEMPOTENT_SKIP을 반환한다.
- turnId 단독 기준 판별은 금지된다.

## 4. 무결성 보장 (LOCKED)
- **Atlas / PlanHash 영향 없음**: 제안 행위는 인덱스나 플랜 해시를 변경시키지 않는다.
- **Authority Boundary**: Planner는 `InterventionRequired` 신호 발생기 역할로 국한되며, Enforcer가 실제 집행을 담당한다.

## 5. 금지 행위 (Forbidden)
- 🔒 `executePlan` 내부에서 직접적인 Atlas write 또는 SQLite 업데이트 금지.
- 🔒 사용자 승인 없이 이루어지는 모든 형태의 Silent Decision mutation 금지.
- 🔒 `CompletionPolicy`를 우회하여 강제로 `VERIFIED` 상태를 부여하는 행위 금지.
