# D-036 -- Web Shell Platform

## 1. Web Shell Architecture
The Web Shell is the primary runtime container for the LangGraph Orchestration UI. It is built as a single-page application (SPA) served from the /v2 route.

### Structural Components
- **Shell Layout**: The top-level grid or flex container defining the three-panel structure.
- **Timeline Engine**: Manages the rendering of the chat history and the transition between turns.
- **Dev Panel**: A secondary diagnostic layer that consumes telemetry streams independently of the chat flow.

## 2. Boundaries and Gating

### Route Gating
- /v2: Canonical Web Shell entry point.
- /v1 (or /): Legacy or non-authoritative UI.
- APIs reuse existing /api/* endpoints; no API namespace migration or versioning is introduced.

### Development Mode (IS_DEV)
- When IS_DEV=true, the Dev Mode Overlay and the Right Panel (Dev Panel) are enabled for diagnostic purposes.
- When IS_DEV=false, the Dev Panel is hidden, and system diagnostic telemetry is suppressed.
- The Dev Panel MUST NOT become an alternate control plane; it is for observation and triggering diagnostic scenarios only.

## 3. Separation of Concerns
- **Web Shell**: Responsible for user interaction, input capture, and system observation.
- **Dev Overlay**: A specialized diagnostic HUD that floats over the UI for real-time state inspection.
- **Core Runtime**: The backend execution engine. The Web Shell interacts with the core only through the defined logical API boundary (B-036).

## 4. Verification Authority
The Web Shell is the final user-facing validation surface. Any feature that is not observable or triggerable from the Web Shell is considered "Incomplete" or "Not Web Live." The CLI remains available for intermediate verification and administrative tasks but is not authoritative for Web Live behavior.
