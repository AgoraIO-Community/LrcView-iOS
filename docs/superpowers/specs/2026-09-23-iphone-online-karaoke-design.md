# iPhone Online Karaoke Demo Design

## Objective

Turn the existing UIKit test demo into an internal iPhone application for single-user online karaoke. The application must install and run on a physical iPhone, use Agora Music Content Center for the existing five-song catalog, display synchronized lyrics, collect local microphone pitch, and calculate real-time singing scores with `AgoraLyricsScore`.

This is an internal demonstration application, not an App Store production release. It may generate Agora tokens on the device from an App Certificate. The UI must still avoid logging or committing the certificate.

## Scope

The application provides three user-facing flows:

1. Enter and persist Agora credentials.
2. Choose one of the five songs already defined by the demo.
3. Sing with online accompaniment, synchronized lyrics, pitch guidance, and scoring.

The first version does not include online search, music charts, rooms, audience or host roles, multi-user singing, queue management, or the existing component test screens.

## Platform And Dependencies

- UIKit application supporting iOS 13 and later.
- iPhone target only, with portrait as the primary orientation.
- Existing local `AgoraLyricsScore` CocoaPod and its `Zip` and `AgoraComponetLog` dependencies.
- Agora RTC SDK for microphone audio and local pitch callbacks.
- `RTMTokenBuilder` for local Music Content Center token generation.
- Agora's official C++ AccessToken2 (007) `AccessToken2` and `RtcTokenBuilder2` sources, pinned to a reviewed commit and exposed to Swift through a minimal Objective-C++ wrapper, for certificate-enabled RTC channel access.

Remove the non-portable `AgoraMccExService` and `ScoreEffectUI` dependencies, both of which currently reference developer-specific filesystem paths. Remove `SVProgressHUD` and replace its uses with UIKit-owned loading and error states. Remove the screens and source references that exist only for component, Ex-service, host, audience, and multi-user testing.

Xcode uses Automatic Signing. The repository must not pin a personal Development Team. The developer selects an available team locally before installing on an iPhone.

## Architecture

### Application Screens

`ConfigurationViewController` owns credential entry. It validates an App ID and App Certificate, stores them through `CredentialsStore`, and proceeds to the song list. The certificate field is obscured by default and has a visibility toggle.

`SongListViewController` displays the fixed catalog and provides access to credential settings. It redirects to configuration when no valid credentials exist.

`KaraokeViewController` owns presentation for a single singing session. It observes `KaraokeSession`, maps session states to loading, playback, and error UI, and forwards user controls without directly owning Agora SDK objects.

### Services

`CredentialsStore` is the only component that reads and writes Agora credentials. Its production implementation uses Keychain. It supports load, save, overwrite, and clear operations and never prints credential values.

`TokenProvider` validates credentials and creates the short-lived RTC and Music Content Center tokens required for a session. The RTC channel name and random session user ID are inputs so that the token matches the actual join request. RTC token generation calls the vendored official C++ AccessToken2 implementation through Objective-C++; Music Content Center token generation continues to use the demo's existing `RTMTokenBuilder.buildRtmToken2` path. The vendored source retains its upstream license and commit reference.

`SongCatalog` exposes the five existing songs as immutable application data:

- 十年
- 爱情转移
- 说爱你
- 江南
- 容易受伤的女人

The existing Music Content Center song IDs remain unchanged. The catalog interface allows a future remote implementation without coupling it to view controllers.

`KaraokeSession` owns RTC Engine, Music Content Center, music player, lyric download, progress updates, and cleanup. It exposes the following state machine:

`idle -> preparing -> ready -> playing <-> paused -> finished`

Any active state may transition to `error` or back to `idle` during cleanup. Cleanup is idempotent and always stops playback, unregisters callbacks, leaves the RTC channel, and releases session resources before a retry, song change, or page exit.

SDK-facing behavior is hidden behind protocols. Tests use fake implementations and do not require Agora network access.

## User Experience

### Configuration

On first launch, the application presents App ID and App Certificate fields. Tapping Save and Continue checks for missing or malformed values before writing to Keychain. A successful save opens the song list. Returning users skip this page. The song list has a settings action for replacing or clearing credentials.

The screen states clearly that local certificate storage and token generation are intended only for internal demonstration builds.

### Song List

The song list uses a compact native list. Each row contains the song name and a disclosure indicator. Selecting a row opens the karaoke screen and starts preparation. No background preload occurs before selection.

### Karaoke Screen

The portrait layout contains:

- A top bar with Back, song title, and original/accompaniment toggle.
- A primary area for pitch tracks, the live pitch cursor, and word-synchronized lyrics.
- A scoring area for current-line feedback and cumulative score.
- Bottom controls for Skip Prelude, Pause/Resume, and Next Song.

The screen respects iPhone safe areas and common compact and large screen sizes. Existing debug consoles, parameter controls, test menus, and test-style red buttons are not present.

Preparation uses a blocking in-screen loading state. Recoverable failures show Retry and Back to Songs. The UI uses native activity indicators and alerts or inline error views instead of a third-party HUD.

## Session Data Flow

1. Read the shared App ID and App Certificate from Keychain.
2. Create a random user ID and an ephemeral channel name for the session.
3. Generate matching RTC and Music Content Center tokens locally with bounded expiration.
4. Request microphone permission, initialize RTC, and join the temporary channel.
5. Initialize Music Content Center and preload the selected song.
6. Request the lyric URL, download the lyric archive, and parse it into `LyricModel`.
7. Open and play the song after both playback and lyric prerequisites are ready.
8. Feed music-player position into `KaraokeView` for synchronized rendering.
9. Feed local RTC pitch callbacks into `KaraokeView` for real-time scoring.
10. Update current-line and cumulative score from `KaraokeDelegate` callbacks.
11. On completion or exit, clean up the session before navigating or starting another song.

RTC and Music Content Center use the same App ID and App Certificate. Credential values and generated tokens must not appear in logs, assertions, analytics, or user-facing errors.

## Permissions And Error Handling

The application includes a microphone usage description. It requests microphone access immediately before the first singing session. A denial prevents session startup and presents an action that opens the application settings page.

Errors are normalized into six user-facing categories:

- Invalid or rejected credentials: explain the configuration problem and return to settings.
- Microphone permission denied: explain why access is required and offer system settings.
- Network unavailable or interrupted: preserve song selection and offer retry.
- Song unavailable, unauthorized, or removed: return to the song list after acknowledgement.
- Lyric download or parsing failure: offer retry and allow return to the list.
- Player or SDK failure: show a concise message containing a non-sensitive diagnostic code and offer retry.

Retries always clean up the previous session first. SDK error codes are retained in internal logs, but secrets and tokens are redacted.

## Testing

Add an application unit-test target covering:

- Keychain save, load, overwrite, and clear behavior.
- Credential validation and deterministic token generation using fixed test inputs.
- All valid `KaraokeSession` state transitions, rejected invalid transitions, and repeated cleanup.
- Fixed catalog content and next-song ordering.
- Mapping Agora, download, parser, and player errors to user-facing categories.

Protocol-backed fakes cover SDK interactions without network access. Existing `AgoraLyricsScore` parser and downloader tests remain available and are not duplicated in the application target.

## Acceptance Criteria

- Debug and Release configurations compile without developer-specific absolute dependency paths.
- The app installs and launches on a physical iPhone running iOS 13 or later after selecting an Apple Development Team.
- First launch requires Agora credentials; valid saved credentials survive an app restart.
- All five songs can initiate loading, and at least one licensed song completes an end-to-end physical-device test.
- Playback displays synchronized lyrics and live pitch scoring from the iPhone microphone.
- Skip Prelude, Pause/Resume, original/accompaniment switching, Next Song, and Back all work.
- Microphone denial, network loss, credential rejection, unavailable songs, lyric failures, and player failures present recoverable UI where recovery is possible.
- Repeated entry, exit, song changes, and retries do not crash, overlap audio, or deliver duplicate callbacks.
- App ID, App Certificate, and generated tokens are absent from source control and runtime logs.

## Security Boundary

Generating tokens from an App Certificate on an iPhone exposes that certificate to a sufficiently motivated user. This design accepts that risk only because the requested deliverable is an internal demonstration build. A distributable or public release must replace `TokenProvider` with a backend token service and remove the App Certificate from the device.
