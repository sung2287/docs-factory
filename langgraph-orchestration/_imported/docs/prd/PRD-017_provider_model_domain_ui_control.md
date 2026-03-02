# PRD-017: Provider / Model / Domain UI Control

## 1. Problem Statement
현재 Web UI는 LLM Provider, Model 및 실행 Domain을 동적으로 제어할 수 있는 수단이 부재합니다. 사용자는 특정 작업을 위해 모델을 변경하거나 도메인 컨텍스트를 지정하고 싶어도 CLI 설정이나 환경 변수에 의존해야 하며, 이러한 변경이 기존 세션의 실행 무결성(Hash)에 미치는 영향을 UI에서 인지하기 어렵습니다.

## 2. Goals
- Web UI에 Provider, Model, Domain 선택기(Selector) 제공.
- 설정 변경 시 기존 세션과의 Hash 불일치를 감지하고 사용자에게 알림.
- 설정 변경 시 "새 세션 시작(New Session)"을 기본 동작으로 유도하여 실행 무결성 유지.
- 서버측 세션 스키마 변경 없이 요청 단위(Request-scoped) 오버라이드 구현.

## 3. Non-Goals (FORBIDDEN)
- `src/core/**` 로직의 수정.
- `session_state.json` 스키마 확장 (Provider/Model/Domain 정보 저장 금지).
- 실행 계획(ExecutionPlan) 해시 구조 자체의 변경.
- Phase와 Domain 간의 암시적 결합(Coupling) 또는 추론(Inference) 로직 추가.
- 서버 세션 상태에 오버라이드 값 영구 저장.

## 4. UX Flow
1. **설정 변경**: 사용자가 UI 상단/설정 패널에서 Provider, Model 또는 Domain을 변경함.
2. **오버라이드 감지**: UI는 현재 선택된 값들이 현재 세션의 초기 생성값(또는 시스템 기본값)과 다른지 비교함.

### Override Baseline Clarification (LOCK)
<!-- PRD-017 Reinforcement Patch -->

The system MUST NOT derive baseline provider/model/domain
from server-side session data.

Override detection in the UI MUST compare:

- Current UI-selected values
- Against the last execution request parameters (client-side memory)

Sessions do NOT store provider/model/domain.
No session-level configuration snapshot exists.

Override state is computed entirely within the UI layer.

### Canonical Domain Resolution (LOCK)
<!-- PRD-017 Reinforcement Patch -->

- `"unset"`은 실행 컨텍스트의 실제 도메인이 아니다.
- `"unset"`은 UI 전용 상태 표현이다.
- Runtime execution payload에는 `"unset"` 문자열이 절대 전달되어서는 안 된다.
- Adapter는 `"unset"` 수신 시 `currentDomain` 필드를 완전히 제거(omit)해야 한다.
- ExecutionPlanHash 계산에도 `"unset"`은 입력으로 포함되지 않는다.
- Domain Default Policy는 `currentDomain`이 존재하지 않을 때만 적용된다.

3. **시각적 힌트**: 값이 다를 경우 "Send" 버튼을 "Send (New Session)"으로 전환하 여 시각적으로 경고함.
4. **세션 로테이션**: 사용자가 전송 클릭 시, UI는 `freshSession: true` 플래그와 함께 오버라이드 값을 서버로 전송함.
5. **결과**: 서버는 요청된 설정으로 새 세션을 생성하고 실행을 개시함.

### No Silent Retry Rule (LOCK)
<!-- PRD-017 Reinforcement Patch -->
UI MUST NOT silently retry the same session after a PLAN_HASH_MISMATCH.
- Automatic retry is forbidden.
- Explicit user action is required to rotate session.
- Hash mismatch must be surfaced as guidance, not auto-corrected.

## 5. Domain Allowlist (Runtime Domains Only)
선택 가능한 도메인은 다음으로 제한됨:
- `global`, `runtime`, `wms`, `coding`, `ui`

### UI Sentinel Value (LOCK)
<!-- PRD-017 Reinforcement Patch -->

- `"unset"`은 Runtime Domain이 아니다.
- `"unset"`은 UI에서 "명시적 도메인 미지정 상태"를 표현하기 위한 Sentinel 값이다.
- `"unset"`은 Runtime Allowlist에 포함되지 않는다.
- Adapter는 `"unset"`을 Runtime execution payload에 포함해서는 안 된다.
- Domain Default Policy는 `currentDomain`이 존재하지 않을 때만 적용된다.

## 6. Guardrails
- **Volatile Overrides**: 모든 오버라이드는 브라우저 메모리 또는 `localStorage`에만 유지되며 서버에는 저장되지 않음.
- **Hash Mismatch Integrity**: 해시 불일치는 오류가 아닌 세션 로테이션의 근거로 활용됨.
- **No Implicit Inference**: 특정 Phase에 진입한다고 해서 도메인이 자동으로 변경되지 않음.

## 7. Governance (LOCK)
<!-- PRD-017 Reinforcement Patch -->
- No implicit Phase → Domain inference is permitted.
- Domain changes MUST always originate from explicit UI selection.
- Runtime MUST NOT derive Domain from Phase or Mode.

## 8. Safe-if-and-only-if
- 사용자가 명시적으로 오버라이드를 선택하고, 시스템이 이를 기반으로 **새 세션**을 시작하는 경우에만 실행 무결성이 보장된 것으로 간주함.
