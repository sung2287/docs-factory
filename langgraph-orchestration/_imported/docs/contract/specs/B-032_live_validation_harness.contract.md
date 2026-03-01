# B-032 -- live_validation_harness.contract

## 1. SeedRunConfigV1
Defines the input parameters for a validation run.
```typescript
interface SeedRunConfigV1 {
  sessionId: string;
  mode: string;
  domain: string;
  inputPrompt: string;
  repeatCount: number; // min: 3
  freshSession: boolean; // true if starting from empty state
}
```

## 2. ValidationResultV1
Defines the captured state for integrity comparison.
```typescript
interface ValidationResultV1 {
  planHash: string;
  snapshotId: string;
  interventionStatus: "NONE" | "REQUIRED";
  decisionCount: number;
  workItemCount: number;
  atlasFingerprint: string;
}
```
- snapshotId represents the compositeHash(repoStructureHash + decisionStateHash).
- atlasFingerprint represents the AtlasHash (computeAtlasHash result).
- snapshotId and atlasFingerprint are distinct identifiers and MUST NOT be conflated.

## 3. Explicit Rules
- Validator findings are NOT included in the PlanHash calculation.
- snapshotId calculation MUST NOT include time-based or random values.
- ValidationResultV1 MUST NOT contain raw LLM output strings.
- SeedRun verification is only performed on the state existing AFTER PersistSession completion.
