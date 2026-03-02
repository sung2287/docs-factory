# **B-018: Bundle Promotion & Governance Contract**

## 1. 개요
Workflow Bundle의 생명주기 및 런타임 승격(Promotion) 과정에서의 무결성 검증 규칙을 정의한다.

## 2. 해시 규칙 (Integrity Rule)
* **[LOCK-17] Sorted Map Hash Rule:** 번들의 무결성 지표인 `bundle_hash`는 다음 절차로만 계산되어야 한다.
    1. 번들에 포함된 각 파일의 raw bytes에 대해 SHA-256 계산.
    2. 파일의 상대 경로(`path`) 기준 오름차순(ASC) 정렬. (`manifest.json` 내 `files[].path` 값을 가공 없이 사용)
    3. 정렬된 각 항목을 `"<path>:<fileHash>\n"` 형식(ASCII, LF 사용)으로 연결.
    4. 연결된 전체 문자열에 대해 최종 SHA-256 계산.
* `manifest.json`의 `bundle_hash`는 위 결과와 반드시 일치해야 하며, 불일치 시 런타임 로딩을 거부한다.

## 3. 승격 및 세션 고정 (Promotion & Pinning)
* **Promotion의 구분:**
    * **Store Promotion:** Bundle 디렉토리를 `promoted` 상태로 확정하는 관리/배포 파이프라인 작업.
    * **Session Re-pin:** `--promote-bundle` 플래그를 통해 기존 세션의 Pin 파일을 현재 Active 번들 정보로 갱신하는 실행 정책 작업.
* **No Auto-Overwrite:** `Pinned != Active` 인 경우 기본 정책은 즉시 Abort이며, 명시적 플래그 없이는 어떠한 자동 갱신이나 승격도 금지된다.
* **Session Evolution Clarification:** `bundle_hash`는 불변 리소스 집합에 대한 **참조 무결성 지표**이며, PRD-004의 Execution Plan 직렬화 해시와는 개념적으로 분리된다.

## 4. 거버넌스 정책
* **[LOCK-18] Strict Fail-Fast Bundle Policy:** 번들 무결성 실패(Drift) 또는 정책 불일치 발생 시 어떠한 자동 복구나 우회 흐름도 허용하지 않는다.
