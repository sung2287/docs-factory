# **PRD-025 — Capture Layer**
> Structured Decision Recording + Reason Validation
> 상태: DRAFT | Phase 7 (PRD-026 후행 조건)

---

## 0. 배경 및 목적

현재 코드베이스는 `changeReason`을 영속 저장하지 않는다. PRD-025는 Capture Layer 경계에서 Decision Commit을 위한 새로운 필수 필드로 구조화된 `reason` 객체를 도입한다.

**이 PRD의 목적:**
- 단순 문자열 사유 대신 구조화된 `reason` 객체를 새롭게 도입하여 결정의 투명성 확보
- Commit 시점의 데이터 무결성 검증 강화 (Reason Schema + Evidence)
- 부적절한 결정 시도에 대한 `BLOCK (InterventionRequired)` 처리 체계 확립

---

## 1. 핵심 원칙 (LOCK)

- **[LOCK-A] Reason Authority:** 구조화된 `reason` 객체만이 결정 사유의 공식 표현 방식이다. (단, Decision의 타당성 SSOT는 Evidence이다.)
- **[LOCK-B] Strict Validation:** Commit Gate는 `reason` 객체의 스키마와 필수 조건을 엄격히 검증한다.
- **[LOCK-C] Blocking over Fail-fast:** 사유 누락 또는 스키마 위반 시 프로세스를 즉시 종료(`FAIL-FAST`)하지 않고, 사용자의 개입을 요구하는 `BLOCK (InterventionRequired)` 상태로 전이한다.
- **[LOCK-D] Minimal Taxonomy:** 지나치게 복잡한 분류 체계보다는 필수적인 정보(Type, Summary) 위주로 구성하여 작성을 방해하지 않는다.

---

## 2. DecisionProposal 구조

### 2.1 DecisionProposal 스키마

결정을 제안하거나 커밋할 때 사용되는 제안 객체는 다음 구조를 갖는다.

```typescript
interface DecisionProposal {
  rootId: string;
  title: string;
  domain: string;
  // changeReason: string; // <-- 완전 제거
  reason: {
    type: "CONSISTENCY" | "RISK" | "SECURITY" | "PERFORMANCE" | "UX" | "MAINTAINABILITY" | "OTHER";
    summary: string;              // 필수, 1~2문장, 1000자 이내
    tradeoff?: string;            // 선택
    evidenceRefs?: string[];      // 선택 (Proposal 수준에서는 선택, Commit 시 검증)
  };
  evidenceRefs: string[];         // 필수 (Section 4.2 참조)
  vaultRefs?: string[];           // 선택 (Section 2.2 참조)
  // ... 기타 필드
}
```

**사유(reason) 필드 설명:**
- **type:** 미리 정의된 Enum 값만 허용한다.
- **summary:** 앞뒤 공백 제거(trim) 후 빈 문자열을 허용하지 않는다.
- **tradeoff:** 이 결정을 내림으로써 발생하는 트레이드오프를 기록한다 (선택).
- **evidenceRefs:** `reason` 내의 `evidenceRefs`는 해당 사유를 뒷받침하는 특정 근거들이며, `DecisionProposal` 루트의 `evidenceRefs`와는 독립적으로 관리될 수 있다.

---

## 2.X Evidence vs Reason — 역할 분리 선언 (LOCK)

Decision은 다음 두 요소로 구성된다:

- **Evidence (근거, SSOT)**
- **Reason (판단 메타데이터)**

### Evidence 정의

- Evidence는 Decision의 **객관적 근거(SSOT)** 이다.
- 재검증 가능해야 하며, artifact pointer / test 결과 / conversation reference 등을 포함한다.
- Evidence가 없으면 Decision은 커밋될 수 없다.
- Commit Gate는 **루트 evidenceRefs** 배열을 기준으로 검증한다.

### Reason 정의

- Reason은 "왜 이 근거를 바탕으로 해당 결정을 선택했는지"를 구조적으로 설명하는 판단 메타데이터이다.
- Reason은 SSOT가 아니며, Evidence를 대체할 수 없다.
- Reason은 재검증 대상이 아니라 **분류 및 감사 가독성 목적**이다.
- Plan Hash에는 Reason의 전체 payload를 포함하지 않는다.

### LOCK — 역할 침범 금지

- Reason은 Evidence의 역할을 대체할 수 없다.
- Evidence는 Reason을 포함하거나 흡수하지 않는다.
- Decision의 타당성 판단은 항상 Evidence를 기준으로 수행한다.
- Reason은 통계/분류/설명 레이어로만 사용된다.

---

## 2.2 🔐 Reserved Extension: Future Vault / PII Isolation Slot

본 PRD는 향후 개인정보(PII) 격리 및 암호화 계층 도입을 고려하여 Decision 구조에 확장 슬롯을 사전 확보한다.

### Extension Field

DecisionProposal / DecisionVersion은 다음 선택 필드를 가질 수 있다:

- **vaultRefs?: string[]** // 외부 Vault 계층을 가리키는 포인터

**운영 원칙:**
- `vaultRefs`는 외부 보관 계층을 참조하는 식별자 목록이다.
- 현재 PRD-025 범위에서는 Vault 구현을 요구하지 않는다.
- `vaultRefs`는 DecisionVersion 레코드에 저장되는 참조 포인터이다.
- 실제 Vault payload는 Decision SSOT가 아니다.
- Decision SSOT는 Vault 외부 데이터를 대체하지 않는다.
- Vault 계층은 DecisionVersion을 확장하지 않으며, 외부 참조 계층으로만 동작한다.
- **Plan Hash(PRD-012A)** 입력에는 vault payload를 포함하지 않는다.
- **Atlas(PRD-026)**는 `vaultRefs`의 "존재 여부"만 인지할 수 있으며, Vault 내부 데이터는 Atlas 인덱스 대상이 아니다.
- Vault 참조의 존재 여부는 Decision의 의미적 타당성을 변경하지 않는다.
- Decision의 SSOT는 항상 Evidence이며, Vault는 이를 대체하지 않는다.

### Non-Goals (현재 범위 아님)
- Vault 저장소 구현 및 암호화 설계
- PII 자동 감지 로직 및 E2EE 도입
- Vault 해시를 PlanHash/AtlasHash에 결합하는 설계

본 슬롯은 향후 PRD-Vault(Security Layer) 도입 시 SQLite 마이그레이션 없이 확장 가능하도록 하기 위한 구조적 예약이다.

---

## 3. Reason Type 정의 (Enum)

| Type | 설명 |
|:--|:--|
| **CONSISTENCY** | 기존 규칙, 스타일, 또는 아키텍처와의 일관성 유지 |
| **RISK** | 잠재적 버그 방지 또는 기술 부채 해소 |
| **SECURITY** | 보안 취약점 수정 또는 보안 가이드라인 준수 |
| **PERFORMANCE** | 실행 속도, 자원 효율성 개선 |
| **UX** | 사용자 경험 또는 인터페이스 일관성 개선 |
| **MAINTAINABILITY** | 코드 가독성, 구조적 명확성 확보 |
| **OTHER** | 위 분류에 속하지 않는 기타 명시적 사유 |

---

## 4. Commit Gate & Enforcer Rules

### 4.1 Commit Gate 운영 정책 (Architectural)

Commit Gate는 실행 계획(Plan Execution)과 영속성 계층(Persistence) 사이의 경계에서 작동한다. Capture Layer의 검증을 통과하지 못한 어떠한 Decision도 영속성 계층에 도달할 수 없다.

### 4.2 Commit 승인 조건

PRD-025는 현재 런타임 저장소 계층이 근거(Evidence)의 존재를 강제한다고 가정하지 않는다. 대신, Capture Layer는 결정 커밋 시점에 연결된 근거가 존재하지 않을 경우 커밋을 차단하는 검증 규칙을 도입한다.

다음 모든 조건이 충족되어야 `DecisionVersion`이 생성된다.
- `reason` 객체가 존재함
- `reason.type`이 허용된 Enum 값 중 하나임
- `reason.summary`가 1자 이상이며 1000자 이하임 (Trim 후 검사)
- 루트의 `evidenceRefs`가 존재하며 빈 배열이 아님 (Commit 시점 검증)

### Evidence Validation Scope Clarification

- Commit Gate는 `DecisionProposal.evidenceRefs` (루트 필드)만을 필수 검증 대상으로 삼는다.
- `reason.evidenceRefs`는 사유별 세부 근거 메타데이터이며, Commit 필수 조건이 아니다.
- 루트 evidenceRefs는 최소 1개 이상어야 한다.

### Evidence Contract Reference

- Evidence 필수 조건의 계약 정의는 B-025를 SSOT로 한다.
- PRD-025는 정책적 설명 문서이며, 필수 검증 조건의 단일 계약 출처는 B-025이다.

### 4.2 Commit 거부 및 Block 조건

다음 중 하나라도 해당할 경우 Commit은 거부되며 **BLOCK (InterventionRequired)** 처리된다.

| 조건 | 사유 |
| :--- | :--- |
| `evidenceRefs` 없거나 빈 배열 | 근거 없는 결정 방지 |
| `reason` 객체 누락 또는 summary 빈 문자열 | 구조화된 변경 근거 없음 |
| `reason.type` Enum 외의 값 | 부적절한 분류 체계 사용 |
| `reason.summary` 길이가 1000자 초과 | 사유 길이 제한 위반 |

**처리 방식:**
- `FAIL-FAST` 아님 (시스템이 다운되거나 전체 상태가 파괴되지 않음)
- **BLOCK (InterventionRequired):** 시스템은 실행을 멈추고 사용자가 해당 정보를 보완하거나 결정을 강제할 때까지 대기한다.
- "의미 불충분(내용이 부실함)"은 구조 위반이 아니므로 승인 보류 사유는 될 수 있으나, 위 스키마 검증 단계에서는 통과될 수 있다.

### Failure Classification Boundary

- Capture Layer 검증 실패는 **BLOCK (InterventionRequired 전이)** 범주에 속한다.
- 시스템 수준의 실행 오류(환경 설정, 저장소 장애 등)는 기존과 같이 **Fail-Fast**로 유지된다.
- BudgetExceededError(PRD-026)는 구조적 FailFast이며, Capture Layer의 BLOCK 정책과 분리된다.
- Budget 초과는 사용자 보완 대상이 아니라 시스템 안전 차단이다.

### Atlas Query / Budget Boundary

- Atlas 인덱스 조회(AtlasQueryAPI)는 `scan_budget`을 소비하지 않는다(PRD-026/C-026).
- 추가 Artifact 스캔이 필요한 경우, LLM은 요청을 제안할 수 있으나 실행/차단은 Budget Enforcer가 수행한다.
- 예산 초과는 `BudgetExceededError`로 **FailFast** 처리되며, 이는 Capture Layer의 `BLOCK(InterventionRequired)` 정책과 분리된다.

---

## 5. Persistence 및 저장 규칙

- **DecisionVersion 저장:** `reason`은 `DecisionVersion` 레코드에 JSON 객체 형태로 영속 저장된다.
- **Metadata Exclusion:** `conversationTurnRef`는 입력 범위의 메타데이터 필드이다. 이는 Decision 영속성 모델의 일부가 아니며, `decisions` 테이블에 저장되지 않는다.
- **Atlas 동기화:** PRD-026에 따라 Atlas는 `reason` 페이로드를 직접 저장하지 않는다.
- **Plan Hash Isolation:** Decision 페이로드 데이터(`reason`, `text`, `vaultRefs` 등)는 런타임 상태이며, Execution Plan Hash 계산에 포함되어서는 안 된다. 이는 사유의 미세한 문구 수정이 실행 계획의 해시를 변경하여 불필요한 재검증을 유발하는 것을 방지하기 위함이다.

- **Atlas 갱신 책임 분리:** PRD-025는 Atlas 인덱스를 직접 갱신(Write)하지 않는다. Atlas Index의 갱신은 PRD-026의 **Cycle-End Sync(PersistSession 성공 직후)** 단계에서만 수행된다. (C-026 AtlasQueryAPI는 Read-Only이며, PRD-025는 이를 위반하지 않는다.)

- **SnapshotHash 즉시성 비보장:** Decision Commit의 성공은 Decision SSOT(DecisionVersion 저장)의 성공만을 의미한다. Atlas Snapshot Hash는 Cycle 종료 시점에 미러링되며, 갱신 실패 시 **Stale 상태가 허용**된다(PRD-026). 따라서 Commit 직후 `getSnapshotHash(bundlePin)`이 최신 상태임을 보장하지 않는다.

---

## 6. Exit Criteria

| # | 종료 조건 | 비고 |
|:--|:--|:--|
| 1 | 구조화된 `reason` 필드 도입 및 DecisionProposal 적용 확인 | |
| 2 | 구조화된 `reason` 객체 스키마 구현 및 적용 | |
| 3 | Commit Gate에서 `reason` 및 `evidenceRefs` 검증 로직 작동 | |
| 4 | 검증 실패 시 `InterventionRequired` 시그널 방출 확인 | |
| 5 | `DecisionVersion` 레코드에 `reason`이 JSON으로 저장됨을 확인 | |

---

## 7. Implementation Evidence (2026-02-27)

- EC-2 (`reason` 스키마 검증): `src/core/plan/plan.handlers.ts` Commit Gate에서 `reason.type`, `reason.summary(1~1000, trim)`, `reason.evidenceRefs` 형식 검증
- EC-3 (`reason` + 루트 `evidenceRefs` 검증): 동일 게이트에서 `decision.evidenceRefs` 최소 1개 강제
- EC-4 (실패 시 InterventionRequired): 검증 실패 시 `errorType: "BLOCK_VALIDATION"` + `violations` + `proposal`를 step result로 기록하고 상태를 `InterventionRequired`로 전이
- EC-5 (`reason` JSON 저장): `runtime/graph/plan_executor_deps.ts` 및 `src/adapter/storage/sqlite/sqlite.stores.ts` 경로로 `reason_json`, `evidence_refs_json`, `vault_refs_json` 저장
- 증거 테스트: `tests/integration/prd_025_capture_layer.test.ts` (T1~T5)

---

*작성일: 2026-02-27 | 상태: DRAFT | PRD-025 UPDATED with Evidence vs Reason Clarity*
