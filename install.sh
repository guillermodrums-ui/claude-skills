#!/usr/bin/env bash
# Install Claude Code skills from this repo into ~/.claude/skills/.
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/guillermodrums-ui/claude-skills/main/install.sh | bash -s <skill-name> [<skill-name>...]
#   curl -sSL https://raw.githubusercontent.com/guillermodrums-ui/claude-skills/main/install.sh | bash -s --all
#   curl -sSL https://raw.githubusercontent.com/guillermodrums-ui/claude-skills/main/install.sh | bash         # lists available skills

set -euo pipefail

REPO="guillermodrums-ui/claude-skills"
BRANCH="main"
SKILLS_DIR="${HOME}/.claude/skills"
TARBALL_URL="https://codeload.github.com/${REPO}/tar.gz/${BRANCH}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "→ Downloading ${REPO}@${BRANCH}..."
curl -sSL "${TARBALL_URL}" | tar -xz -C "${TMP_DIR}"
SRC_DIR="${TMP_DIR}/claude-skills-${BRANCH}/skills"

if [[ ! -d "${SRC_DIR}" ]]; then
  echo "ERROR: skills/ not found in downloaded tarball" >&2
  exit 1
fi

AVAILABLE=$(find "${SRC_DIR}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)

if [[ $# -eq 0 ]]; then
  echo ""
  echo "Available skills:"
  echo "${AVAILABLE}" | sed 's/^/  - /'
  echo ""
  echo "Install with: curl -sSL https://raw.githubusercontent.com/${REPO}/${BRANCH}/install.sh | bash -s <skill-name>"
  exit 0
fi

if [[ "$1" == "--all" ]]; then
  set -- ${AVAILABLE}
fi

mkdir -p "${SKILLS_DIR}"

for skill in "$@"; do
  if [[ ! -d "${SRC_DIR}/${skill}" ]]; then
    echo "ERROR: skill '${skill}' not found. Available:" >&2
    echo "${AVAILABLE}" | sed 's/^/  - /' >&2
    exit 1
  fi
  DEST="${SKILLS_DIR}/${skill}"
  if [[ -e "${DEST}" ]]; then
    echo "→ Replacing existing ${DEST}"
    rm -rf "${DEST}"
  fi
  cp -r "${SRC_DIR}/${skill}" "${DEST}"
  echo "✓ Installed ${skill} → ${DEST}"
done

echo ""
echo "Done. Restart Claude Code to pick up new skills."
