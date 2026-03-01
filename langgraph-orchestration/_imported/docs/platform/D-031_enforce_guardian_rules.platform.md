# D-031 — enforce_guardian_rules.platform

## 1. Execution Boundary
- Guardian은 `PlanExecutor` 내부의 `executePlan` 루프에서만 실행된다.
- **GraphState mutation 금지**: 가디언 로직은 상태 객체를 직접 수정할 수 없다.
- **applyPatch 생성 금지**: 가디언은 상태 변경을 위한 패치를 생성하여 반환할 수 없다.

## 2. Persistence Boundary
- **BLOCK 시 PersistSession 호출 금지**: 가디언 판정이 BLOCK인 경우, 정규 세션 저장소(`decisions`, `work_items`)에 대한 접근이 차단된다.
- **GuardianAudit 테이블 도입**: GuardianAudit 테이블은 PersistSession/SSOT와 분리된 감사 전용 저장소이며, BLOCK/WARN/INFORMED_BLOCK 및 minimal persistence 기록은 이 경로로만 영속화된다.
- **BlockKey 레지스트리**: BlockKey 레지스트리는 인메모리로 구현할 수 없으며, GuardianAudit의 `BLOCK_KEY` 레코드가 SSOT다.
- **Atlas update 금지**: 가디언 실행 과정이나 결과로 아틀라스 인덱스(Atlas Index)를 물리적으로 수정하지 않는다.

## 3. Hash Boundary
- **validator 선언 순서 변경 = PlanHash 변경**: YAML 내 가디언 선언 순서가 바뀌면 플랜의 고유 해시도 변경된다.
- **findings는 Hash 입력 제외**: 가디언의 실행 결과 데이터는 `PlanHash` 계산에 포함하지 않아 해시 안정성을 유지한다.
- **logicHash 변경 시 version bump 필수**: 가디언 로직의 무결성 해시가 변경되면 반드시 버전을 올려 호환성을 관리해야 한다.

## 4. Runtime Failure Policy
- **version mismatch → 초기화 실패**: 시스템 구동 시 정의된 버전과 실제 로딩된 버전이 다르면 구동을 중단한다.
- **logicHash 누락 → Fail-fast**: 가디언 선언에 무결성 해시가 없으면 런타임 에러를 발생시켜 안전을 확보한다.
- **GuardianAudit 기록 실패**: GuardianAudit 기록 실패는 Fail-fast로 분류한다(차단 이벤트의 소실 방지).
