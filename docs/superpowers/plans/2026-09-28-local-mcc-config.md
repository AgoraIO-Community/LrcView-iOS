# Local MCC Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep internal Demo MCC credentials local and out of Git while compiling them into the iOS Demo.

**Architecture:** `Config.swift` keeps the SDK-facing property names and reads the two MCC values from a separate ignored `localConfig.swift`. The Xcode project explicitly compiles that local file. A tracked example documents the required shape without credentials; a small shell check protects the ignore and project wiring.

**Tech Stack:** Swift 5, Xcode project (OpenStep plist), shell, Git.

---

### Task 1: Verify the repository guard fails before the change

**Files:**
- Create: `scripts/tests/local_mcc_config.sh`

- [ ] **Step 1: Write the failing integration check**

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
git check-ignore -q Demo/Demo/localConfig.swift
if git ls-files --error-unmatch Demo/Demo/localConfig.swift >/dev/null 2>&1; then
    echo 'localConfig.swift is tracked by Git' >&2
    exit 1
fi
rg -q 'LocalMccConfig\.mccAppId' Demo/Demo/Config.swift
rg -q 'LocalMccConfig\.mccCertif' Demo/Demo/Config.swift
test "$(rg -c 'localConfig\.swift in Sources' Demo/Demo.xcodeproj/project.pbxproj)" -eq 2
swiftc -typecheck -module-cache-path /private/tmp/klyrics-local-mcc-config-cache Demo/Demo/localConfig.swift
plutil -lint Demo/Demo.xcodeproj/project.pbxproj
```

- [ ] **Step 2: Run `bash scripts/tests/local_mcc_config.sh`**

Expected: Nonzero exit because `localConfig.swift` is not yet ignored.

### Task 2: Wire the ignored credentials into the app

**Files:**
- Modify: `.gitignore`
- Modify: `Demo/Demo/Config.swift`
- Modify: `Demo/Demo.xcodeproj/project.pbxproj`
- Create (ignored): `Demo/Demo/localConfig.swift`
- Create: `Demo/Demo/localConfig.example.swift`

- [ ] **Step 1: Add `/Demo/Demo/localConfig.swift` to `.gitignore`**

- [ ] **Step 2: Create the local file with no real credentials**

```swift
import Foundation

enum LocalMccConfig {
    static let mccAppId = ""
    static let mccCertif = ""
}
```

- [ ] **Step 3: Create an identical `localConfig.example.swift`**

The example is tracked but is *not* added to Xcode's Sources. It must contain only the empty strings shown above.

- [ ] **Step 4: Replace only the two MCC properties in `Config.swift`**

```swift
static let mccAppId = LocalMccConfig.mccAppId
static let mccCertificate = LocalMccConfig.mccCertif
```

- [ ] **Step 5: Register `localConfig.swift` in `project.pbxproj`**

Add one `PBXFileReference` adjacent to `Config.swift`, one `PBXBuildFile` adjacent to `Config.swift in Sources`, one child in the `Demo` group, and one entry in the Demo `PBXSourcesBuildPhase`. Use new unique 24-digit hexadecimal identifiers. Do not register the example file.

- [ ] **Step 6: Run `bash scripts/tests/local_mcc_config.sh`**

Expected: Exit zero; `plutil` reports `OK` and Swift typechecking succeeds.

- [ ] **Step 7: Run `git status --short` and `git check-ignore -v Demo/Demo/localConfig.swift`**

Expected: `localConfig.swift` is omitted from status and mapped to the exact `.gitignore` rule; the template and tracked wiring are visible.

- [ ] **Step 8: Try the simulator build**

```bash
xcodebuild -project Demo/Demo.xcodeproj -scheme Demo -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/klyrics-local-mcc-config-derived CODE_SIGNING_ALLOWED=NO -quiet build
```

Expected in this checkout: fails at the missing `Pods-Demo.debug.xcconfig`, unrelated to the local Swift wiring. Do not alter missing external Pods or add credentials.
