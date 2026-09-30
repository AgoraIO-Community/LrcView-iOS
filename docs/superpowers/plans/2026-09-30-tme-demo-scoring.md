# TME Demo Scoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the TME Demo play with synchronized lyrics and scoring when `song-info` resources are available, while continuing audio-only on resource failure and keeping preparation code copyable.

**Architecture:** A Foundation-only `TMEScoringPreparation<Model>` takes the existing MCC send closure, receives MCC responses, delegates JSON decoding to `TMEParser`, downloads both resources with an injectable `URLSession`, and invokes an injected model parser with local paths. `TmeManager` gates playback on media open and preparation completion, forwards local RTC pitch and player progress, and owns session cleanup. A dedicated `TmeSingingVC` renders status, playback, lyrics and line scores.

**Tech Stack:** Swift 5, UIKit, AgoraRtcKit/MCC, URLSession, existing AgoraLyricsScore and TMEParser, Swift command-line tests, xcodebuild.

**Spec:** `docs/superpowers/specs/2026-09-30-tme-demo-scoring-design.md`

**Workspace:** Implement in this checkout: `TmeManager.swift`, `TmeTestVC.swift`, Podfile and Xcode project are already modified/untracked user work; a new worktree cannot see them. Preserve all existing unrelated edits. Only stage files explicitly changed for this feature.

### Task 1: Reusable preparation service

**Files:**
- Create: `Demo/Demo/Other/Utils/TMEScoringPreparation.swift`
- Create: `scripts/tests/TMEScoringPreparationTests.swift`
- Modify: `Demo/Demo.xcodeproj/project.pbxproj` (register helper once in Demo Sources)

- [ ] **Step 1: Add a failing Foundation command-line test.** Compile the existing parser models/decoder with a new test harness. Exercise the wished-for API using an in-memory send closure, `prepare(songId:sendRequest:)`, `handleResponse(requestId:jsonOption:httpCode:response:)`, `cancel()`, `onStatus`, `onCompletion`, and an injected `parseModel(tonePath, lyricPath)` closure. The first test asserts request fields without a network connection:

```swift
let preparation = TMEScoringPreparation<String>(parseModel: { _, _ in "ok" })
var option = ""
preparation.prepare(songId: "s1") { json in option = json; return "request-1" }
let request = try JSONSerialization.jsonObject(with: Data(option.utf8)) as! [String: Any]
precondition(request["vendorId"] as? Int == 2)
precondition(request["actionType"] as? String == "song-info")
precondition((request["actionParameter"] as? [String: String])?["songIdListStr"] == "s1")
```

  Next use a decoded response whose first entry is another song and whose second has `pitchUrl` plus both `krc` and `lrc` URLs. The harness must be `@main` and assert on the main thread after pumping `RunLoop.main` for the asynchronous decoder.
- [ ] **Step 2: Run RED:** `swiftc -module-cache-path /private/tmp/kl-tme-module-cache -o /private/tmp/tme-scoring-preparation-test Demo/Demo/Other/Utils/TMEParserModels.swift Demo/Demo/Other/Utils/TMEParser.swift Demo/Demo/Other/Utils/TMEScoringPreparation.swift scripts/tests/TMEScoringPreparationTests.swift` must fail because `TMEScoringPreparation.swift` is absent.
- [ ] **Step 3: Implement request and parsing.** Expose `TMEScoringPreparation<Model>` using this contract. Keep all mutable state on main; `TMEParser` already invokes its delegate on main. Return `true` from `handleResponse` only for the active request. Build JSON with `JSONSerialization`, not interpolation:

```swift
enum Status { case requestingSongInfo, downloadingLyrics, lyricsDownloaded,
              downloadingPitch, pitchDownloaded, parsing }
enum PreparationError: Error { case requestFailed, invalidSongInfo, invalidURL,
                               downloadFailed, invalidFiles }
init(session: URLSession = .shared, parseModel: @escaping (String, String) -> Model?)
var onStatus: ((Status) -> Void)?
var onCompletion: ((Result<Model, PreparationError>) -> Void)?
func prepare(songId: String, sendRequest: (String) -> String?)
func handleResponse(requestId: String, jsonOption: String,
                    httpCode: Int, response: String) -> Bool
func cancel()
```
- [ ] **Step 4: Test network and cancellation.** With a test `URLProtocol` registered on an injected `URLSession`, return fixture pitch/LRC data and verify two independent statuses, paths in a unique session directory, parsed model, signed URL integrity and one completion. Add tests for missing fields, HTTP/decoder failure, either download failing, model parser returning `nil`, cancellation and late callbacks. Run RED for each behavior before implementing its minimal code; use `URLSession.dataTask` and atomic file writes with a session UUID directory so transport is straightforward to stub and cancel.
- [ ] **Step 5: Run GREEN:** compile command from Step 2 followed by `/private/tmp/tme-scoring-preparation-test`; also run `swiftc -module-cache-path /private/tmp/kl-tme-module-cache -o /private/tmp/tme-parser-regression Demo/Demo/Other/Utils/TMEParserModels.swift Demo/Demo/Other/Utils/TMEParser.swift scripts/tests/TMEParserTests.swift` and `/private/tmp/tme-parser-regression`. Register new source in Demo Xcode project without altering other user changes.

### Task 2: Manager playback gate and RTC input

**Files:**
- Modify: `Demo/Demo/Other/Utils/TmeManager.swift`
- Create: `scripts/tests/TMEPlaybackGateTests.swift`
- Create: `Demo/Demo/Other/Utils/TMEPlaybackGate.swift`
- Modify: `Demo/Demo.xcodeproj/project.pbxproj` (register gate)

- [ ] **Step 1: RED on playback gate.** Test a Foundation-only `TMEPlaybackGate` with both arrival orders and cancellation:

```swift
let gate = TMEPlaybackGate()
var modes = [TMEPlaybackGate.Mode]()
gate.onStart = { modes.append($0) }
gate.mediaOpened()
precondition(modes.isEmpty)
gate.resourcesReady()
gate.mediaOpened()
precondition(modes == [.playWithScoring])
```

  In separate instances, call `resourcesFailed()` before/after `mediaOpened()`, assert `.playWithoutScoring` exactly once; `stop()` before completion must emit nothing. Compile `swiftc -module-cache-path /private/tmp/kl-tme-module-cache -o /private/tmp/tme-playback-gate-test Demo/Demo/Other/Utils/TMEPlaybackGate.swift scripts/tests/TMEPlaybackGateTests.swift` before production file exists; verify failure.
- [ ] **Step 2: GREEN on gate.** Implement `TMEPlaybackGate` with `enum Mode { case playWithScoring, playWithoutScoring }`, `var onStart: ((Mode) -> Void)?`, `mediaOpened()`, `resourcesReady()`, `resourcesFailed()`, and `stop()`. Only emit when opened and resources have a terminal result, and set a fired flag before callback invocation to withstand delegate reentry. Run the Step 1 command and binary until pass.
- [ ] **Step 3: Wire `TmeManager`.** Preserve existing RTC/MCC creation and songs behavior. Store `currentTMESongId` separately from numeric `selectedSongCode`; on matching preload `.OK` start preparation with `{ center.sendExtRequest(jsonOption: $0) }` and open media. Route only matching `song-info` response to preparation, keep songs on original `responseParser`. On `.openCompleted`, notify gate rather than calling `play()` immediately. On completed model/error, notify delegate/status and gate; play only once, report actual play failure. Enable local voice indication on existing RTC, forward its `voicePitch` to delegate while scoring, and expose `getPosition()` for progress. On `stopSong()` cancel preparation, stop player and gate without destroying RTC/MCC; `stop()` additionally destroys SDK resources.
- [ ] **Step 4: Verify manager integration.** Build Demo simulator with `xcodebuild -workspace Demo/Demo.xcworkspace -scheme Demo -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/kl-tme-demo-scoring-derived CODE_SIGNING_ALLOWED=NO build`. Re-run both Foundation test binaries and `scripts/tests/tme_sdk_flow.sh` (existing text assertion may require adjusting to new playback flow, preserving its substantive checks).

### Task 3: Dedicated singing page

**Files:**
- Create: `Demo/Demo/VC/MainVC/TmeSingingVC.swift`
- Modify: `Demo/Demo/VC/MainVC/TmeTestVC.swift`
- Modify: `Demo/Demo.xcodeproj/project.pbxproj` (register page)
- Test: `scripts/tests/tme_sdk_flow.sh`

- [ ] **Step 1: RED on page integration.** Extend the shell flow test to demand an independent `TmeSingingVC`, immediate `navigationController?.pushViewController`, a `KaraokeView` with `setLyricData(data:usingInternalScoring: true)`, `setProgress`, `setPitch`, `didFinishLineWith`, and return-path `stopSong`. Run the script and observe missing page.
- [ ] **Step 2: Implement presentation.** On row selection instantiate the page with selected song and shared manager, set manager delegate to page, push immediately, then call `manager.select(song)`. Keep the list delegate on returning. Page uses unframed UIKit vertical layout: title, separate lyric/pitch status rows, scoring `KaraokeView`, per-line and cumulative score, pause/resume button. Hook `ProgressProvider` to `player.getPosition()`, use existing 250-ms progress alignment, apply `setPitch` only for scoring playback, hide karaoke/score UI on resource error while preserving song title/status/control, stop provider and model at completion or return.
- [ ] **Step 3: GREEN and visual check.** Re-run shell test and simulator build. For available iOS simulator use `xcodebuild test` for `AgoraLyricsScore-Unit-Tests/TestTMEToneParser` and `TestTMEToneScoring`; inspect layout on iPhone 14 and SE with screenshots if device can run without real credentials. Confirm status strings and pause/finished/error states do not overlap.

### Task 4: Copy guide and final verification

**Files:**
- Create: `Demo/TME_SCORING.md`
- Modify: `scripts/tests/tme_sdk_flow.sh` (final wiring assertions)

- [ ] **Step 1: Document copy set.** Show exact files `TMEScoringPreparation.swift`, `TMEParser.swift`, `TMEParserModels.swift`, `TMEPlaybackGate.swift` and API usage with caller-owned MCC, media player, RTC, `KaraokeView`. Include explicit `onExtResponse` forwarding, `onPreLoadEvent(.OK)`, file status, cancellation, player-gate and pitch/progress callbacks; no real IDs/tokens.
- [ ] **Step 2: Verify.** Run all Foundation tests, shell integration checks, Demo simulator build, library TME + parser/scoring regressions, `git diff --check`, and `git status --short`. Verify only owned feature files are staged if committing, preserve all other dirty files. Real network/RTC TME access needs a configured device; report it separately if unavailable.
