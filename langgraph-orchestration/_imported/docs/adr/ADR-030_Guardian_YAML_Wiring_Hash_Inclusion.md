# ADR-030: Guardian YAML Wiring Hash Inclusion Policy

## Status
Accepted (2026-02-28)

## Context
웹 런타임에서 가디언 검증기를 동적으로 주입함에 있어, 이 구성 정보가 실행 계획의 정체성(`PlanHash`)에 포함되어야 하는지에 대한 결정이 필요함.

## Decision
가디언 설정(`validators`, `postValidators`)을 `PlanHash` 계산 로직에 **직접 포함**하기로 결정함.

### Rationale
1. **무결성 보장**: 동일한 플랜이라도 검증기 구성이 다르면 시스템의 행동 결과(BLOCK 여부 등)가 달라질 수 있으므로, 이를 다른 계획으로 간주하는 것이 타당함.
2. **순서 의존성**: 가디언 실행 순서가 결과에 영향을 줄 수 있으므로, 정렬 로직 없이 YAML 선언 순서 자체를 해시에 반영하여 엄격한 재현성을 확보함.

## Consequences
- 가디언 구성을 변경하면 기존 세션과의 `PlanHash` 불일치가 발생함.
- 향후 대규모 검증기 변경 시 하위 호환성을 위한 해시 마이그레이션 전략이 필요할 수 있음.
