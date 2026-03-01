# D-028 — Domain Pack Runtime Mapping
> Integration Points & Workflow Implementation

## 1. Component Mapping & Workflow

### 1.1 `PolicyInterpreter` Validator Insertion Point
- **Location**: `PolicyInterpreter.interpret()` 호출 시, `ExecutionPlan` 객체 생성 직전 `DomainPackValidator`를 실행한다.
- **Role**: 팩 파일 로딩 후 런타임 진입 전 차단막(Gate) 역할.

### 1.2 `RepoScan` Payload Generation
- **Path**: `ExecutionPlan`의 `steps.repo_scan.payload` 필드에 `AtlasDomainPack` 정보를 삽입한다.
- **Rule**: `resolved inline` 주입. Library의 경로 참조가 아닌 데이터 내용 자체를 포함한다.

### 1.3 `resolveAtlasDomainPack` Path
- **Base Directory**: `policy/packs/`
- **Structure**: `<pack-id>/<version>/pack.json`
- **Result**: `AtlasDomainPackV1` 객체 반환.

### 1.4 `AtlasIndexUpdater` Transmission Path
- **Flow**: `run_request` -> `ExecutionPlan.steps.repo_scan` -> `AtlasIndexUpdater`.
- **Note**: `AtlasIndexUpdater`는 `RepoScan` 페이로드에 정의된 `scan_budget` 및 `conflict_points`를 기준으로 인덱싱 범위를 결정한다.

## 2. Hash Integrity Diagram (Textual Representation)

🔒 LOCK-028-HASH-FLOW:
Hash 제외는 “후주입 구조”가 아니라 `normalizeExecutionPlanForHash()` 단계에서 payload를 제외하는 구조임을 명확히 한다.

```text
[Step 1: Raw Pack Load]
    -> Load policy/packs/<pack-id>/<version>/pack.json

[Step 2: Validation]
    -> Apply schema_version default ("v1" if missing)
    -> Fail-fast if invalid (DOMAIN_PACK_VALIDATION_ERROR)

[Step 3: ExecutionPlan Construction]
    -> Generate ExecutionPlan
    -> Resolved inline DomainPack is included in RepoScan payload

[Step 4: Hash Calculation]
    -> computeExecutionPlanHash() 호출
    -> normalizeExecutionPlanForHash()가 step.id + step.type만 추출
    -> Payload(domainPack 포함)는 정규화 단계에서 제외됨
```

[Outcome]
- Hash는 페이로드 내용의 변경에 관계없이 각 step의 식별자와 타입에 의해 결정되는 불변성을 유지한다.
- Inline Payload는 실행 시점에 완결된 데이터 일관성을 보장한다.

## 3. Conflict Analysis with PRD-022~027

- **No Conflicts Identified**:
  - `ExecutionPlan`의 구조 변경이 기존 `Guardian`의 필터링 로직(`PRD-022`)을 방해하지 않음.
  - `WorkItem`(`PRD-027`)의 상태 전이는 팩 데이터 로딩 이후의 구현 단계이므로 영향 없음.
  - `Retrieval Intelligence`(`PRD-023`)는 본 플랫폼 맵핑을 통해 표준화된 팩 데이터를 입력으로 사용하게 됨.
