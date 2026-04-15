#!/bin/bash
#
# Fetches GoogleService-Info.plist from the team 1Password vault.
#
# Prerequisites:
#   - Membership in the `client-api-secrets` 1Password vault.
#   - 1Password CLI installed: https://developer.1password.com/docs/cli/
#   - Signed in: `eval $(op signin)` (or biometric unlock if configured).
#
# Open-source contributors who don't have vault access can skip running this;
# the build will still succeed and Firebase will no-op at runtime.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${REPO_ROOT}/EluvioWalletTVOS/EluvioWalletTVOS/GoogleService-Info.plist"
OP_PATH="op://client-api-secrets/Firebase analytics tvOS plist/GoogleService-Info.plist"

if ! command -v op >/dev/null 2>&1; then
  echo "error: 1Password CLI ('op') not found." >&2
  echo "Install: https://developer.1password.com/docs/cli/get-started/" >&2
  exit 1
fi

op read "$OP_PATH" > "$DEST"
echo "Wrote $DEST"
