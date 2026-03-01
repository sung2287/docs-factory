# C-028 — Domain Pack Intent Map
> Loading, Validation, and Versioning Intents

## 1. Intent Matrix

| Intent ID | Name | Desired Outcome |
|:---|:---|:---|
| `INT-028-01` | Resolve Pack Reference | Pack ID/version resolved to concrete file path |
| `INT-028-02` | Validate Pack Schema | VALID or DOMAIN_PACK_VALIDATION_ERROR |
| `INT-028-03` | Promote Pack Version | Version Chain 유지 (Library 관리 체계 강화) |
| `INT-028-04` | Materialize & Inject Pack Inline | Fully materialized DomainPack injected into RepoScan payload |

## 2. Success Criteria & Block Conditions

### `INT-028-01`: Resolve Pack Reference
- **Success Criteria**:
  - `policy/packs/<pack-id>/<version>/pack.json` 경로 해석 성공
  - 파일 존재 확인 완료
- **Block Condition**:
  - 파일 미존재(FileNotFound) 시 즉시 `Fail-fast`

### `INT-028-02`: Validate Pack Schema
- **Success Criteria**:
  - `schema_version` default 보정 수행 ("v1" if missing)
  - `B-028` 규격(Optional 필드 규칙 포함) 검증 통과
- **Block Condition**:
  - `DOMAIN_PACK_VALIDATION_ERROR` 발생 시 `PolicyInterpreter`는 즉시 중단 (Fail-fast)

### `INT-028-03`: Promote Pack Version
- **Success Criteria**:
  - 새로운 버전의 팩이 추가되어도 기존 세션은 명시적 업그레이드 전까지 이전 버전 팩 유지
  - Library 내 여러 버전이 독립적인 경로로 존재
  - Promote 행위는 ExecutionPlan 생성 및 런타임 실행 경로와 독립적으로 동작한다.

### `INT-028-04`: Materialize & Inject Pack Inline
- **Success Criteria**:
  - JSON 파싱 완료 및 `DomainPack` 객체 생성
  - `ExecutionPlan`의 `RepoScan` 페이로드에 `resolved inline` 주입 완료
- **Block Condition**:
  - JSON 파싱 실패 또는 객체 생성 오류 시 `Fail-fast`

## 3. Implementation Hints

- `PolicyInterpreter` 단계에서 아래 순서로 프로세스를 수행한다:
  1) **Pack Reference Resolve**: 요청된 ID/버전을 물리적 경로로 매핑.
  2) **Schema Validation**: 로드된 데이터의 스키마 및 제약 조건 검증.
  3) **Materialize & Inline Injection**: 검증된 데이터를 객체화하여 `RepoScan` 페이로드에 주입.
- `RepoScan` payload는 모든 팩 정보를 하나의 객체로 병합하여 포함한다.
- `schema_version` 필드가 없을 경우 런타임은 내부적으로 "v1"로 보정한 뒤 검증 로직을 수행한다.
- `Promote Pack Version`은 Library 관리 계층(Intent)이며, Resolve → Validate → Materialize → Inject 런타임 흐름과 직접적으로 결합되지 않는다.
