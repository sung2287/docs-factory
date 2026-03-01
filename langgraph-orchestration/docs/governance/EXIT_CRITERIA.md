# EXIT CRITERIA (Accumulated)

Purpose: PRD 종료 조건(게이트)을 한 파일에 누적한다.
Rule:
- 각 PRD 섹션은 "측정 가능/검증 가능"하게만 쓴다.
- PRD 종료 후 변경 필요 시: 기존 항목 수정/삭제 금지, Patch 섹션에 추가한다.
- 과거 PRD를 사후 작성하는 경우 상단에 RECONSTRUCTED로 표시한다.

---

## PRD-022 — Guardian Enforcement Robot
Status: CLOSED (2026-02-27)
- [x] Hook 삽입 + Step Contract 위반 없음
- [x] 위반 감지 시 InterventionRequired 생성(차단이 아닌 신호)
- [x] Determinism 재현(validator signature / logic_hash)
- [x] Evidence 저장 연동
- [x] 회귀 테스트 통과
- [x] Plan Hash 연동 기록(PlanHash에 findings 포함 금지)

Patch:
- (append-only)

---

## PRD-023 — Retrieval Intelligence Upgrade
Status: CLOSED (2026-02-28)
- [x] 기존 hierarchical retrieval 회귀 없음
- [x] Strategy Port로 교체 가능(Core 수정 없이)
- [x] Semantic/Hybrid 최소 1개 구현 + 수치 근거(precision/latency/recall)
- [x] Loading order 유지(Policy → Structural → Semantic)
- [x] Strategy 선택이 Bundle/Pin에 고정됨

Patch:
- (append-only)

---

## PRD-025 — Decision Capture Layer
Status: CLOSED (2026-02-27)
- [x] DecisionProposal 자동 생성(conversationTurnRef 포함)
- [x] 저장 정책(옵션 B): 제안 → 사용자 YES → Commit
- [x] reason + evidenceRefs gate 강제(없으면 BLOCK)
- [x] 실패 시 InterventionRequired
- [x] Version chain + active 포인터 이동(overwrite 금지)

Patch:
- WorkItem 및 VERIFIED 로직은 PRD-027 범위로 이관됨(2026-02-27)

---

## PRD-026 — Atlas Index Engine
Status: CLOSED (2026-02-27)
- [x] 온보딩 시 Atlas 4대 인덱스 생성(Structure/Contract/Decision/ConflictPoints)
- [x] cycle-end fingerprint 기반 partial update + REVALIDATION_REQUIRED 표시
- [x] Partial Scan Budget Enforcer 작동(max_files/max_bytes 차단)
- [x] 조회 API가 PRD-025/PRD-022에서 사용 가능
- [x] 실행 중 Atlas mutate 금지(테스트로 보장)
- [x] Deterministic Atlas snapshot hash 재현(동일 repo+pin)

Patch:
- (append-only)

---

## PRD-027 — WorkItem Completion & VERIFIED
Status: CLOSED (2026-02-28)
- [x] WorkItem v1 상태머신 구현 + 임의 점프 불가
- [x] completion_policy evaluator 정상 작동(Domain Pack 기반)
- [x] auto_verify_allowed=true 케이스 VERIFIED 자동 판정
- [x] IMPLEMENTED → VERIFIED → CLOSED 전이 강제
- [x] 코딩 도메인 실제 케이스(테스트 evidence + conflict/contract clear) 통과

Patch:
- (append-only)

---

## PRD-028 — Domain Pack Library + Pack Validation
Status: CLOSED (2026-02-28)

- [x] Pack 스키마 검증(필수 필드/allowlist/budget/versioning)
- [x] Pack 교체만으로 도메인 전환(Core 수정 없음)
- [x] Validation 실패 시 로딩 차단
- [x] 최소 2개 Pack 공존 + 격리 확인
- [x] Pack 버전 관리(이전 pin 유지 + 신규 opt-in)

Patch:
- Integer strictness(Number.isInteger) 보강 및 inline ref cleanup 반영 (2026-02-28)

---

## PRD-030 — Guardian YAML Wiring
Status: CLOSED (2026-02-28)
- [x] YAML 주입 검증 (validators/postValidators 루트 레벨 선언 및 해석)
- [x] PlanHash 변경 검증 (validator 구성 변경 시 해시 변경 확인)
- [x] Guardian BLOCK 라이브 확인 (위반 시 실행 차단 정책 집행)
- [x] 회귀 테스트 통과

Patch:
- (append-only)
- NOTE (2026-02-28): "Guardian BLOCK 라이브 확인"은 당시 환경에서 검증 불가였음.
  - 사유: modes.yaml에 validators/postValidators 선언이 없어 Guardian 실행이 트리거되지 않음.
  - 사유: registry의 guardian.* validator들이 allowStub(항상 ALLOW) 상태라 BLOCK 실증이 불가했음.
  - 따라서 PRD-030의 범위는 wiring/schema/hash 계약 완료로 유지하되, 라이브 BLOCK 실증은 PRD-031/032에서 수행한다.
- MIGRATION (2026-02-28): 라이브 BLOCK 실증/로그 확보 요구사항은 PRD-031 Exit Criteria로 승계한다.
- MIGRATION (2026-02-28): Test 3~6 라이브 재검증(데이터 축적 포함)은 PRD-032 Exit Criteria로 승계한다.

---

## PRD-031 — Guardian Rule Set Implementation
Status: CLOSED (2026-02-28)
- [x] 최소 1개 실제 BLOCK validator 구현 완료
- [x] 최소 1개 mode에 validator 선언 존재
- [x] 웹 라이브 BLOCK 실증 로그 확보
- [x] typecheck/test/prd smoke 통과

Patch:
- (append-only)

---

## PRD-032 — Live Validation Harness & Seed Data Stabilization
Status: CLOSED (2026-02-28)
- [x] Seed Run 3회 이상 수행 로그 존재
- [x] Decision/WorkItem/Atlas 데이터 존재 확인
- [x] Test 3~6 라이브 재검증 통과
- [x] 검증 절차 문서화 완료

Patch:
- (append-only)

---

## PRD-029 — Persist Proposal (Ask-to-Commit)
Status: CLOSED (2026-02-28)

- [x] conversationTurnRefs(minItems:1) gate 동작 확인
- [x] 동일 3-tuple 재실행 시 IDEMPOTENT_SKIP 반환
- [x] PersistSession 이전 DB write 호출 0회 보장
- [x] PlanHash 동일성 유지 (Proposal 생성 여부와 무관)
- [x] Planner 단계에서 상태 mutation 없음

Patch:
- (append-only)

---

## PRD-033 — Policy Registration Engine
Status: PLANNED
- [ ] 승인된 Decision으로부터 정책 규칙(Policy Rule) 생성 확인
- [ ] 생성된 정책이 차기 ExecutionPlan 빌드에 정상 반영 확인
- [ ] 정책 승격 과정에서 결정론적 해시(PlanHash) 호환성 유지
- [ ] 정책 규칙과 원천 Decision ID 간의 추적성(Traceability) 확보

Patch:
- (append-only)

---

## PRD-034 — Policy Modification & Conflict Resolution Flow
Status: PLANNED
- [ ] POLICY 위반 발생 시 구조화된 충돌 보고서 생성 확인
- [ ] 사용자 응답(승인/수정)에 따른 신규 DecisionVersion 생성 확인
- [ ] 수정된 정책이 다음 실행 사이클에 즉시 적용 확인
- [ ] 정책 수정 이력에 대한 감사 추적(Audit Trail) 정합성 확인

Patch:
- (append-only)
