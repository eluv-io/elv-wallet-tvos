#!/bin/bash
# Auto-increments the NBA Summer League (com.eluvio.nbademo) build number
# (CURRENT_PROJECT_VERSION) in the Xcode project. Invoked from the
# EluvioWalletTVOS scheme's Archive pre-action so every Archive bumps the build.
# Only the NBA target's Debug + Release configs are touched; the Mobile and
# test targets are left alone.
set -euo pipefail

# SRCROOT is provided when the pre-action inherits build settings from the
# EluvioWalletTVOS target; fall back to the script's own location otherwise.
ROOT="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PROJECT="$ROOT/EluvioWalletTVOS.xcodeproj/project.pbxproj"

/usr/bin/env python3 - "$PROJECT" <<'PY'
import re, sys

path = sys.argv[1]
text = open(path).read()

def bump_block(match):
    block = match.group(0)
    if "com.eluvio.nbademo" not in block:
        return block
    return re.sub(
        r"CURRENT_PROJECT_VERSION = (\d+);",
        lambda m: "CURRENT_PROJECT_VERSION = %d;" % (int(m.group(1)) + 1),
        block,
    )

# Each `buildSettings = { ... }` dict contains no nested braces, so this
# matches one settings block at a time and only rewrites the NBA ones.
open(path, "w").write(re.sub(r"\{[^{}]*\}", bump_block, text))
PY

echo "Bumped NBA Summer League build number."
