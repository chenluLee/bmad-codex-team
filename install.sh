#!/usr/bin/env bash
set -euo pipefail

target="${1:-.}"

if [[ ! -d "$target" ]]; then
  echo "Target project does not exist: $target" >&2
  exit 1
fi

mkdir -p "$target/.codex/agents" "$target/_bmad/custom"

cp .codex/agents/*.toml "$target/.codex/agents/"
cp _bmad/custom/bmad-build.toml "$target/_bmad/custom/bmad-build.toml"

echo "Installed bmad-codex-team into: $target"
echo "Restart Codex or start a new task so custom agent roles are reloaded."
echo "Then run BMAD normally; full-route implementation and review lenses will use the pinned roles."
