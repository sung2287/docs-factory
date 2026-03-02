# C-035 — Policy Decision Core Unlock Intent Map

**Title:** Policy Decision Core Unlock & Wiring Completion

## Actors
- Web UI
- Core Engine
- PersistSession
- Post-run Registration

## Flow

1. **POLICY finding occurs.**
2. **UI submits interventionResponse:**
   - action: `MODIFY_POLICY` | `REGISTER_POLICY` | `KEEP_POLICY`
3. **runGraph injects state.interventionResponse.**
4. **PersistDecision resolves action via wiring.**
5. **If MODIFY/REGISTER:**
   - DecisionProposal created.
6. **PersistSession commit.**
7. **Post-run eligibility materialization.**
8. **Next session adopts policy.**

## Non-goals
- No retroactive mutation of active session.
- No `executionPlan` recalculation mid-run.
