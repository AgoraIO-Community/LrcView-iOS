#!/usr/bin/env bash
set -euo pipefail

task_root="$(cd "$(dirname "$0")/../.." && pwd)"
task_output="$(mktemp -d "${TMPDIR:-/tmp}/tme-public-component.XXXXXX")"
# All generated files belong to this unique test directory.
trap 'rm -r "$task_output"' EXIT
task_sources="$task_root/AgoraLyricsScore/Class/TME"

# Separate module/client compilation intentionally exercises public access.
# This Foundation-only slice uses the exact sources shipped by the pod.
xcrun swiftc -swift-version 5 -module-cache-path "$task_output/cache" \
  -emit-library -emit-module -module-name AgoraLyricsScore \
  -emit-module-path "$task_output/AgoraLyricsScore.swiftmodule" \
  "$task_sources/TMEParserModels.swift" "$task_sources/TMEParser.swift" \
  "$task_sources/TMEResponseTracker.swift" "$task_sources/TMEScoringPreparation.swift" \
  -o "$task_output/libAgoraLyricsScore.dylib"
for task_test in TMEParserTests TMEResponseTrackerTests TMEScoringPreparationTests; do
  xcrun swiftc -swift-version 5 -module-cache-path "$task_output/cache" \
    -I "$task_output" -L "$task_output" -lAgoraLyricsScore \
    -Xlinker -rpath -Xlinker "$task_output" -parse-as-library \
    "$task_root/scripts/tests/$task_test.swift" -o "$task_output/$task_test"
  "$task_output/$task_test"
done

xcrun swiftc -swift-version 5 -module-cache-path "$task_output/cache" \
  -I "$task_output" -L "$task_output" -lAgoraLyricsScore \
  -Xlinker -rpath -Xlinker "$task_output" -parse-as-library \
  "$task_root/Demo/Demo/Other/Utils/TmeSongCatalog.swift" \
  "$task_root/scripts/tests/TmeSongCatalogTests.swift" -o "$task_output/TmeSongCatalogTests"
"$task_output/TmeSongCatalogTests"
