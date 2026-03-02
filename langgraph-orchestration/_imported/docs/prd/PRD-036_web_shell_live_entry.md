# PRD-036 -- Web Shell Live Entry

## 1. Objective
The goal of this PRD is to establish /v2 as the canonical, unified Web Shell for the LangGraph Orchestration system. This "Web Shell" will serve as the primary environment for all system interactions, ensuring that every feature and test case (Tests 1-6) has a visible, functional entry point in the web interface.

All API references in this PRD are logical contracts; existing /api/* endpoints may be reused without introducing new API versioning.

- Declare /v2 as the authoritative Web Shell.
- Create explicit Web Entry Sockets for all live validation tests.
- Ensure all APIs reuse existing /api/* endpoints; no API version migration is required.
- Maintain CLI only as an intermediate or administrative verification path.

## 2. Scope (IN)

### Web Shell Layout
- Left Panel: Session history, session selection, and model/provider settings.
- Center Panel: Chat timeline rendering with message input and response streaming.
- Right Panel (Dev Panel): Real-time system telemetry, validator findings, and state inspection.

### InterventionRequired Web Entry
- Structured UI rendering for InterventionRequired signals.
- Support for canonical wire-level action values: KEEP | MODIFY | REGISTER.
- Note: UI labels may differ for user experience, but wire values MUST remain canonical.
- Direct wiring of user response to the next turn's interventionResponse payload.

### Atlas Visibility
- Dedicated slot in the Dev Panel for Atlas state (stale/revalidation status).
- Visibility for atlasFingerprint and snapshotId comparisons.
- Atlas visibility may be provided via snapshot, telemetry stream, or dedicated endpoint; transport is not fixed in this PRD.

### Dev Overlay Integration
- Integration of the Dev Mode Overlay (PRD-019) as a debug-only surface.
- Gated access via IS_DEV environment flag.
- Real-time telemetry feed from the core runtime to the overlay.

### Test Entry Points (1-6)
- Natural UI entry points (e.g., specific message inputs, setting changes) that trigger Test 1-6 scenarios.
- Dev-only diagnostic triggers MAY exist for internal validation but are not part of the product UI.

## 3. Scope (OUT)
- Core runtime logic or GraphState mutation rules.
- Hash semantics or PlanHash calculation logic.
- Real-time policy interpretation or Atlas index computation.
- Expansion of CLI-only administrative features.
- Final visual polish, custom theming, or complex CSS animations.

## 4. Constraints (LOCK)
- /v2 is the only authoritative surface for Web Live validation.
- No "silent" test paths that can only be triggered via CLI.
- Web must expose entry even if the backend wiring is stubbed or mocked.
- The UI must remain a passive observer/trigger; it must not recompute policy or interpret system semantics.
- Core-Zero-Mod: No modifications to the core runtime execution loop are allowed for UI support.
- All API interactions are logical contracts; existing /api/* endpoints must be prioritized.

## 5. Exit Criteria
- Natural UI entry points exist for each test scenario (Tests 1-6).
- An InterventionRequired signal can be successfully rendered and responded to within the /v2 chat interface.
- The Atlas stale state is visible in the Dev Panel (even if marked as "Not Wired").
- No CLI commands are required to initiate or observe Web Live behavior.
- The Dev Overlay remains a read-only or diagnostic tool and does not become an alternate control plane.
