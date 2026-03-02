# **C-018: Bundle Promotion Intent Map**

## 1. 개요
번들 승격 및 관리 과정에서 발생하는 사용자/시스템 의도(Intent)를 매핑한다. **Strict Fail-Fast** 정책을 따르며, 모든 불일치는 즉각적인 실행 중단으로 이어진다.

## 2. Intent 매핑 테이블

| Intent | Trigger | Adapter (Resolver) | Runtime (Core) | Result | Ownership |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Promote Bundle** | CLI `--promote-bundle` | Validate Active Bundle + Re-pin (Explicit Only) | N/A | Pin file rotated/overwritten ONLY when `--promote-bundle` is present | Adapter |
| **Pin Session to Bundle** | Session Init | Create `*.bundle_pin.json` | N/A | Session bound to Bundle | Adapter |
| **Verify Bundle Hash** | Execution Start | **Sorted Map Hash** Calc | N/A | Integrity Verified/Fail | Adapter |
| **Detect Plan Hash Drift** | Core Loop | N/A | Compare Plan Hash | `HASH_MISMATCH` Abort | Core |
| **Enforce Pin Policy** | Every Execution | Compare Pin vs Active | N/A | Match: OK / Diff: Abort | Adapter |
| **Fresh Session** | `--fresh-session` | Rotate Pin (.bak) & Reset | Re-initialize | Rotate session_state + rotate bundle_pin (.bak) and re-init | Adapter/User |

* **[LOCK]** Promote(Pin 갱신)는 현재 세션의 즉시 실행 성공을 보장하지 않는다. 갱신 후 실제 실행 여부는 Runtime의 일반 정책(Plan Hash 일치 등)을 따른다.
