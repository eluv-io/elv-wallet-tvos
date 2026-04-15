#!/bin/bash
#
# Xcode Cloud pre-build hook. Runs automatically before xcodebuild.
# Decodes the real GoogleService-Info.plist from a base64-encoded secret
# environment variable and writes it into the source tree. The plist is
# git-ignored, so without this step it would be absent and Firebase would
# be disabled at runtime.
#
# To set up the secret:
#   1. base64 -i GoogleService-Info.plist | pbcopy
#   2. App Store Connect → Xcode Cloud → workflow → Environment Variables
#      Add GOOGLE_SERVICE_INFO_PLIST_B64 as a *secret*.

set -euo pipefail

DEST="${CI_PRIMARY_REPOSITORY_PATH}/EluvioWalletTVOS/EluvioWalletTVOS/GoogleService-Info.plist"

if [ -n "${GOOGLE_SERVICE_INFO_PLIST_B64:-}" ]; then
  echo "$GOOGLE_SERVICE_INFO_PLIST_B64" | base64 --decode > "$DEST"
  echo "Wrote GoogleService-Info.plist from GOOGLE_SERVICE_INFO_PLIST_B64 secret."
else
  echo "GOOGLE_SERVICE_INFO_PLIST_B64 not set — Firebase will be disabled in this build."
fi
