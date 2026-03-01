# PRD-031 — enforce_guardian_rules

Status: OPEN
Purpose: Guardian Stub 제거 및 실제 BLOCK/WARN 정책 집행 구현

## 1. Objective
- Guardian Stub 제거: `allowStub` 기반의 명목상 검증에서 실질적 정책 집행으로 전환.
- 실제 BLOCK/WARN 정책 집행 구현: 위반 사항 발견 시 핵심 실행 경로 차단 또는 경고 생성.
- 최소 1개 실제 BLOCK validator 동작: `guardian.contract` 또는 `guardian.evidence_integrity` 중 1개 이상 실질 가동.
- Deterministic findings 보장: 동일 입력에 대해 동일한 검증 결과(findings) 산출.

## 2. Scope
- ValidatorRegistry 확장: 정적 등록 방식에서 메니페스트 기반 동적 로딩 및 버전 관리 지원.
- ValidatorManifest 설계: `validatorId`, `version`, `logicHash`를 포함한 스펙 정의.
- minimal persistence 앵커 도입: BLOCK 발생 시에도 최소한의 위반 이력을 기록하기 위한 전용 스토리지 경로.
- GuardianAudit 테이블 도입: BLOCK/WARN/INFORMED_BLOCK 및 minimal persistence 기록을 SSOT(Decisions/WorkItems/PersistSession)와 분리된 감사 전용 저장소에 영속화.
- BlockKey 전략 정의: 중복 차단 신호 및 무한 루프 방지를 위한 식별 키 설계.
- modes.yaml validator 선언 설계: YAML 설정을 통한 검증기 주입 및 순서 SSOT 확립.

## 3. Non-Goals
- override 기능: MVP 단계에서는 사용자나 시스템의 강제 무시(override) 기능을 배제한다.
- Guardian의 GraphState mutation: 가디언은 상태를 직접 수정할 수 없으며 오직 신호만 생성한다.
- PersistSession 내부 분기: 정규 세션 저장 로직 내에 가디언 예외 분기를 섞지 않는다.

## 4. Core Decisions
- BLOCK 시 minimal persistence 앵커 사용: 정규 세션 저장이 차단되더라도 위반 로그는 별도 경로로 보존한다.
- PersistSession은 BLOCK 시 진입 금지: 무결성이 깨진 상태에서의 SSOT 업데이트를 원천 차단한다.
- guardian.evidence_integrity = preflight BLOCK: 근거 정합성 오류는 실행 전 차단한다.
- guardian.contract = preflight BLOCK (MVP): 계약 위반은 실행 전 차단함을 기본으로 한다.
- guardian.strong_decision / guardian.conflict_point = WARN: 지침 위반은 경고를 생성하되 실행은 허용한다.
- BlockKey 및 minimal persistence 기록은 별도 GuardianAudit 테이블에 영속화하며, 이는 커밋(PersistSession)이나 Atlas 갱신이 아니다.

## 5. Authority Boundary
- Guardian은 상태 변경 권한 없음: `GraphState`를 직접 수정하거나 패치를 적용할 수 없다.
- DB write는 GuardianAudit(감사 전용) 테이블에 대한 기록만 허용한다. 정규 SSOT 테이블(decisions, work_items 등) 및 PersistSession 경로로의 쓰기는 금지된다.
- Atlas update 금지: 가디언 실행 결과로 아틀라스 인덱스를 갱신하지 않는다.
- cycle-end mutation 금지: 가디언은 사이클 종료 시점의 어떠한 영속 상태 변경도 트리거할 수 없다.

## 6. Determinism
- 동일 PlanHash + 동일 입력 → 동일 findings: 실행 계획과 입력 데이터가 같으면 가디언 판정은 항상 일관되어야 한다.
- findings는 PlanHash 계산에서 제외: 가디언의 판정 결과가 플랜의 식별자를 변경시켜서는 안 된다.
- validator 선언 순서 = SSOT: YAML에 선언된 순서가 곧 가디언의 실행 순서이며 결정론의 기준이다.

## 7. Infinite Loop Strategy
- BlockKey = (planHash, turnId, validatorId, targetRootId): 차단 신호의 고유성을 식별한다.
- BlockKey는 인메모리가 아니라 GuardianAudit 테이블에 영속 저장된다.
- 동일 BlockKey 2회차 판단은 DB(GuardianAudit) 조회 결과를 SSOT로 사용한다.
- 동일 BlockKey 2회차부터는 INFORMED_BLOCK을 반환하며, 추가 저장은 하지 않는다(중복 기록 방지).
- override 없음 (MVP): 루프 발생 시 수동 개입 없이 중단함을 원칙으로 한다.

## 8. Exit Criteria
- 최소 1개 실제 BLOCK validator 동작 확인.
- minimal persistence 저장 확인 (BLOCK 시 로그 보존).
- INFORMED_BLOCK 동작 확인 (무한 루프 방지 검증).
- Determinism 테스트 통과 (재현성 확보).
