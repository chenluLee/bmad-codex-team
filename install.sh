#!/usr/bin/env bash
set -euo pipefail

target="${1:-.}"

if [[ ! -d "$target" ]]; then
  echo "Target project does not exist: $target" >&2
  exit 1
fi

mkdir -p "$target/.codex/agents" "$target/_bmad/custom"

cp .codex/agents/*.toml "$target/.codex/agents/"
cp .codex/bmad-build-routing.md "$target/.codex/bmad-build-routing.md"

target_user_toml="$target/_bmad/custom/bmad-build.user.toml"
if [[ ! -f "$target_user_toml" ]]; then
  cp _bmad/custom/bmad-build.user.toml "$target_user_toml"
elif grep -Fq ".codex/bmad-build-routing.md" "$target_user_toml"; then
  echo "BMAD Codex routing persistent fact already present."
else
  example="$target/_bmad/custom/bmad-build.user.codex-team.example.toml"
  cp _bmad/custom/bmad-build.user.toml "$example"
  echo "Existing bmad-build.user.toml preserved."
  echo "Merge the persistent_facts entry from: $example"
fi

target_agents="$target/AGENTS.md"
if [[ ! -f "$target_agents" ]]; then
  cp AGENTS.md "$target_agents"
elif grep -Fq "## Codex bmad-build 子智能体" "$target_agents"; then
  echo "AGENTS.md already contains the Codex BMAD routing section."
else
  printf "\n\n" >> "$target_agents"
  cat AGENTS.md >> "$target_agents"
  echo "Appended Codex BMAD routing section to existing AGENTS.md."
fi

echo "Installed bmad-codex-team into: $target"
echo "Restart Codex or start a new task so custom agent roles are reloaded."
