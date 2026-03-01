# **✅ Exit Criteria — PRD-026 ~ PRD-028**

> MVP 기준. 과장 없음. 확장 조건 제외.
> 각 PRD는 아래 조건을 **전부** 통과해야 닫힌다.

---

## 🔵 PRD-026 — Atlas Index Engine
> **역할**: 엔진 기반. PRD-025/022/023의 공통 기반 레이어.

| # | 종료 조건 | 비고 |
|:--|:--|:--|
| 1 | 레포 최초 온보딩 시 Atlas 4대 인덱스 정상 생성 | Structure / Contract / DecisionIndex / ConflictPoints |
| 2 | Cycle 종료 시 fingerprint 기반 Index Update 정상 작동 | 변경된 Artifact만 REVALIDATION_REQUIRED 표시 |
| 3 | Partial Scan Budget Enforcer 작동 | Domain Pack max_files / max_bytes 초과 요청 차단 확인 |
| 4 | Atlas 조회 API가 PRD-025 / PRD-022에서 사용 가능 | 공통 조회 인터페이스 확인 |
| 5 | 실행 중 Atlas mutate 금지 규칙이 테스트로 보장됨 | Cycle 종료 시점 외 수정 불가 |
| 6 | Atlas 조회 결과 결정론적 재현 가능 확인 | 동일 레포 + 동일 Pin에서 동일 Index 해시 생성, Atlas snapshot hash 비교 테스트 통과 |

**→ 6개 통과 시 PRD-026 CLOSED**

> **Status: CLOSED (2026-02-27)**  
> All 6 criteria verified via runtime tests and deterministic hash checks.

---

## 🔵 PRD-025 — Decision Capture Layer
> **역할**: 대화 → Decision 자동화.
> ⚠️ WorkItem, completion_policy, VERIFIED 판정은 PRD-027 범위이다.

| # | 종료 조건 | 비고 |
|:--|:--|:--|
| 1 | DecisionProposal 자동 생성 확인 | conversationTurnRef 포함 필수 |
| 2 | 옵션 B 저장 정책 정상 작동 | 저장 제안 → 사용자 YES → Committed 전환 |
| 3 | reason + 루트 evidenceRefs 검증 Gate 작동 | Enforcer 강제 규칙 확인 |
| 4 | 검증 실패 시 InterventionRequired 발생 | BLOCK 정책 확인 |
| 5 | DecisionVersion 새 버전 생성 + active 포인터 이동 확인 | overwrite 금지 |

**→ 5개 통과 시 PRD-025 CLOSED**

> **Status: CLOSED (2026-02-27)**  
> WorkItem 및 VERIFIED 로직은 PRD-027 범위로 이관됨.

---

## 🔵 PRD-022 — Guardian Enforcement Robot
> **역할**: 안전장치. 실행 검수 + 개입 신호 생성.
> ⚠️ BLOCK은 실행 차단이 아닌 InterventionRequired 신호만.

| # | 종료 조건 | 비고 |
|:--|:--|:--|
| 1 | Execution Hook으로 Guardian 정상 삽입 확인 | Hook 계약 준수 |
| 2 | 위반 감지 시 InterventionRequired 생성 확인 | StepResult mutation 없음 |
| 3 | 동일 입력에서 Guardian 결과 결정론적 재현 가능 | validator signature / logic_hash 포함 |
| 4 | Guardian 리포트 Evidence 저장 연동 확인 | 근거/라인/권고/차단여부 포맷 |
| 5 | 기존 PRD-001~021 회귀 테스트 통과 | 기존 실행 경로 무손상 |
| 6 | Guardian 결과가 Plan Hash와 함께 기록되고 재현 가능 확인 | PRD-012A Deterministic Hash 연동 — validator signature / logic_hash 포함 재현 테스트 통과 |

**→ 6개 통과 시 PRD-022 CLOSED**

---

## 🔵 PRD-023 — Retrieval Intelligence Upgrade
> **역할**: 성능 레이어. 026/025/022 완료 후 진행.
> ⚠️ 데이터(Decision/Evidence/Conflict)가 충분히 쌓인 뒤 효과 측정 가능.

| # | 종료 조건 | 비고 |
|:--|:--|:--|
| 1 | 기존 Hierarchical Retrieval 유지 보장 | 기존 동작 회귀 없음 |
| 2 | Strategy Port 통해 전략 교체 가능 확인 | Core 수정 없이 교체 |
| 3 | Semantic / Hybrid 전략 최소 1개 구현 | Precision@k ≥ baseline(기존 SQL) / Retrieval latency budget 유지 / Recall regression 없음 — 수치 기반 근거 제시 필수 |
| 4 | Memory Loading Order 유지 확인 | Policy → Structural → Semantic 순서 불변 |
| 5 | Strategy 선택이 Bundle / Pin에 고정됨 | PRD-018 무결성 유지 |

**→ 5개 통과 시 PRD-023 CLOSED**

---

## 🔵 PRD-027 — WorkItem Completion & VERIFIED 판정
> **역할**: WorkItem v1 실체(테이블 + 상태머신), completion_policy evaluator, VERIFIED 전이 로직.
> ⚠️ 코딩 번들 온보딩 후 실사용 데이터가 쌓인 시점에 시작. PRD-025 완료 후 진행.

| # | 종료 조건 | 비고 |
|:--|:--|:--|
| 1 | WorkItem v1 엔티티 및 상태머신 구현 확인 | PROPOSED → ANALYZING → DESIGN_CONFIRMED → IMPLEMENTING → IMPLEMENTED → VERIFIED → CLOSED |
| 2 | completion_policy 평가기 정상 작동 | Domain Pack 기반 완료 조건 평가 |
| 3 | VERIFIED 자동 판정 작동 확인 | auto_verify_allowed=true 케이스 |
| 4 | WorkItem IMPLEMENTED → VERIFIED → CLOSED 전이 강제 확인 | 임의 점프 불가 |
| 5 | 코딩 도메인 completion_policy 기준 실제 케이스 통과 | 테스트 Evidence + Conflict 클리어 + Contract Lock 위반 없음 |

**→ 5개 통과 시 PRD-027 CLOSED**
> 타이밍: 코딩 번들 온보딩 후 VERIFIED 흐름이 실제로 필요하다고 느끼는 시점에 시작.

---

## 🟡 PRD-028 — Domain Pack Library + Pack Validation
> **역할**: 두 번째 도메인 진입 시 Domain Pack을 체계적으로 관리하는 라이브러리 + 검증 체계.
> ⚠️ 코딩 번들 이후 두 번째 도메인이 생기는 시점에 시작. 지금은 슬롯 예약만.

| # | 종료 조건 | 비고 |
|:--|:--|:--|
| 1 | Domain Pack 스키마 검증 통과 | 필수 필드 / allowlist / budget / versioning 확인 |
| 2 | Pack 추가 시 Core 수정 없이 교체 가능 확인 | 설정 파일 교체만으로 도메인 전환 |
| 3 | Pack Validation 실패 시 로딩 차단 확인 | 잘못된 Pack이 런타임에 올라가지 않음 |
| 4 | 최소 2개 도메인 Pack 공존 + 격리 확인 | 코딩 + 1개 추가 도메인 |
| 5 | Pack 버전 관리 작동 확인 | 이전 버전 Pin 유지 + 신규 버전 Opt-in |

**→ 5개 통과 시 PRD-028 CLOSED**
> 타이밍: 코딩 번들 검증 완료 후 두 번째 도메인 진입 시점.

---

## 🔥 전체 엔진 최소 완료 기준

시스템이 **"AI 코딩 병목 제거 엔진"으로 실제 작동한다**고 말하려면:

| 조건 | 상태 |
|:--|:--|
| PRD-026 CLOSED | Atlas 기반 완성 |
| PRD-025 CLOSED (DESIGN_CONFIRMED까지) | 대화→결정 자동화 완성 |
| PRD-022 CLOSED | 안전장치 완성 |

**→ 이 세 개가 완료되면 코딩 번들 온보딩 시작 가능.**
PRD-023은 그 이후 성능 개선 단계.
PRD-027은 코딩 번들 실사용 후 VERIFIED 흐름 필요 시점에 시작.
PRD-028은 두 번째 도메인 진입 시점에 시작.

---

## 📅 추천 스프린트 (혼자 작업 기준)

| Week | PRD | 핵심 목표 |
|:--|:--|:--|
| Week 1 | PRD-026 | Atlas 4대 인덱스 + Budget Enforcer + 조회 API |
| Week 2 | PRD-025 | Capture Layer MVP + WorkItem DESIGN_CONFIRMED까지 |
| Week 3 | PRD-022 | Guardian Hook + InterventionRequired + 회귀 테스트 |
| Week 4 | 버퍼 + 검증 | 실제 레포 Atlas 온보딩 → 병목 해소 직접 검증 |
| Week 5+ | PRD-023 | 데이터 쌓인 뒤 Retrieval 고도화 |
| 코딩 번들 안정화 후 | PRD-027 | VERIFIED 판정 + completion_policy 전체 구현 |
| 2번째 도메인 진입 시 | PRD-028 | Domain Pack Library + Validation 체계 |

> ⚠️ Week 1 Day 5에 Exit Criteria 5개를 냉정하게 체크.
> 미통과 시 Week 2로 넘어가지 않는다.

---

*작성일: 2026-02-27 | PRD-025/026 CLOSED 반영*
