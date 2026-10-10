# Shared TME karaoke UI implementation plan

> Execute inline in the user-selected LrcView-iOS workspace and preserve unrelated changes.

**Goal:** Use the built-in scoring presentation for the TME lyric and scoring components.

**Architecture:** Extract the existing MainView karaoke and score-effect subviews into a reusable KaraokePanelView. Both screens own this panel; playback remains in the respective controllers.

**Tech Stack:** Swift, UIKit, AgoraLyricsScore, ScoreEffectUI, Xcode.

- [x] Add Demo/Demo/View/KaraokePanelView.swift containing the existing MainView appearance and score overlays. Register it in Demo/Demo.xcodeproj/project.pbxproj.
- [x] Replace MainView's individual karaoke/score subviews with the panel, expose their original names as computed properties, and preserve all control and console constraints.
- [x] Use the panel in TmeSingingVC with the same 350pt height/full width. Keep status text scrollable below it and the playback button visible. Feed line score, cumulative grade and incentive callbacks into the shared score views; hide the panel on preparation fallback.
- [x] Update the existing scripts/tests/tme_sdk_flow.sh appearance check to expect the shared panel instead of the old TME lyric color override.
- [x] Run bash scripts/tests/tme_sdk_flow.sh and build Demo/Demo.xcworkspace with scheme Demo, Debug, generic iOS destination, CODE_SIGNING_ALLOWED=NO, and a dedicated derived data directory under /tmp.
- [x] Inspect the diff, verify compilation and report the scope and any device validation limits.

This reversible display change uses existing integration checks and a full build; no tests duplicating visual setters are added.

Validation: generic iOS Debug build succeeded in /tmp/lrcview-ios-tme-ui-build (unsigned); tme_sdk_flow.sh passed; project.pbxproj plist validation and git diff --check passed. Actual iPhone UI rendering has not been verified in this task.

Independent review identified the hidden panel retaining 350pt during loading/fallback. Fixed by collapsing the container height to zero and restoring 350pt before model installation, while keeping child geometry stable. Follow-up review found no remaining significant issues; the updated build and TME integration check passed again.
