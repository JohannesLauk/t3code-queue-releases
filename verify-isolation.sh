#!/bin/zsh
set -euo pipefail

readonly STABLE_APP="${1:-/Applications/T3 Code.app}"
readonly QUEUE_APP="${2:-/Applications/T3 Code Queue.app}"

stable_id="$(plutil -extract CFBundleIdentifier raw "$STABLE_APP/Contents/Info.plist")"
queue_id="$(plutil -extract CFBundleIdentifier raw "$QUEUE_APP/Contents/Info.plist")"
stable_cache="$(awk '$1 == "updaterCacheDirName:" { print $2 }' "$STABLE_APP/Contents/Resources/app-update.yml")"
queue_cache="$(awk '$1 == "updaterCacheDirName:" { print $2 }' "$QUEUE_APP/Contents/Resources/app-update.yml")"
queue_name="$(plutil -extract CFBundleDisplayName raw "$QUEUE_APP/Contents/Info.plist")"

failed=0
if [[ "$stable_id" == "$queue_id" ]]; then
  print "RED bundle-id collision: $queue_id"
  failed=1
fi
if [[ "$stable_cache" == "$queue_cache" ]]; then
  print "RED updater-cache collision: $queue_cache"
  failed=1
fi
if [[ "$queue_name" != "T3 Code Queue" ]]; then
  print "RED queue app name: $queue_name"
  failed=1
fi

if (( failed )); then
  exit 1
fi

print "GREEN stable=$stable_id/$stable_cache queue=$queue_id/$queue_cache"
