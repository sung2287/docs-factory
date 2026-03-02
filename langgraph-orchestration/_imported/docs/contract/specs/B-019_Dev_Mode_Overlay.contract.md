# B-019: Dev Mode Overlay Contract

## 1. Secret Handling Contract
- **Purpose**: API Key 등 민감 정보를 안전하고 지역적으로만 관리한다.
- **Invariant**: 시크릿은 영속성 레이어(PRD-004)에 저장될 수 없다.
- **Allowed**: LLM 실행을 위한 런타임 메모리 내 일시적 보유.
- **Forbidden**: 로그 출력, 세션 파일 기록, BundlePin/Delta/Evidence 데이터 포함.
- **Failure Mode**: 저장 시도 감지 시 즉시 세션 Abort 및 데이터 소거.

## 2. Telemetry Isolation Contract
- **Purpose**: 런타임 내부 상태를 읽기 전용(Read-only)으로 외부 노출한다.
- **Invariant**: 텔레메트리 데이터 스트림은 실행 엔진의 상태를 변경할 수 없다.
- **Mandate**: 반드시 **Deep-copy Snapshot**만 전송하며, 원본 GraphState/ExecutionPlan에 대한 참조를 외부에 노출해서는 안 된다.

### 2.1 Snapshot Structural Sanitization LOCK

- Snapshot은 반드시 Plain JSON 객체로 직렬화되어야 한다.
- Prototype chain, Getter, Setter, Function reference, Proxy는 포함될 수 없다.
- Class instance는 JSON-safe object로 변환되어야 한다.
- Snapshot 객체는 전송 전 Object.freeze() 처리되어야 한다.
- 원본 GraphState, ExecutionPlan에 대한 참조는 절대 노출되어서는 안 된다.

## 3. Reproducibility Isolation LOCK
- **Purpose**: Dev 기능을 Prod 환경으로부터 물리적으로 격리한다.
- **Invariant**: Dev Override 상태에서는 다음 기능이 비활성화된다.
    - **Bundle Promote** 기능 비활성화 (PRD-018 보호)
    - **Bundle Pin** 생성 및 갱신 금지 (재현성 붕괴 방지)
    - **`state:cycle`**, **`prd:close`** 경로 차단 (운영 상태 전이 방지)
- **UI Mandate**: 오버레이 활성 시 "NON-REPRODUCIBLE (DEV MODE)" 경고를 모든 화면에 오버레이한다.
- **Failure Mode**: LOCK 상태에서 해당 명령 수신 시 `ActionNotAllowedError` 발생.

### 3.1 Session-Scoped Override LOCK

- Dev Override 상태는 반드시 `sessionId` 단위로 격리되어야 한다.
- Global Override 상태는 허용되지 않는다.
- 하나의 세션에서 활성화된 Override는 다른 세션의 Promote/Pin/Cycle 경로에 영향을 줄 수 없다.
- OverrideGuard는 모든 요청에서 `request.sessionId` 기반으로 판단해야 한다.

## 4. Secret Zero-Logging LOCK
- **Purpose**: 로깅 및 디버깅 과정에서의 의도치 않은 시크릿 유출을 원천 차단한다.
- **Invariant**: `console.log`, `error stack`, `telemetry payload`, `HTTP request body`, `exception trace` 등 모든 로깅 및 전송 경로에서 시크릿 필드 마스킹(Masking)을 강제한다.
- **Mandate**: 로그 시스템은 기본적으로 "Redaction Filter"를 적용하여 민감 정보를 자동으로 필터링해야 한다.

## 5. Mode Isolation Contract
- **Purpose**: Dev 기능을 Prod 환경으로부터 물리적으로 격리한다.
- **Invariant**: Dev Mode 및 오버레이 엔드포인트는 오직 **서버 설정(`config.is_dev === true`)**에서만 활성화된다.
- **Verification**: UI 토글 기능은 서버가 Dev 모드임을 명시적으로 검증한 경우에만 작동하며, 클라이언트 단독 결정은 허용되지 않는다.
- **Forbidden**: Prod 빌드 환경(`NODE_ENV === 'production'`)에서의 Dev UI 컴포넌트 포함 (Tree-shaking 필수).
