# PRD-019: Dev Mode Overlay (Observability & Local Control)

## 1. Objective
개발자가 터미널 환경 변수 설정이나 서버 재시작 없이 웹 UI 상상에서 **Secrets(API Keys) 관리, 실행 텔레메트리 모니터링, 상태 정합성 검토**를 실시간으로 수행할 수 있는 오버레이 인터페이스를 제공한다. 본 기능은 오직 **Dev/RD 모드**에서만 활성화되며, 운영(Prod) 환경의 무결성에는 어떤 영향도 미치지 않아야 한다.

---

## 2. Scope & Priorities

### P0) Secret Handling (Local-only & In-memory)
- **UI Input**: 마스킹 처리된 입력 필드 제공. 현재 활성화된 Provider/Model에 따라 동적 필드 노출.
- **In-memory Use**: 시크릿은 서버의 **영속성 레이어(PRD-004)에 절대 저장될 수 없다.**
- **Isolation**: 런타임 메모리 내 일시적 주입은 허용되나(LLM 호출용), 로그, 세션 파일, BundlePin, Delta, Evidence 등 **어떠한 물리적 저장 경로에도 기록될 수 없다.**
- **Storage**: OS Keychain 또는 로컬 암호화 파일에만 잔류한다.

### P0) Live Telemetry Panel (Isolated Snapshot)
- **Snapshot Mandate**: 텔레메트리 데이터는 반드시 **Deep-Copy된 Snapshot 객체만 전송**한다.
- **Execution Flow**: 현재 실행 Step, Phase, Mode, Plan Hash, Bundle Pin 정보 실시간 표시.
- **Governance Status**: `validators[]` / `postValidators[]` 실행 결과(ALLOW/WARN/BLOCK) 및 `InterventionRequired` 사유 노출.

### P1) Dev Override & Reproducibility Isolation
- **Isolation LOCK**: Dev Override 활성화 시 Bundle Promote, Pin 생성/갱신, 운영 상태 전이(`cycle`/`close`) 기능을 물리적으로 차단한다.
- **Watermark**: Dev Override 상태 세션은 **"NON-REPRODUCIBLE (DEV MODE)"** 워터마크를 강제 표시한다.

---

## 3. Non-Goals
- **Prod Persistence**: 운영 세션 영속성(PRD-004)에 시크릿을 저장하는 행위.
- **Core Semantic Modification**: 오버레이가 실행 엔진의 핵심 로직(Hash 계산 등)을 변경하는 행위.

---

## 4. Acceptance Criteria
- **E2E DX**: 터미널 조작 없이 웹 UI만으로 API Key를 설정하고 첫 채팅을 시작할 수 있음.
- **Real-time Visibility**: Validator Hook 결과와 Plan Hash 변동을 100ms 이내에 오버레이에서 확인할 수 있음.
- **Safety**: Dev 오버레이가 비활성화된 경우, 운영 환경의 성능이나 동작에 영향이 없음.

---

## 5. Risk Assessment
- **Medium**: 로컬 시크릿 저장소의 보안 구현 및 운영 환경과의 물리적 격리(LOCK) 구현이 핵심 리스크임.

---

# 🔒 PRD-019 Hardened Safety Reinforcement Patch

본 패치는 Dev Mode Overlay 구현 시 재현성 붕괴, Core 침투, Secret 유출을 원천 차단하기 위한 강제 명세이다. 모든 항목은 Mandatory이다.

---

## 1. Snapshot JSON Round-Trip LOCK

- Telemetry Snapshot은 반드시 JSON 직렬화 Round-Trip을 통해 생성되어야 한다.
    - JSON.stringify(rawState) → JSON.parse(...)
- structuredClone() 단독 사용은 허용되지 않는다.
- 직렬화 완료 후 반드시 Object.freeze()를 적용한다.
- 순환 참조 발생 시 Snapshot 생성은 실패해야 하며 부분 직렬화는 허용되지 않는다.
- Snapshot에는 다음이 포함될 수 없다:
    - Prototype chain
    - Getter / Setter
    - Function reference
    - Proxy
    - Class instance
- 원본 GraphState 및 ExecutionPlan에 대한 참조는 절대 외부에 노출될 수 없다.

---

## 2. OverrideGuard Fail-Closed LOCK

- Override 상태를 판별할 수 없는 경우 요청은 기본적으로 거절되어야 한다 (Fail-Closed).
- sessionId 누락 또는 유효하지 않은 경우 Promote / Pin / Cycle / Close 요청은 거절된다.
- Guard 판단 실패 시 Default-Allow는 금지된다.
- CLI, API, 자동화 스크립트(state:cycle, prd:close) 모든 경로에 동일 Guard가 적용되어야 한다.

---

## 3. Session-Scoped Override LOCK (Reinforced)

- Dev Override는 반드시 sessionId 단위로 격리된다.
- Global Override 상태는 금지된다.
- 하나의 세션에서 활성화된 Override는 다른 세션에 영향을 줄 수 없다.
- OverrideGuard는 반드시 request.sessionId 기준으로 동작해야 한다.

---

## 4. Secret Zero-Logging Enforcement

- Runtime 레이어에서 raw console.log 사용은 금지된다.
- 모든 로그는 RedactionLogger middleware를 통해 출력되어야 한다.
- HTTP request body 전체 로깅은 금지된다.
- LLM 호출 payload는 secret 필드 제거 후에만 로깅 가능하다.
- 예외 스택 출력 시 process.env 값 덤프는 허용되지 않는다.
- Secret 필드는 telemetry payload, error trace, debug dump에 포함될 수 없다.

---

## 5. Dev Mode Activation Hard LOCK

- Dev Mode는 서버 시작 시 config.is_dev === true 상태에서만 활성화된다.
- 런타임 중 Dev/Prod 모드 전환은 허용되지 않는다.
- 클라이언트 요청만으로 Dev 기능을 활성화할 수 없다.
- NODE_ENV === 'production' 빌드에는 Dev 관련 코드가 포함되어서는 안 된다 (Tree-shaking Mandatory).

---

## 6. Hash Diff Structural Comparison LOCK

- 단순 JSON diff는 허용되지 않는다.
- 비교는 다음 구조 단위로 수행되어야 한다:
    - Step execution order
    - Step type chain
    - Validator / PostValidator sequence
    - Retrieval source signature (Decision/Evidence ID set)
    - Bundle pin hash vs current plan hash
- timestamp, telemetry sequence counter, UI-only metadata는 비교 대상에서 제외된다.

---

## 7. Implementation Safety Checklist (Mandatory)

- [ ] TelemetryEmitter는 JSON round-trip + Object.freeze() 사용
- [ ] OverrideGuard는 API + CLI + state scripts 전 경로에 적용
- [ ] Guard 기본 동작은 Fail-Closed
- [ ] RedactionLogger 전역 적용
- [ ] Dev 코드가 production bundle에 포함되지 않음
- [ ] Secret 필드가 telemetry payload에 존재하지 않음

---

## Implementation Order Checklist

### Stage 1: Infrastructure & Isolation (P0)
- [ ] Deep-copy 기반 `TelemetryEmitter` 구축.
- [ ] **Reproducibility Isolation LOCK** (Promote/Pin 차단 가드) 구현.
- [ ] `LocalSecretStore` (영속성 레이어 차단형) 구현.

### Stage 2: P0 Feature Delivery
- [ ] "NON-REPRODUCIBLE" 워터마크 및 UI 레이아웃.
- [ ] Secret Input UI (Masked, Local-only).
- [ ] 실시간 Snapshot 스트리밍 연동.

### Stage 3: Observability Hardening (P1)
- [ ] Retrieval Metrics (Layer별 카운트) 데이터 수집 및 시각화.
- [ ] Plan Hash Watcher 및 Diff View 구현.
- [ ] Memory "Fuel Gauge" 차트 추가.
