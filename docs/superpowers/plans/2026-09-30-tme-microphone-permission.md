# TME Demo Microphone Permission Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prompt for microphone access before starting TME RTC, show a clear denial message, and ignore permission callbacks after leaving the page.

**Architecture:** A Foundation-only `TMEMicrophonePermissionGate` owns the pending authorization generation and accepts injected status/request closures. `TmeManager` adapts `AVAudioSession` to that gate and retains its existing RTC/MCC initialization after authorization. The Xcode project registers the new source; Debug and Release use a recording-specific permission description.

**Tech Stack:** Swift 5, Foundation, AVFoundation, UIKit, AgoraRtcKit, Swift command-line tests, xcodebuild, iOS Simulator.

**Spec:** `docs/superpowers/specs/2026-09-30-tme-microphone-permission-design.md`.

**Workspace:** Use the current `LrcView-iOS` checkout. `TmeManager.swift`, the Xcode project, and the TME flow test contain uncommitted user work and are not visible in a new worktree. Preserve all unrelated changes; do not stage or commit implementation files without checking ownership with the user.

### Task 1: Testable Permission Gate

**Files:**
- Create: `Demo/Demo/Other/Utils/TMEMicrophonePermissionGate.swift`
- Create: `scripts/tests/TMEMicrophonePermissionGateTests.swift`

- [ ] **Step 1: Write a failing Foundation command-line test.** Use this complete harness for authorized, denied, duplicate, cancellation and retry behavior:

```swift
import Foundation

@main
struct TMEMicrophonePermissionGateTests {
    static func main() {
        var requests = 0
        let granted = TMEMicrophonePermissionGate(status: { .granted },
                                                  request: { _ in requests += 1 })
        var grantedResults = [Bool]()
        granted.authorize { grantedResults.append($0) }
        precondition(grantedResults == [true] && requests == 0)

        let denied = TMEMicrophonePermissionGate(status: { .denied },
                                                 request: { _ in requests += 1 })
        var deniedResults = [Bool]()
        denied.authorize { deniedResults.append($0) }
        precondition(deniedResults == [false] && requests == 0)

        var callback: ((Bool) -> Void)?
        let pending = TMEMicrophonePermissionGate(status: { .undetermined },
            request: { completion in requests += 1; callback = completion })
        var pendingResults = [Bool]()
        pending.authorize { pendingResults.append($0) }
        pending.authorize { _ in preconditionFailure("duplicate request") }
        precondition(requests == 1)
        let oldCallback = callback!
        pending.cancel()
        pending.authorize {
            precondition(Thread.isMainThread)
            pendingResults.append($0)
        }
        precondition(requests == 2)
        oldCallback(true)
        RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        precondition(pendingResults.isEmpty)
        callback?(false)
        RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        precondition(pendingResults == [false])
        print("TMEMicrophonePermissionGateTests passed")
    }
}
```

- [ ] **Step 2: Verify RED.** Run `swiftc -module-cache-path /private/tmp/kl-tme-module-cache -o /private/tmp/tme-microphone-gate-test Demo/Demo/Other/Utils/TMEMicrophonePermissionGate.swift scripts/tests/TMEMicrophonePermissionGateTests.swift`. It must fail because the gate source does not exist. After creating the empty production file, the same command must fail because the requested API is undefined.

- [ ] **Step 3: Implement the gate.** Keep state on main and accept only one pending request; dispatch the system callback to main before touching state. Use a generation that `cancel()` increments so old callbacks cannot authorize a later request:

```swift
import Foundation

final class TMEMicrophonePermissionGate {
    enum Status { case granted, undetermined, denied }
    private let status: () -> Status
    private let request: (@escaping (Bool) -> Void) -> Void
    private var generation = 0
    private var awaiting = false

    init(status: @escaping () -> Status,
         request: @escaping (@escaping (Bool) -> Void) -> Void) {
        self.status = status
        self.request = request
    }

    func authorize(_ completion: @escaping (Bool) -> Void) {
        precondition(Thread.isMainThread)
        guard !awaiting else { return }
        switch status() {
        case .granted: completion(true)
        case .denied: completion(false)
        case .undetermined:
            awaiting = true
            let current = generation
            request { [weak self] allowed in
                DispatchQueue.main.async {
                    guard let self = self, self.generation == current,
                          self.awaiting else { return }
                    self.awaiting = false
                    completion(allowed)
                }
            }
        }
    }

    func cancel() {
        precondition(Thread.isMainThread)
        generation += 1
        awaiting = false
    }
}
```

- [ ] **Step 4: Verify GREEN.** Re-run the Step 2 compile command followed by `/private/tmp/tme-microphone-gate-test`. Confirm granted, denied, duplicate, cancelled and retry cases all pass.

### Task 2: Connect TME Startup and Permission Copy

**Files:**
- Modify: `Demo/Demo/Other/Utils/TmeManager.swift`
- Modify: `Demo/Demo.xcodeproj/project.pbxproj`
- Modify: `scripts/tests/tme_sdk_flow.sh`

- [ ] **Step 1: Add failing integration assertions.** After the current `rg` checks in `scripts/tests/tme_sdk_flow.sh`, assert registration of `TMEMicrophonePermissionGate.swift`, AVAudioSession status/request handling, stop cancellation, a denial hint, and two microphone purpose descriptions. Run `bash scripts/tests/tme_sdk_flow.sh` and confirm it fails at the new assertion:

```bash
rg -q 'TMEMicrophonePermissionGate.swift in Sources' Demo/Demo.xcodeproj/project.pbxproj
rg -q 'recordPermission' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'requestRecordPermission' Demo/Demo/Other/Utils/TmeManager.swift
rg -q 'microphonePermission.cancel()' Demo/Demo/Other/Utils/TmeManager.swift
rg -q '请在系统设置中允许麦克风权限后重试' Demo/Demo/Other/Utils/TmeManager.swift
test "$(rg -c 'INFOPLIST_KEY_NSMicrophoneUsageDescription = "允许录音以检测演唱音高并计算得分";' Demo/Demo.xcodeproj/project.pbxproj)" -eq 2
```

- [ ] **Step 2: Wire permission before RTC creation.** Add `import AVFoundation` and a lazy injected gate in `TmeManager`. Move only the current RTC setup statements from after `if rtc != nil { stop() }` into `private func startRtc()`; leave config validation and existing-MCC refresh in `start()`. Preserve a retryable `rtc != nil` teardown inside `startRtc()`. Pass the gate completion through a weak capture:

```swift
private lazy var microphonePermission = TMEMicrophonePermissionGate(
    status: {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted: return .granted
        case .denied: return .denied
        case .undetermined: return .undetermined
        @unknown default: return .denied
        }
    },
    request: { completion in
        AVAudioSession.sharedInstance().requestRecordPermission(completion)
    }
)

// At the end of start(), after configuration and existing-MCC checks:
microphonePermission.authorize { [weak self] allowed in
    guard let self = self else { return }
    guard allowed else {
        self.fail("请在系统设置中允许麦克风权限后重试")
        return
    }
    self.startRtc()
}

// First statement in stop(), before the existing early return:
microphonePermission.cancel()
```

  Register the source once in the PBXBuildFile, PBXFileReference, Utils group, and Demo Sources sections using a fresh pair of IDs adjacent to `TMEPlaybackGate.swift`. Change both `INFOPLIST_KEY_NSMicrophoneUsageDescription` values to `允许录音以检测演唱音高并计算得分`.

- [ ] **Step 3: Verify GREEN and build.** Run `bash scripts/tests/tme_sdk_flow.sh`, `/private/tmp/tme-microphone-gate-test`, `git diff --check`, then `xcodebuild -quiet -workspace Demo/Demo.xcworkspace -scheme Demo -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/kl-tme-demo-scoring-derived CODE_SIGNING_ALLOWED=NO build`. If sandboxing prevents CoreSimulatorService access, retry xcodebuild with required escalation.

### Task 3: Simulator Permission Check

**Files:** No repository edits.

- [ ] **Step 1: Install and launch the newly built Demo on the already available iPhone 14 simulator** (`886F78E2-A8B3-4C33-884B-874878DDBCF4`). Use `xcrun simctl install` and `launch` for bundle `io.agora.test.entfull`. Do not pre-grant permission with `simctl privacy grant` or wipe unrelated simulator data.
- [ ] **Step 2: Open the TME page and inspect a screenshot.** On an undecided permission state, verify the OS microphone dialog appears. Test denial only through the dialog if it does not interfere with a previously authorized device; verify the hint and that no RTC list loads. For approval, let the user choose Allow in the system dialog, reopen/retry the TME page, and verify the list loads. If permission is already decided, use a fresh simulator device only with explicit consent before creating/changing that device; otherwise report the missing manual scenario honestly.
- [ ] **Step 3: Final verification.** Re-run the Swift gate test, TME integration script, simulator build and `git diff --check`. Inspect `git status --short` and preserve pre-existing dirty files. The log should no longer report an undetermined record permission during an authorized TME session. Report separately that a nonzero score requires live mic input and is not guaranteed by permission alone.
