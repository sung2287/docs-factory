# B-036 -- Web Live Entry Contract

## 1. Web Entry Boundary
This contract defines the logical data shapes and communication patterns between the Web Shell (/v2) and the Orchestration API. It focuses exclusively on the entry and observation points required for live validation.

## 2. API Specifications

### Chat Submission (Logical Endpoint)
- Request Payload:
  - message: string (user input)
  - interventionResponse: object (optional)
    - action: "KEEP" | "MODIFY" | "REGISTER"
    - targetRootId: string (optional)
  - sessionPin: object (optional)
- Response Payload:
  - streamId: string
  - initialState: GraphState snippet

### Session Management (Logical Endpoint)
- Response Payload:
  - sessions: Array of session metadata
  - activeSessionId: string

### Telemetry / Atlas Visibility (Logical Endpoint)
- Data Shape:
  - type: "VALIDATOR_FINDING" | "STATE_TRANSITION" | "ATLAS_STATUS"
  - payload: Object containing specific data
- Note: Atlas visibility may be provided via snapshot, telemetry stream, or dedicated endpoint; the specific transport mechanism is not fixed in this contract.

## 3. Authority and Overrides
- The Web Shell treats API responses as authoritative; the UI does not mutate core state directly.
- Fields marked as STUB in the implementation may return hardcoded values or placeholders (e.g., "NOT_WIRED").
- Any UI-driven overrides (e.g., forcing a model choice) must be passed as explicit fields in the request, not as mutations of the core state.
