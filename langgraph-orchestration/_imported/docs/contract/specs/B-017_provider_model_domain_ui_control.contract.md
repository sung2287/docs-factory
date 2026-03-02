# B-017: Provider / Model / Domain UI Control Contract

## 1. Overview
이 계약서는 Web UI에서 전달하는 모델 및 도메인 제어 파라미터와 서버측 수신 규격을 정의합니다.

## 2. UI State Model (Client-side only)
UI는 다음 상태를 관리하며, 이는 서버 세션에 귀속되지 않는 휘발성 데이터입니다.
- `selectedProvider`: 사용자가 선택한 LLM 제공자 (예: `openai`, `anthropic`).
- `selectedModel`: 사용자가 선택한 모델명 (예: `gpt-4o`, `claude-3-5-sonnet`).
- `selectedDomain`: 허용 리스트에 정의된 실행 도메인.

## 3. Request Payload Extension
`POST /api/chat` (또는 해당 실행 API)의 요청 페이로드는 다음과 같이 확장됩니다.

```typescript
interface ChatRequest {
  message: string;
  sessionId?: string;
  // PRD-017 Overrides
  provider?: string;      // 요청 단위 Provider 오버라이드
  model?: string;         // 요청 단위 Model 오버라이드
  currentDomain?: string; // 실행 컨텍스트 도메인
  freshSession?: boolean; // 변경 발생 시 새 세션 강제 여부
}
```

## 4. Specification Rules
- **Request-scoped**: 위 파라미터들은 해당 HTTP 요청의 생명주기 동안만 유효함.
- **Non-persistence**: 서버는 이 값들을 `session_state.json`에 저장하지 않음.
- **"unset" Handling**:
    - `"unset"`은 네트워크 페이로드에 전달될 수 있으나, 서버는 이를 런타임 실행 payload에 포함하지 않는다.
    - `"unset"`은 persistence 대상이 아니다.
    - `"unset"`은 Allowlist의 실제 실행 도메인으로 간주되지 않는다.
- **Hash Integrity Clause**: `provider`, `model`, `currentDomain`의 변경은 실행 계획 생성 시 입력값으로 포함되므로, 결과적으로 `ExecutionPlanHash`를 변경시켜야 함.
- **No Canonicalization**: UI는 모델명을 정규화하지 않음. 정규화 및 유효성 검증은 서버(Adapter)의 책임임.

### Domain Validation Authority (LOCK)
<!-- PRD-017 Reinforcement Patch -->
Server MUST validate `currentDomain` against the canonical Runtime Domain allowlist (`global`, `runtime`, `wms`, `coding`, `ui`).
- `"unset"` is NOT subject to Allowlist validation as it is a UI Sentinel value.
- UI validation is convenience only.
- Runtime remains final authority.
- Direct REST calls must not bypass domain validation.
- Invalid domain MUST return `400 Bad Request`.

### Unset Domain Semantics (LOCK)
<!-- PRD-017 Reinforcement Patch -->
If `currentDomain` is `"unset"`:
- The field MUST be omitted from the actual runtime execution payload.
- Server may receive `"unset"` via network payload, but MUST NOT include it in Runtime input.
- Runtime Domain Default Policy applies.
- Retrieval loads `global + axis` only.
- No implicit fallback to previous domain is allowed.

## 5. Governance (LOCK)
<!-- PRD-017 Reinforcement Patch -->
- No implicit Phase → Domain inference is permitted.
- Domain changes MUST always originate from explicit UI selection.
- Runtime MUST NOT derive Domain from Phase or Mode.

## 6. Error Codes
- **400 Bad Request**: 허용되지 않은 도메인 값 전달 시.
- **422 Unprocessable Entity**: 지원되지 않는 Provider/Model 조합 요청 시.
