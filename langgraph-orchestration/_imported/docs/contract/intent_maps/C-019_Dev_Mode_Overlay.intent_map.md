# C-019: Dev Mode Overlay Intent Map

## 1. Intent Context (Why & What)

### 1.1 Why Dev Mode Overlay exists
- **개발 환경 최적화**: 터미널이나 서버 조작 없이 UI 상에서 실시간 디버깅 및 설정을 가능하게 하기 위함이다.
- **실시간 관측성**: LLM의 실행 단계와 거버넌스 검수 결과를 즉시 시각화하여 문제 해결 속도를 높인다.

### 1.2 What it must NEVER become
- **Prod 제어기**: 운영 환경의 데이터를 변조하거나 시크릿을 서버에 저장하는 통로로 사용될 수 없다.
- **재현성 파괴자**: Dev 모드에서의 실험 결과가 운영 환경의 재현성(PRD-018)에 영향을 주지 않아야 한다.

---

## 2. Intent Behavior Table

| User Intent | UI Behavior | System Reaction | Ownership |
|:---|:---|:---|:---|
| "임시로 모델을 바꿔보고 싶다" | Dev Override 활성화 | **Isolation LOCK** 발동, Promote/Pin 버튼 비활성화 | **Core (Safety)** |
| "API Key를 설정하고 싶다" | 시크릿 입력창 노출 및 마스킹 입력 | 로컬 전용 저장소(`LocalSecretStore`)에 암호화 저장, `PRD-004` 저장 채널 차단 | **Client (Vault)** |
| "데이터를 관측한다" | Telemetry 수신 | Deep-copy된 데이터만 Snapshot으로 UI에 렌더링 | **Telemetry Layer** |
| "개입이 필요한 지점 확인" | BLOCK 신호 발생 | 스냅샷 기반의 검수 리포트 출력 및 `InterventionRequired` 사유 표시 | **Guardian Layer** |
| "해시가 왜 깨졌는지 확인" | Hash Watcher에서 Diff 버튼 클릭 | Pinned vs Current Plan Hash 구조적 비교 결과 노출 | **Integrity Layer** |

---

## 3. Structural Intent Boundaries

### 3.1 Secret Handling Boundary
- **Memory**: 실행을 위해 서버 메모리에는 존재할 수 있다.
- **Storage**: 서버의 모든 물리적 저장소(파일, DB, 로그)에는 절대 존재할 수 없다.

### 3.2 Reproducibility Isolation Intent
- **Dev Mode**: 실험적이고 비재현적인(Non-reproducible) 상태를 허용한다.
- **Prod Mode**: 엄격하고 결정론적인(Deterministic) 상태만 허용한다.
- **Boundary**: Dev 모드에서 생성된 모든 상태는 운영 환경으로의 "전이(Transition)"를 물리적으로 차단한다.
