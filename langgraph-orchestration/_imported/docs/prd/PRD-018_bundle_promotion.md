# **PRD-018: Bundle Promotion Pipeline & Runtime Governance**

## **1\. 문서 목적 (Objective)**

본 문서는 LangGraph 기반의 R\&D 환경(Builder)과 서비스 환경(Runtime)을 물리적으로 분리하고, 코드 수정 없이 파이프라인(프롬프트, 정책, 루브릭)을 배포(Promote)하기 위한 '메타 팩토리'의 핵심 연결 엔진을 정의한다.

* **용어 충돌 해결 (Terminology Lock):** 기존 policy/bundles.yaml에서 쓰이는 'bundle'과 본 PRD의 개념은 분리된다. 본 문서의 배포 단위는 \*\*'Workflow Bundle'\*\*로 명명한다.

## **2\. 핵심 원칙 및 제약 사항 (Core Principles & LOCKs)**

### **2.1 분리 및 강제 원칙**

* **\[LOCK-1\] 승격 대상의 엄격한 분리 (SSOT Separation):** 유저 데이터(Decision/Evidence)와 설정 데이터(Bundle)를 물리적으로 격리한다.  
* **\[LOCK-4\] Core-enforced Fallback 강제:** Prod 모드에서 판사 AI(Judge) 실패 시 처리 규칙은 번들이 아닌 Runtime Core에 하드코딩된 계약을 따른다.  
* **\[LOCK-7\] Strict I/O Boundary (Core 무 I/O 유지):** src/core 내부에는 절대 파일 시스템 I/O 로직을 추가하지 않으며, 외부 Adapter(BundleResolver)에서 주입한다.

### **2.2 버전 및 해시 무결성**

* **\[LOCK-6\] Hash-Coupled Bundle Version:** ExecutionContextMetadata에 bundleId, bundleVersion, bundleHash 필드를 포함하여 해시 입력에 사용한다. Pinned 번들 위변조 시 즉시 실행을 중단한다.  
* **[LOCK-11] Deterministic Bundle Hashing Principle:**
  - Bundle hash는 결정론적이어야 하며, 입력 파일 집합과 경로가 동일하면 항상 동일한 결과를 생성해야 한다.
  - Bundle hash 계산의 유일한 SSOT는 **[LOCK-17] Sorted Map Hash Rule**이다.
  - [LOCK-17]과 상충하는 다른 계산 규칙(section 정렬, raw byte 직접 concat 등)은 허용하지 않는다.
* **\[LOCK-15\] Runtime Version Compatibility Gate:** 로드 시 다음 기준에 따라 엄격히 검증한다.  
  * runtime.version \< manifest.min\_runtime\_version → Reject (Fail-fast)  
  * manifest.schema\_version이 현재 런타임이 지원하는 schema\_aversion 집합에 포함되지 않으면 → Reject (Fail-fast)

### **2.3 스토어 및 리소스 로딩 보안**

* **\[LOCK-8\] Immutable Bundle Store & Retention:** 모든 번들은 ops/runtime/bundles/ 하위의 immutable 디렉토리에 보관한다.  
* **\[LOCK-10\] Deny-by-default Resource Loading:** manifest에 명시되지 않은 파일 로딩은 절대 금지한다.  
* **\[LOCK-13\] Bundle Store Immutability Contract:** 생성된 번들 디렉토리의 파일 수정/덮어쓰기를 엄격히 금지하며 동일 버전 재사용을 불허한다.  
* **\[LOCK-14\] Symlink Resolution Canonicalization:** fs.realpath()를 통해 canonical path를 resolve하며 store root 탈출을 원천 차단한다.

### **2.4 세션 고정(Pinning) 안정성**

* **\[LOCK-5\] Backward-Compatible Session Pinning:** 기존 session\_state.json 스키마를 건드리지 않기 위해 별도 파일(\<session\_id\>\_bundle\_pin.json)을 사용한다.  
- Pin file path는 `storage/sessions/<session_id>.bundle_pin.json`으로 고정한다.
- session_state.*.json과 동일 디렉토리 레벨에 위치한다.
- Pin 파일은 SessionState와 병합하지 않는다.
* **\[LOCK-9\] Pin File Schema v1:** 아래 스키마를 따르며 SessionState와 병합을 금지한다.

{  
  "schema\_version": "v1",  
  "pinned\_at": "ISO8601\_TIMESTAMP",  
  "bundle\_id": "string",  
  "bundle\_version": "string",  
  "bundle\_hash": "sha256",  
  "bundle\_root": "canonical\_path"  
}

* **\[LOCK-12\] Active Bundle Switch Semantics:** 번들 교체는 새 세션에만 반영된다. 기존 세션은 pin된 경로를 유지한다.  
* **\[LOCK-16\] Pin Creation Atomicity:** O\_EXCL 플래그 및 Atomic Write(temp → rename)를 사용하여 경합을 방지한다.

## **3\. 핵심 구현 범위 (In-Scope)**

### **3.1 BundleResolver (독립 Adapter)**

레거시 PolicyInterpreter와 분리된 독립 클래스로 구현한다. 경로 보안(LOCK-10, 14), 해시 무결성(LOCK-11), 버전 게이트(LOCK-15)를 검증하며 실패 시 즉시 Fail-fast한다.

### **3.2 Active Bundle Switching & Session Pinning**

* **Bundle Store 구조:** ops/runtime/bundles/\<id\>/\<version\>/  
* **세션 시작 플로우:**  
  * **새 세션:** active\_bundle resolve → 검증 → pin 파일 생성(Atomic) → metadata 주입 → 해시 계산.  
  * **기존 세션:** pin 파일 로드 → bundle\_root resolve(active\_bundle 무시) → 검증 → metadata 주입 → 해시 계산.  
* **Retention (MVP):** 자동 삭제 기능은 비활성화하며 수동 정리를 원칙으로 한다.

## **4\. Hash Mismatch Semantics**

**Mismatch 발생 조건:**

1. bundle\_hash와 실제 파일 내용 불일치  
2. ExecutionContextMetadata에 포함된 bundleId, bundleVersion, bundleHash 중 하나라도 변경됨  
3. pin 파일에 기록된 정보와 실제 번들 경로(bundle\_root) 불일치

**동작:** 위 조건 발생 시 SESSION_STATE_HASH_MISMATCH 예외 발생 → 즉시 실행 중단.
사용자가 선택 가능한 복구 경로는 다음 두 가지뿐이다:

1. `--fresh-session`
   - session_state.*.json과 동일하게 bundle_pin.*.json도 회전(.bak) 후 재시작
2. `--promote-bundle`
   - 사용자의 명시적 동의 하에 pin 파일을 현재 Active Bundle 정보로 재생성/갱신

UI와 CLI는 동일한 가이드 문구를 사용한다.

## **5\. 완료 정의 기준 (Definition of Done)**

1. 독립된 BundleResolver 및 PinStore 구현 완료.  
2. 기존 세션 파손 없이 별도 Pin 파일을 통한 세션-번들 Pinning 달성.  
3. LOCK-11(해시), LOCK-13(불변성), LOCK-14(경로), LOCK-15(호환성) 검증 통과.
4. Sorted Map Hash 계산 유닛 테스트 추가 및 Drift 시나리오 테스트 통과.