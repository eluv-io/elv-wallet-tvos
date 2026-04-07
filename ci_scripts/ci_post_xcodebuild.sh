#!/bin/bash

# Post a GitHub commit status with the TestFlight build number
# Requires GITHUB_TOKEN env var set in Xcode Cloud workflow

if [ -z "$GITHUB_TOKEN" ] || [ -z "$CI_COMMIT" ] || [ -z "$CI_BUILD_NUMBER" ]; then
  echo "Missing required env vars, skipping GitHub status update"
  exit 0
fi

# Only post for archive builds (TestFlight)
if [ "$CI_XCODEBUILD_ACTION" != "archive" ]; then
  echo "Not an archive build, skipping"
  exit 0
fi

curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/eluv-io/elv-wallet-tvos/statuses/$CI_COMMIT" \
  -d "{
    \"state\": \"success\",
    \"description\": \"TestFlight build #$CI_BUILD_NUMBER\",
    \"context\": \"TestFlight\",
    \"target_url\": \"https://appstoreconnect.apple.com\"
  }"

echo "Posted GitHub status: TestFlight build #$CI_BUILD_NUMBER"
