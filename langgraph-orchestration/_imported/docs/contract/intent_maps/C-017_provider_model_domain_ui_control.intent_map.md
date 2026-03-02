# C-017: Provider / Model / Domain UI Control Intent Map

## 1. Overview
사용자의 제어 의도가 UI 행위와 런타임 효과로 어떻게 연결되는지 매핑합니다.

## 2. Intent Mapping

| User Intent | UI Behavior | Runtime Effect | Ownership |
| :--- | :--- | :--- | :--- |
| **모델/제공자 변경** | `selectedModel/Provider` 업데이트 및 오버라이드 상태 활성화 | 없음 (UI 상태만 변경) | UI |
| **도메인 변경** | `selectedDomain` 업데이트 및 오버라이드 상태 활성화 | 없음 (UI 상태만 변경) | UI |
| **변경 후 메시지 전송** | 전송 버튼을 "New Session" 모드로 표시 | `freshSession: true`와 함께 오버라이드 파라미터 송신 | UI |
| **Select "unset" Domain** | Omit currentDomain from payload | Runtime applies Domain Default Policy (global + axis only) | Runtime |
| **오버라이드 전송 수신** | N/A | 오버라이드된 값을 바탕으로 새 세션 생성 및 해시 계산 | Runtime/Adapter |
| **해시 불일치 발생** | 사용자에게 세션 로테이션 필요성 안내 | 기존 세션 보호 및 새 실행 경로 강제 | Runtime/Adapter |

- `"unset"`은 Domain 변경이 아니라 Domain 해제(intent: clear domain)이다.
- Runtime은 이를 "no currentDomain provided"로 해석한다.

## 3. Responsibility Separation
- **UI Responsibility**:
  - 사용자 선택값 유지 (`localStorage` 등).
  - 현재 세션 설정과 선택값 간의 불일치(Mismatch) 시각화.
  - 도메인 허용 리스트(`Allowlist`) 준수.
- **Runtime Responsibility**:
  - 수신된 오버라이드 값을 `run_request`의 컨텍스트로 주입.
  - 오버라이드 값을 해시 계산의 입력으로 사용.
  - 세션 파일에 오버라이드 값이 유출(Persist)되지 않도록 필터링.

## 4. Governance (LOCK)
<!-- PRD-017 Reinforcement Patch -->
- No implicit Phase → Domain inference is permitted.
- Domain changes MUST always originate from explicit UI selection.
- Runtime MUST NOT derive Domain from Phase or Mode.
