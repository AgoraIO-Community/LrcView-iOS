# Restore Legacy Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the legacy iOS Demo by reverting the online karaoke feature merge without rewriting `develop` history.

**Architecture:** Git will invert merge commit `abd7a04` relative to its first parent, leaving the upstream `2.1.7-beta-3` merge and later restoration documentation intact. Verification compares the restored feature scope against first parent `2d3a1f6`; dependency installation and simulator execution are attempted separately because the legacy Podfile intentionally contains machine-local dependencies.

**Tech Stack:** Git, CocoaPods, Xcode 14.1, iOS 16.1 Simulator

---

### Task 1: Revert the online karaoke merge

**Files:**
- Restore through Git: `Demo/**`, `README.md`, `Vendor/RTMTokenBuilder-1.0.2/**`, `scripts/configure_iphone_demo_project.rb`

- [ ] **Step 1: Confirm the worktree is clean and the target merge exists**

Run:

```bash
git status --short
git show --no-patch --format='%H %P %s' abd7a04
```

Expected: no status output; `abd7a04` has first parent `2d3a1f6` and subject `Merge branch 'feature/iphone-online-karaoke' into develop`.

- [ ] **Step 2: Create the restoration commit**

Run:

```bash
git revert -m 1 --no-edit abd7a04
```

Expected: a new `Revert "Merge branch 'feature/iphone-online-karaoke' into develop"` commit with no conflicts.

- [ ] **Step 3: Verify the restored feature scope**

Run:

```bash
git diff --exit-code 2d3a1f6 HEAD -- Demo README.md Vendor scripts
test ! -d Demo/Demo/App
```

Expected: no diff in the feature scope and exit status `0`; the online karaoke `Demo/Demo/App` directory is absent.

### Task 2: Restore dependencies and assess buildability

**Files:**
- Generated locally: `Demo/Demo.xcworkspace/**`, `Demo/Pods/**`, `Demo/Podfile.lock`
- Read: `Demo/Podfile`

- [ ] **Step 1: Install the legacy dependencies**

Run from `Demo/`:

```bash
pod install
```

Expected when the original machine-local dependencies exist: installation succeeds. On this machine, an error resolving `/Volumes/T5/PodSpec/AgoraMccExService/AgoraMccExService.podspec` or `~/work/DevHistoryProject/ScoreEffectUI/ScoreEffectUI.podspec` is an expected legacy-environment blocker and must be reported without editing the restored Podfile.

- [ ] **Step 2: Build only if dependency installation succeeds**

Run:

```bash
xcodebuild build -quiet -workspace Demo.xcworkspace -scheme Demo -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 14' -derivedDataPath /tmp/kllyrics-legacy-derived-data
```

Expected: build succeeds when local Pods and the values in `Demo/Demo/Config.swift` are supplied. If the untouched `<#...#>` placeholders stop compilation, report that original configuration requirement without replacing them.

### Task 3: Launch the restored Demo when buildable

**Files:**
- Generated screenshot: `/tmp/kllyrics-legacy-demo-simulator.png`

- [ ] **Step 1: Install and launch the built app**

Run after a successful build:

```bash
xcrun simctl install booted /tmp/kllyrics-legacy-derived-data/Build/Products/Debug-iphonesimulator/Demo.app
xcrun simctl launch --terminate-running-process booted io.agora.test.entfull
```

Expected: the legacy Demo process launches with bundle identifier `io.agora.test.entfull`.

- [ ] **Step 2: Capture the legacy interface**

Run:

```bash
xcrun simctl io booted screenshot /tmp/kllyrics-legacy-demo-simulator.png
```

Expected: the screenshot shows the legacy Demo rather than the `Agora 配置` screen. Skip this task and report the dependency/configuration blocker if Task 2 cannot produce an app.

### Task 4: Final integrity check

**Files:**
- Verify: repository state only

- [ ] **Step 1: Confirm history and status**

Run:

```bash
git status --short --branch
git log -3 --oneline --decorate
git diff-tree --check HEAD
```

Expected: the source worktree is clean, the restoration commit is at `HEAD`, and the commit contains no whitespace errors. Ignored CocoaPods products may remain locally.
