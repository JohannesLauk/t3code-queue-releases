#!/bin/zsh
set -euo pipefail

readonly SOURCE_REPO="/Users/johannes/Developer/t3code-queue"
readonly CONFIG_REPO="/Users/johannes/Developer/t3code-queue-releases"
readonly RELEASE_REPO="JohannesLauk/t3code-queue-releases"
readonly STATE_DIR="/Users/johannes/Library/Application Support/T3 Code Queue Builder"
readonly STATE_FILE="$STATE_DIR/last-source-sha"
readonly LOCK_DIR="/tmp/t3code-queue-builder.lock"
readonly SIGNING_IDENTITY="Apple Development: Created via API (M8M7BY6JD8)"
export PATH="/Users/johannes/.local/share/vite-plus/bin:/Users/johannes/.local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  lock_pid="$(command cat "$LOCK_DIR/pid" 2>/dev/null || true)"
  if [[ "$lock_pid" == <-> ]] && kill -0 "$lock_pid" 2>/dev/null; then
    print "A T3 Code Queue build is already running."
    exit 0
  fi
  rm -f "$LOCK_DIR/pid"
  rmdir "$LOCK_DIR"
  mkdir "$LOCK_DIR"
fi
print -r -- "$$" > "$LOCK_DIR/pid"

output_dir="$(mktemp -d /tmp/t3code-queue-release.XXXXXX)"
cleanup() {
  rm -f "$LOCK_DIR/pid"
  rmdir "$LOCK_DIR" 2>/dev/null || true
  rm -rf "$output_dir"
}
trap cleanup EXIT

mkdir -p "$STATE_DIR"
cd "$SOURCE_REPO"

pr_state="$(gh pr view 2829 --repo pingdotgg/t3code --json state --jq .state)"
merged_at="$(gh pr view 2829 --repo pingdotgg/t3code --json mergedAt --jq '.mergedAt // empty')"

if [[ -n "$merged_at" ]]; then
  git fetch --quiet origin main:refs/remotes/origin/main
  source_ref="origin/main"
elif [[ "$pr_state" == "OPEN" ]]; then
  git fetch --quiet origin refs/pull/2829/head:refs/remotes/origin/queue-pr
  source_ref="origin/queue-pr"
else
  print "PR #2829 closed without merging; keeping the last working release."
  exit 0
fi

source_sha="$(git rev-parse "$source_ref")"
if [[ "${FORCE_BUILD:-0}" != "1" && -f "$STATE_FILE" && "$(<"$STATE_FILE")" == "$source_sha" ]]; then
  print "No new queue source commit."
  exit 0
fi

git reset --hard "$source_sha"

apply_patch() {
  local patch_file="$1"
  if git apply --check "$patch_file"; then
    git apply "$patch_file"
  elif git apply --reverse --check "$patch_file"; then
    print "Patch already present upstream: ${patch_file:t}"
  else
    print "Patch no longer applies cleanly: $patch_file" >&2
    exit 1
  fi
}

apply_patch "$CONFIG_REPO/patches/automatic-updates.patch"
apply_patch "$CONFIG_REPO/patches/local-signing.patch"

upstream_version="$(node -p 'require("./apps/desktop/package.json").version')"
IFS=. read -r version_major version_minor version_patch <<< "$upstream_version"
version="${version_major}.${version_minor}.$((version_patch + 1))-nightly.$(date -u +%Y%m%d).$(date -u +%s)"

vp install --frozen-lockfile --prefer-offline \
  --filter @t3tools/monorepo \
  --filter '@t3tools/desktop...' \
  --filter 't3...' \
  -- --network-concurrency=4 --fetch-retries=5 --fetch-timeout=120000
vp test run apps/desktop/src/updates/DesktopUpdates.test.ts

T3CODE_DESKTOP_UPDATE_REPOSITORY="$RELEASE_REPO" \
CSC_NAME="$SIGNING_IDENTITY" \
vp run dist:desktop:dmg \
  --arch arm64 \
  --build-version "$version" \
  --output-dir "$output_dir" \
  --signed

gh release create "v$version" "$output_dir"/* \
  --repo "$RELEASE_REPO" \
  --title "T3 Code Queue $version" \
  --notes "Queue-enabled T3 Code build from upstream commit $source_sha." \
  --prerelease

print -r -- "$source_sha" > "$STATE_FILE"
print "Published T3 Code Queue $version from $source_sha."
