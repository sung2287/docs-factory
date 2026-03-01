# C-031 — enforce_guardian_rules.intent_map

## Intent Table

| Intent ID | Name | Description | Outcome |
|-----------|------|------------|---------|
| INT-031-A | GuardianPreflight | 실행 전 정책 및 무결성 검증 | 위반 시 BLOCK, 정상 시 ALLOW |
| INT-031-B | GuardianPostStep | 단계 실행 후 결과에 대한 정책 검증 | 위반 시 WARN, 정상 시 ALLOW |
| INT-031-C | InformedBlock | 동일한 BlockKey로 재실행 시도 시 감지 | INFORMED_BLOCK 신호 생성 및 루프 방지 |

### 상세 규칙

#### INT-031-A: GuardianPreflight
- **Success Criteria**: 모든 필수 검증기 통과 (ALLOW).
- **Block Conditions**: `evidence_integrity` 또는 `contract` 위반 시 즉시 차단.
- **Determinism Rule**: 동일 `planHash` 및 입력에 대해 항상 동일한 `status` 반환.
- **Evidence Logging Rule**: BLOCK 시 `GuardianAuditRecordV1(recordType=MIN_PERSIST, status=BLOCK)` 생성 필수. 동시에 `GuardianAuditRecordV1(recordType=BLOCK_KEY)`로 BlockKey를 1회 기록한다. NOTE: recordType=BLOCK_KEY 기록은 최초 1회차 BLOCK에서만 수행하며, 2회차 이상은 중복 기록하지 않는다.

#### INT-031-B: GuardianPostStep
- **Success Criteria**: 단계 실행 결과가 정책 범위 내에 있음.
- **Block Conditions**: 포스트 스텝에서 치명적 위반 감지 시 차단(MVP에서는 WARN 우선).
- **Determinism Rule**: 실행 결과 데이터의 비결정론적 요소 배제 후 검증.
- **Evidence Logging Rule**: WARN 시 `GuardianAuditRecordV1(recordType=WARN, status=WARN)` 기록. GraphState 내 보관은 허용되나, 영속 SSOT는 GuardianAudit이다.

#### INT-031-C: InformedBlock
- **Success Criteria**: 무한 루프 진입 전 `INFORMED_BLOCK`으로 안전하게 중단.
- **Block Conditions**: GuardianAudit에 동일 BlockKey(recordType=BLOCK_KEY)가 존재할 때.
- **Determinism Rule**: GuardianAudit의 `BLOCK_KEY` 레코드가 SSOT.
- **Evidence Logging Rule**: 2회차 이상은 GuardianAudit에 추가 기록하지 않고(중복 방지), INFORMED_BLOCK 신호만 생성한다.
