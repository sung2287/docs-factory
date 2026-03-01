# B-031 — enforce_guardian_rules.contract

## 1. ValidatorManifestV1
가디언 검증기의 명세와 무결성을 정의한다.
```typescript
interface ValidatorManifestV1 {
  validatorId: string;
  version: string;
  logicHash: string; // 검증 로직의 무결성을 보장하는 해시
}
```

## 2. ValidatorFindingV1
가디언 실행 결과로 생성되는 판정 데이터 구조이다.
```typescript
interface ValidatorFindingV1 {
  validatorId: string;
  validatorVersion: string; // 필수 (누락 시 Fail-fast)
  logicHash: string;        // 필수 (누락 시 Fail-fast)
  status: "BLOCK" | "WARN" | "ALLOW";
  reason: string;
  turnId: string;
  planHash: string;
}
```

## 3. MinimalPersistenceRecordV1
BLOCK 발생 시 위반 이력을 보존하기 위한 최소 저장 구조이다.
```typescript
interface MinimalPersistenceRecordV1 {
  planHash: string;
  turnId: string;
  validatorId: string;
  validatorVersion: string;
  targetRootId: string;
  findings: ValidatorFindingV1[];
  createdAt: string;
}
```
- `validatorId/validatorVersion/logicHash/targetRootId` 정합성이 BlockKey 판단과 1:1로 대응해야 한다.

## 4. BlockKeyDefinition
중복 차단 및 무한 루프 방지를 위한 식별 키 구조이다.
```typescript
interface BlockKeyDefinition {
  planHash: string;
  turnId: string;
  validatorId: string;
  targetRootId: string;
}
```
- BlockKey는 GuardianAuditRecordV1(recordType=BLOCK_KEY)로 영속 저장되며, 인메모리 레지스트리는 허용되지 않는다.

## 5. GuardianAuditRecordV1
감사 및 조회를 위한 전용 영속화 구조이다.
```typescript
interface GuardianAuditRecordV1 {
  recordType: "MIN_PERSIST" | "BLOCK_KEY" | "WARN" | "INFORMED_BLOCK";
  planHash: string;
  turnId: string;
  validatorId: string;
  validatorVersion: string;
  logicHash: string;
  targetRootId: string;
  status: "BLOCK" | "WARN" | "ALLOW" | "INFORMED_BLOCK";
  reason: string;
  findings?: ValidatorFindingV1[];   // recordType이 MIN_PERSIST일 때 필수
  createdAt: string;
}
```

## 명시적 규칙
- findings는 PlanHash 입력에 포함되지 않는다.
- logicHash는 필수이며, 누락 시 실행을 거부한다.
- version 불일치 시 런타임 초기화 실패(Fail-fast)를 원칙으로 한다.
- GuardianAuditRecordV1은 감사/조회 전용이며 PersistSession 커밋이 아니다.
- `recordType=BLOCK_KEY`는 '1회차 BLOCK 감지됨'을 표시하는 고유 레코드이며, 2회차 이상은 INFORMED_BLOCK으로 처리한다.
- 동일 BlockKey의 정의는 아래 4-tuple SSOT로 고정: `(planHash, turnId, validatorId, targetRootId)`
- INFORMED_BLOCK 판단은 GuardianAudit 조회 결과를 SSOT로 사용한다.
- GuardianAudit 기록은 Atlas update 및 cycle-end mutation을 트리거하지 않는다.
