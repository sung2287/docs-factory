# C-036 -- Web Live Entry Intent Map

## 1. Intent Mapping
This map connects user goals to specific UI actions and the expected system outcomes. No intent requires CLI-only initiation.

| User Intent | Web UI Action | API Call (Logical) | Expected Observable Outcome | Status |
| :--- | :--- | :--- | :--- | :--- |
| Start New Session | Click "New Session" in Left Panel | POST /sessions | Chat timeline resets; new session ID appears. | LIVE |
| Send User Message | Type in Center input + Enter | POST /chat | Message appears in timeline; response starts streaming. | LIVE |
| Respond to Intervention | Click canonical choice button | POST /chat | System resumes; status changes from "InterventionRequired". | LIVE |
| Observe Validation | View Right Panel (Dev Panel) | Telemetry Stream | Validator findings appear in real-time. | LIVE |
| Observe Atlas Sync | View Atlas section in Right Panel | Atlas Visibility Channel (Logical) | Current Atlas fingerprint and stale status visible. | STUBBED |
| Change Runtime Settings | Select Model/Provider in Left Panel | POST /chat | Next turn uses the selected provider/model via override. | LIVE |
| Trigger Conflict Scenario | Send message triggering violation | POST /chat | UI renders structured conflict report banner. | LIVE |

## 2. Live vs Stubbed Logic
- LIVE: Intents mapped to fully functional backend services.
- STUBBED: Intents that expose UI entry points but interact with placeholder API responses or mock data.
