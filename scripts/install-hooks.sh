#!/usr/bin/env bash
set -euo pipefail

HOOK_SOURCE="$(dirname "$0")/pre-commit"
HOOK_TARGET="$(git rev-parse --git-dir)/hooks/pre-commit"

cp "$HOOK_SOURCE" "$HOOK_TARGET"
chmod +x "$HOOK_TARGET"
echo "Installed pre-commit hook at $HOOK_TARGET"
echo "It blocks committing an unencrypted ansible/host_vars/all/secrets.yml."
