# iOS Lyrics View with RTC Media

## Overview

Render synchronized lyrics in an iOS RTC audio experience for karaoke, music, or live media apps.

Repository: [AgoraIO-Community/LrcView-iOS](https://github.com/AgoraIO-Community/LrcView-iOS)

## Prerequisites and Setup

1. Use Xcode and CocoaPods. From `Demo/`, run `pod install` and open `Demo.xcworkspace`.
2. Inspect `Demo/Demo/Config.swift` and configure the music/RTC services used by the selected demo with your own credentials and compatible SDKs.
3. Load a supported XML/LRC/KRC lyric file and optional pitch data using the sample's KaraokeView flow.
4. Drive lyric progress from playback and provide pitch updates when scoring is enabled. Refer to the README and demo controllers for the chosen music-content integration.

## What To Check

- Verify highlighting and seek position follow playback.
- Check pitch/scoring output with suitable test assets and service entitlement.
- Switch songs and confirm the karaoke view resets.

## Integration Notes

This is a lyric/scoring component demo. It is not validated by showing a generic camera preview; music-content service setup and appropriate assets are required.

Keep App Certificates, customer secrets and privileged token generation on a trusted backend for production. Use only your own test credentials while configuring historical demos; do not commit them. Preserve the sample's existing dependency versions and lifecycle until a separate migration is tested.

## Source References

- [README.md](../../README.md)
- [Demo/Podfile](../../Demo/Podfile)
- [Demo/Demo/Config.swift](../../Demo/Demo/Config.swift)

## Validation Status

This recipe was checked against the repository's source and setup documents. The platform build and live service/device flow have not been run as part of this documentation change. Complete the checks above in an environment with the required SDKs, hardware and service access before treating it as a validated deployment.

## Implementation Prompt

```text
You are working in AgoraIO-Community/LrcView-iOS. Use docs/ai/RECIPE.md and its linked source files to adapt the iOS Lyrics View with RTC Media reference to this project.

Start by inspecting the actual sample directory and configuration described above. Resolve its listed missing prerequisites before claiming it is runnable. Preserve the existing architecture and compatible dependency versions. Implement the recipe's feature-specific flow, permissions and resource cleanup. Use a trusted backend for privileged credentials and tokens in production.

Run the repository-specific build or launch flow, then perform each What To Check item. Report the commands run, the observed results and anything blocked by service access, hardware or incomplete sample code. Do not claim live validation from a documentation or catalog build alone.
```
