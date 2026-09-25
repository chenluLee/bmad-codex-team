# Architecture

## Control plane

The parent Codex session runs BMAD and remains the orchestrator. BMAD owns planning, route selection, spec state, review triage, loopbacks, and final acceptance.

## Execution plane

Codex project-scoped custom agents provide model/effort pinning:

- `BmadExplorer`: repository discovery only.
- `BmadImplementer`: implementation.
- `BmadAdversarialReviewer`: independent defect/missing-behavior review.
- `BmadEdgeCaseReviewer`: boundary and failure-path review.
- `BmadVerificationReviewer`: test coverage / verification-gap review.
- `BmadAcceptanceAuditor`: acceptance and original-intent alignment.

BMAD's `implementation_handoff` and configurable lens instructions are the routing layer between the two.

## Why project-scoped profiles

Codex custom-agent profiles can be installed globally or per project. This project uses `.codex/agents` so different BMAD repositories can choose different model policies without global collisions.

## Context policy

Implementation receives the BMAD spec and its declared `context:` files. Reviewers start context-free and receive only the artifacts their lens requires. This preserves reviewer independence and reduces confirmation bias.

## Write ownership

Only the implementer receives `workspace-write`. Review roles and Explorer are `read-only`. The parent session owns triage and any direct fallback edits BMAD requires.

## Model policy

The initial profile follows the pattern proven by codex-team-mode:

- cheaper/faster model for exploration,
- strong high-effort model for implementation,
- stronger review model for independent inspection,
- extra-high effort only where intent/acceptance synthesis benefits from it.

Treat these as defaults, not universal truths. Change the TOML profiles per repository when cost, latency, or model availability differs.
