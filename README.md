# bmad-codex-team

Project-scoped Codex subagents for BMAD projects, with role-specific model and reasoning-effort profiles.

This repository is an overlay for an existing BMAD project. It does **not** fork BMAD. It uses two supported extension surfaces:

- Codex project agents in `.codex/agents/*.toml`
- BMAD workflow overrides in `_bmad/custom/*.toml`

## Goal

Route different BMAD tasks to different Codex child agents:

| Task | Agent | Default model | Reasoning |
| --- | --- | --- | --- |
| Codebase exploration | `BmadExplorer` | `gpt-6-luna` | `medium` + Fast |
| Story / build implementation | `BmadImplementer` | `gpt-6-luna` | `xhigh` |
| Blind/adversarial review | `BmadAdversarialReviewer` | `gpt-6-sol` | `high` |
| Edge-case review | `BmadEdgeCaseReviewer` | `gpt-6-sol` | `high` |
| Verification-gap review | `BmadVerificationReviewer` | `gpt-6-sol` | `high` |
| Acceptance / intent audit | `BmadAcceptanceAuditor` | `gpt-6-sol` | `xhigh` |

The profiles are intentionally project-scoped. A BMAD project can therefore pin its own model strategy without changing your global `~/.codex/agents`.

## Why this shape

Current BMAD exposes `workflow.implementation_handoff` plus configurable review lenses in `_bmad/custom/bmad-build.toml`. Current Codex custom-agent profiles can pin `model` and `model_reasoning_effort`, and fixed profile values take precedence over conflicting spawn-time values.

That makes a thin routing layer preferable to maintaining a BMAD fork.

## Install into a BMAD project

From this repository:

```bash
bash install.sh /absolute/path/to/your-bmad-project
```

Or copy manually:

```bash
cp -R .codex /path/to/project/
mkdir -p /path/to/project/_bmad/custom
cp _bmad/custom/*.toml /path/to/project/_bmad/custom/
```

Restart Codex / start a new task after installing or changing agent profiles so the role schema is reloaded.

## BMAD usage

Normal BMAD commands remain unchanged. For example:

```text
Use bmad-build full on this story.
```

With the overlay installed:

1. BMAD plans the change.
2. Full-route implementation is delegated to `BmadImplementer`.
3. Review lenses are delegated in parallel to model-pinned reviewer roles.
4. The parent BMAD session still owns triage, loopback, acceptance, and finalization.

For large-codebase discovery outside the Build handoff, explicitly dispatch `BmadExplorer` from the parent session.

## Design rules

- Parent agent owns decomposition, product decisions, triage, and final acceptance.
- Explorer is read-only and never edits.
- Implementer owns implementation changes and can be re-engaged for review fixes.
- Reviewers are context-free and read-only; they do not modify the reviewed work.
- Child agents do not spawn further agents.
- Review lenses stay independent from one another.

## Compatibility note

BMAD's current review workflow text says review children should use the same model capability as the parent session, while BMAD's customization surface also explicitly permits replacing a review recipe (including an external tool / different model). This overlay intentionally uses the customization surface to pin reviewer roles. Verify the effective child model in Codex traces after installation.

If your Codex host refuses a custom agent type, BMAD can still fall back to the parent session, but the pinned-model behavior is then not active.

## Repository layout

```text
.codex/agents/
  BmadExplorer.toml
  BmadImplementer.toml
  BmadAdversarialReviewer.toml
  BmadEdgeCaseReviewer.toml
  BmadVerificationReviewer.toml
  BmadAcceptanceAuditor.toml

_bmad/custom/
  bmad-build.toml

install.sh
```

## References

- oil-oil/codex-team-mode — custom Codex role profiles and model/effort pinning pattern.
- bmad-code-org/BMAD-METHOD — `bmad-build` implementation handoff and configurable review lenses.

## Status

v0.1 focuses on `bmad-build` / story implementation and its review lenses. Next extensions can add:

- standalone `bmad-review` role routing,
- per-project model policy presets,
- a small installer/config generator,
- runtime diagnostics that verify the effective model/effort used by each BMAD child.
