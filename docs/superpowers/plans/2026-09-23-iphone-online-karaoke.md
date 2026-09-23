# iPhone Online Karaoke Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the test-menu Demo target with an internal, portrait iPhone app that stores Agora credentials in Keychain, offers the existing five-song catalog, and runs a single-user online karaoke session with synchronized lyrics and scoring.

**Architecture:** Keep the UIKit/CocoaPods project and local `AgoraLyricsScore` pod, but compile only a new `Demo/Demo/App` application layer. An `AppCoordinator` owns the three-screen flow, while `KaraokeSession` owns state and delegates SDK work to `AgoraKaraokeClient`; credentials, token generation, permissions, and song data remain independently testable.

**Tech Stack:** Swift 5, UIKit, XCTest, Security/Keychain, AVFoundation, Agora RTC 4.1.1.24, Agora Music Content Center, `RTMTokenBuilder` 1.0.2, local `AgoraLyricsScore`, CocoaPods, Ruby `xcodeproj`.

---

## File Map

- `Demo/Demo/App/AppCoordinator.swift`: composition root and navigation.
- `Demo/Demo/App/Credentials/AgoraCredentials.swift`: credential value and validation.
- `Demo/Demo/App/Credentials/CredentialsStore.swift`: Keychain persistence boundary.
- `Demo/Demo/App/Credentials/ConfigurationViewController.swift`: credential form.
- `Demo/Demo/App/Songs/Song.swift`: song value type and fixed catalog.
- `Demo/Demo/App/Songs/SongListViewController.swift`: five-song selection UI.
- `Demo/Demo/App/Session/TokenProvider.swift`: local RTC and MCC AccessToken2 creation.
- `Demo/Demo/App/Session/KaraokeError.swift`: normalized user-facing failures.
- `Demo/Demo/App/Session/KaraokeSession.swift`: state machine and SDK-independent orchestration.
- `Demo/Demo/App/Session/AgoraKaraokeClient.swift`: RTC, MCC, lyric downloader, player, and timer adapter.
- `Demo/Demo/App/Karaoke/KaraokeContentView.swift`: karaoke layout and controls.
- `Demo/Demo/App/Karaoke/KaraokeViewController.swift`: session-to-view binding.
- `Demo/Demo/App/Permissions/MicrophonePermissionProvider.swift`: AVAudioSession permission adapter.
- `Demo/DemoTests/*.swift`: focused unit tests for each boundary.
- `scripts/configure_iphone_demo_project.rb`: reproducible app/test target membership and build settings.

### Task 1: Create A Portable App And Test Harness

**Files:**
- Modify: `Demo/Podfile`
- Modify: `Demo/Demo/AppDelegate.swift`
- Modify: `Demo/Demo/SceneDelegate.swift`
- Modify: `Demo/Demo/Info.plist`
- Create: `Demo/Demo/App/AppCoordinator.swift`
- Create: `Demo/DemoTests/ProjectSmokeTests.swift`
- Create: `scripts/configure_iphone_demo_project.rb`
- Modify (generated): `Demo/Demo.xcodeproj/project.pbxproj`
- Modify (generated): `Demo/Demo.xcodeproj/xcshareddata/xcschemes/Demo.xcscheme`

- [ ] **Step 1: Replace non-portable Pod dependencies**

Use this complete `Demo/Podfile`:

```ruby
platform :ios, '13.0'

source 'https://github.com/CocoaPods/Specs.git'

target 'Demo' do
  use_frameworks!

  pod 'AgoraLyricsScore', :path => '../AgoraLyricsScore.podspec'
  pod 'RTMTokenBuilder', '1.0.2'
  pod 'AgoraRtcEngine_Special_iOS', '4.1.1.24'

  target 'DemoTests' do
    inherit! :search_paths
  end
end
```

- [ ] **Step 2: Add a minimal programmatic app root**

Replace `AppDelegate.swift` with an `@main` delegate that only returns `true`. Replace `SceneDelegate.scene(_:willConnectTo:options:)` with:

```swift
guard let windowScene = scene as? UIWindowScene else { return }
let coordinator = AppCoordinator()
let window = UIWindow(windowScene: windowScene)
window.rootViewController = coordinator.navigationController
self.window = window
self.coordinator = coordinator
window.makeKeyAndVisible()
coordinator.start()
```

Add `private var coordinator: AppCoordinator?` and create the first compiling coordinator:

```swift
import UIKit

final class AppCoordinator {
    let navigationController = UINavigationController()

    func start() {
        let root = UIViewController()
        root.title = "K 歌"
        root.view.backgroundColor = .systemBackground
        navigationController.setViewControllers([root], animated: false)
    }
}
```

Remove `UISceneStoryboardFile` from `Info.plist`. Keep the scene delegate entry and add:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要使用麦克风检测演唱音高并计算得分。</string>
```

- [ ] **Step 3: Create the project configuration script**

Create this complete `scripts/configure_iphone_demo_project.rb` so project membership and settings are repeatable:

```ruby
#!/usr/bin/env ruby
require 'pathname'
require 'xcodeproj'

root = Pathname.new(File.expand_path('..', __dir__))
project_path = root.join('Demo/Demo.xcodeproj')
project = Xcodeproj::Project.open(project_path.to_s)
app = project.targets.find { |target| target.name == 'Demo' }
abort('Demo target not found') unless app
tests = project.targets.find { |target| target.name == 'DemoTests' }
tests ||= project.new_target(:unit_test_bundle, 'DemoTests', :ios, '13.0')
tests.add_dependency(app) unless tests.dependencies.any? { |dependency| dependency.target == app }

demo_group = project.main_group.groups.fetch { |group| group.display_name == 'Demo' }
app_group = demo_group.groups.find { |group| group.display_name == 'App' }
app_group ||= demo_group.new_group('App', 'App')
tests_group = project.main_group.groups.find { |group| group.display_name == 'DemoTests' }
tests_group ||= project.main_group.new_group('DemoTests', 'DemoTests')

def ensure_reference(group, path)
  group.files.find { |reference| reference.path == path } || group.new_file(path)
end

app_references = [
  ensure_reference(demo_group, 'AppDelegate.swift'),
  ensure_reference(demo_group, 'SceneDelegate.swift')
]
app_root = root.join('Demo/Demo/App')
Dir.glob(app_root.join('**/*.{swift,m,mm,c,cpp}').to_s).sort.each do |path|
  relative = Pathname.new(path).relative_path_from(app_root).to_s
  app_references << ensure_reference(app_group, relative)
end

test_root = root.join('Demo/DemoTests')
test_references = Dir.glob(test_root.join('**/*.swift').to_s).sort.map do |path|
  relative = Pathname.new(path).relative_path_from(test_root).to_s
  ensure_reference(tests_group, relative)
end

app.source_build_phase.files.each(&:remove_from_project)
tests.source_build_phase.files.each(&:remove_from_project)
app.add_file_references(app_references)
tests.add_file_references(test_references)

allowed_resources = ['Assets.xcassets', 'LaunchScreen.storyboard']
app.resources_build_phase.files.each do |build_file|
  build_file.remove_from_project unless allowed_resources.include?(build_file.file_ref.display_name)
end

app.build_configurations.each do |config|
  settings = config.build_settings
  settings.delete('DEVELOPMENT_TEAM')
  settings.delete('INFOPLIST_KEY_UIMainStoryboardFile')
  settings.delete('INFOPLIST_KEY_NSCameraUsageDescription')
  settings.delete('SWIFT_OBJC_BRIDGING_HEADER')
  settings['CODE_SIGN_STYLE'] = 'Automatic'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  settings['TARGETED_DEVICE_FAMILY'] = '1'
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'io.agora.KLyricsDemo'
  settings['INFOPLIST_KEY_NSMicrophoneUsageDescription'] = '需要使用麦克风检测演唱音高并计算得分。'
  settings['INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone'] = 'UIInterfaceOrientationPortrait'
end

tests.build_configurations.each do |config|
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'io.agora.KLyricsDemoTests'
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/Demo.app/Demo'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
end

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(tests)
scheme.set_launch_target(app)
scheme.save_as(project_path.to_s, 'Demo', true)
project.save
```

- [ ] **Step 4: Add and run the smoke test**

```swift
import XCTest
@testable import Demo

final class ProjectSmokeTests: XCTestCase {
    func testAppCoordinatorCreatesNavigationController() {
        XCTAssertTrue(AppCoordinator().navigationController.viewControllers.isEmpty)
    }
}
```

Run:

```bash
ruby scripts/configure_iphone_demo_project.rb
cd Demo && pod install --repo-update
xcodebuild test -workspace Demo.xcworkspace -scheme Demo \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -only-testing:DemoTests/ProjectSmokeTests CODE_SIGNING_ALLOWED=NO
```

Expected: one passing test and no reference to `/Volumes/T5` or `~/work/DevHistoryProject`.

- [ ] **Step 5: Commit**

```bash
git add Demo/Podfile Demo/Demo.xcodeproj Demo/Demo.xcworkspace Demo/Demo/AppDelegate.swift \
  Demo/Demo/SceneDelegate.swift Demo/Demo/Info.plist Demo/Demo/App \
  Demo/DemoTests scripts/configure_iphone_demo_project.rb
git commit -m "build: create portable iPhone demo target"
```

### Task 2: Define Credentials And The Fixed Song Catalog

**Files:**
- Create: `Demo/Demo/App/Credentials/AgoraCredentials.swift`
- Create: `Demo/Demo/App/Songs/Song.swift`
- Create: `Demo/DemoTests/AgoraCredentialsTests.swift`
- Create: `Demo/DemoTests/SongCatalogTests.swift`

- [ ] **Step 1: Write failing domain tests**

```swift
func testCredentialsTrimAndAcceptThirtyTwoHexCharacters() throws {
    let value = try AgoraCredentials(
        appId: " 0123456789abcdef0123456789abcdef ",
        appCertificate: "fedcba9876543210fedcba9876543210"
    )
    XCTAssertEqual(value.appId, "0123456789abcdef0123456789abcdef")
}

func testCredentialsRejectMalformedValues() {
    XCTAssertThrowsError(try AgoraCredentials(appId: "short", appCertificate: "also-short"))
}

func testCatalogContainsTheApprovedFiveSongsInOrder() {
    XCTAssertEqual(SongCatalog.songs.map(\.name), ["十年", "爱情转移", "说爱你", "江南", "容易受伤的女人"])
    XCTAssertEqual(SongCatalog.next(after: SongCatalog.songs[4]), SongCatalog.songs[0])
}
```

- [ ] **Step 2: Run tests and verify failure**

Run the two test classes. Expected: compile failure because `AgoraCredentials` and `SongCatalog` do not exist.

- [ ] **Step 3: Implement the value types**

`AgoraCredentials` is `Codable, Equatable`, trims whitespace, and accepts only exactly 32 ASCII hexadecimal characters for both values. Throw `CredentialValidationError.invalidAppId` or `.invalidCertificate`.

```swift
struct Song: Equatable {
    let name: String
    let id: Int
}

enum SongCatalog {
    static let songs = [
        Song(name: "十年", id: 6625526605291650),
        Song(name: "爱情转移", id: 6246262727282860),
        Song(name: "说爱你", id: 6654550221757560),
        Song(name: "江南", id: 6246262727300580),
        Song(name: "容易受伤的女人", id: 6625526608670440)
    ]

    static func next(after song: Song) -> Song {
        guard let index = songs.firstIndex(of: song) else { return songs[0] }
        return songs[(index + 1) % songs.count]
    }
}
```

- [ ] **Step 4: Run tests and commit**

Expected: both test classes pass.

```bash
git add Demo/Demo/App/Credentials Demo/Demo/App/Songs Demo/DemoTests Demo/Demo.xcodeproj
git commit -m "feat: add Agora credentials and fixed song catalog"
```

### Task 3: Persist Credentials In Keychain

**Files:**
- Create: `Demo/Demo/App/Credentials/CredentialsStore.swift`
- Create: `Demo/DemoTests/CredentialsStoreTests.swift`

- [ ] **Step 1: Write failing Keychain tests**

Create a unique service per test with `"io.agora.KLyricsDemoTests.\(UUID().uuidString)"`. Test `load()` is initially nil, `save` then `load` round-trips, a second save overwrites, and `clear` returns to nil.

```swift
func testSaveOverwriteAndClear() throws {
    let store = KeychainCredentialsStore(service: service)
    let first = try AgoraCredentials(appId: validA, appCertificate: validB)
    let second = try AgoraCredentials(appId: validB, appCertificate: validA)
    try store.save(first)
    XCTAssertEqual(try store.load(), first)
    try store.save(second)
    XCTAssertEqual(try store.load(), second)
    try store.clear()
    XCTAssertNil(try store.load())
}
```

- [ ] **Step 2: Verify the test fails**

Expected: compile failure for missing `KeychainCredentialsStore`.

- [ ] **Step 3: Implement the store**

Define:

```swift
protocol CredentialsStoring {
    func load() throws -> AgoraCredentials?
    func save(_ credentials: AgoraCredentials) throws
    func clear() throws
}
```

`KeychainCredentialsStore` imports `Security`, JSON-encodes the single credentials value, and uses one generic-password record with `kSecClassGenericPassword`, the injected service, and account `"agora-credentials"`. `save` deletes the existing record before `SecItemAdd`; treat `errSecSuccess` and `errSecItemNotFound` as successful deletion. Throw `KeychainStoreError.unexpectedStatus(OSStatus)` for any other result. Never log the payload.

- [ ] **Step 4: Run tests and commit**

Expected: all four persistence assertions pass on the simulator.

```bash
git add Demo/Demo/App/Credentials/CredentialsStore.swift Demo/DemoTests/CredentialsStoreTests.swift Demo/Demo.xcodeproj
git commit -m "feat: store Agora credentials in Keychain"
```

### Task 4: Generate RTC And Music Content Center Tokens

**Files:**
- Create: `Demo/Demo/App/Session/TokenProvider.swift`
- Create: `Demo/DemoTests/TokenProviderTests.swift`

- [ ] **Step 1: Write failing token tests**

Inject deterministic UID and channel closures, then assert both tokens use AccessToken2 and bind the generated session identity:

```swift
func testCreatesRtcAndMccAccessToken2Values() throws {
    let provider = LocalTokenProvider(uid: { 1234 }, channel: { "kl-test-channel" })
    let access = try provider.makeAccess(credentials: validCredentials)
    XCTAssertEqual(access.uid, 1234)
    XCTAssertEqual(access.channelName, "kl-test-channel")
    XCTAssertTrue(access.rtcToken.hasPrefix("007"))
    XCTAssertTrue(access.mccToken.hasPrefix("007"))
    XCTAssertNotEqual(access.rtcToken, access.mccToken)
}
```

Also inject UID `0` and an empty channel in separate tests and assert `TokenProviderError.invalidSessionIdentity` is thrown before either builder is called.

- [ ] **Step 2: Verify failure**

Expected: compile failure for missing `LocalTokenProvider`.

- [ ] **Step 3: Implement token generation**

```swift
import RTMTokenBuilder

struct KaraokeAccess: Equatable {
    let uid: UInt
    let channelName: String
    let rtcToken: String
    let mccToken: String
}

protocol TokenProviding {
    func makeAccess(credentials: AgoraCredentials) throws -> KaraokeAccess
}

enum TokenProviderError: Error, Equatable {
    case invalidSessionIdentity
    case generationFailed
}

final class LocalTokenProvider: TokenProviding {
    private let uid: () -> UInt
    private let channel: () -> String

    init(uid: @escaping () -> UInt = { UInt.random(in: 1...UInt(Int32.max)) },
         channel: @escaping () -> String = { "kl-" + UUID().uuidString.replacingOccurrences(of: "-", with: "") }) {
        self.uid = uid
        self.channel = channel
    }

    func makeAccess(credentials: AgoraCredentials) throws -> KaraokeAccess {
        let value = uid()
        let name = channel()
        guard value > 0, value <= UInt(Int32.max), !name.isEmpty, name.utf8.count < 64 else {
            throw TokenProviderError.invalidSessionIdentity
        }
        let rtc = TokenBuilder.rtcToken2(credentials.appId,
                                         appCertificate: credentials.appCertificate,
                                         uid: Int32(value),
                                         channelName: name)
        let mcc = TokenBuilder.buildRtmToken2(credentials.appId,
                                              appCertificate: credentials.appCertificate,
                                              userUuid: String(value))
        guard rtc.hasPrefix("007"), mcc.hasPrefix("007") else {
            throw TokenProviderError.generationFailed
        }
        return KaraokeAccess(uid: value, channelName: name, rtcToken: rtc, mccToken: mcc)
    }
}
```

- [ ] **Step 4: Run tests and commit**

Expected: token tests pass without printing either token.

```bash
git add Demo/Demo/App/Session/TokenProvider.swift Demo/DemoTests/TokenProviderTests.swift Demo/Demo.xcodeproj
git commit -m "feat: generate local Agora session tokens"
```

### Task 5: Build The Karaoke Session State Machine

**Files:**
- Create: `Demo/Demo/App/Session/KaraokeError.swift`
- Create: `Demo/Demo/App/Session/KaraokeSession.swift`
- Create: `Demo/DemoTests/KaraokeSessionTests.swift`
- Create: `Demo/DemoTests/KaraokeErrorTests.swift`

- [ ] **Step 1: Write failing state and error tests**

Use `FakeKaraokeClient` and `FakeTokenProvider` to prove:

```swift
session.start(song: song, credentials: credentials) // idle -> preparing
client.emitLyrics(model)                            // forwards model, preparing -> ready
client.emitStarted()                                // ready -> playing
session.pause()                                     // playing -> paused
session.resume()                                    // paused -> playing
session.stop()                                      // -> idle and exactly one cleanup
session.stop()                                      // still idle, no second cleanup
```

Also assert `.credentials`, `.microphoneDenied`, `.network`, `.songUnavailable`, `.lyrics`, and `.playback(code:)` expose these exact UI values:

| Error | Title | Message | Recovery |
|---|---|---|---|
| `.credentials` | `配置不可用` | `请检查 App ID 和 App Certificate。` | `.settings` |
| `.microphoneDenied` | `需要麦克风权限` | `需要麦克风权限才能检测音高。` | `.systemSettings` |
| `.network` | `网络连接失败` | `请检查网络后重试。` | `.retry` |
| `.songUnavailable` | `歌曲不可用` | `歌曲未授权或已下架，请选择其他歌曲。` | `.songList` |
| `.lyrics` | `歌词加载失败` | `无法下载或解析歌词，请重试。` | `.retry` |
| `.playback(code: 7)` | `播放失败` | `播放器错误（7），请重试。` | `.retry` |

- [ ] **Step 2: Verify tests fail**

Expected: missing session and error types.

- [ ] **Step 3: Implement the state boundary**

Define `KaraokeRecovery`, the cases above in `KaraokeError`, and `KaraokeSessionState: Equatable` with `idle`, `preparing(Song)`, `ready(Song)`, `playing(Song)`, `paused(Song)`, `finished(Song)`, and `failed(Song?, KaraokeError)`. Define these SDK-independent interfaces:

```swift
protocol KaraokeClientDelegate: AnyObject {
    func client(_ client: KaraokeClientProtocol, didLoad lyrics: LyricModel)
    func clientDidStartPlayback(_ client: KaraokeClientProtocol)
    func client(_ client: KaraokeClientProtocol, didUpdateProgress milliseconds: Int)
    func client(_ client: KaraokeClientProtocol, didUpdatePitch pitch: Double)
    func client(_ client: KaraokeClientProtocol, didFail error: KaraokeError)
    func clientDidFinishPlayback(_ client: KaraokeClientProtocol)
}

protocol KaraokeClientProtocol: AnyObject {
    var delegate: KaraokeClientDelegate? { get set }
    func prepare(song: Song, credentials: AgoraCredentials, access: KaraokeAccess)
    func pause()
    func resume()
    func seek(milliseconds: Int)
    func toggleAudioTrack()
    func cleanup()
}

protocol KaraokeSessionDelegate: AnyObject {
    func session(_ session: KaraokeSessionControlling, didChange state: KaraokeSessionState)
    func session(_ session: KaraokeSessionControlling, didLoad lyrics: LyricModel)
    func session(_ session: KaraokeSessionControlling, didUpdateProgress milliseconds: Int)
    func session(_ session: KaraokeSessionControlling, didUpdatePitch pitch: Double)
}

protocol KaraokeSessionControlling: AnyObject {
    var delegate: KaraokeSessionDelegate? { get set }
    var state: KaraokeSessionState { get }
    func start(song: Song, credentials: AgoraCredentials)
    func pause()
    func resume()
    func seek(milliseconds: Int)
    func toggleAudioTrack()
    func stop()
}
```

`KaraokeSession` conforms to `KaraokeSessionControlling`, creates access through `TokenProviding`, calls the client, guards pause/resume by current state, forwards client events through `KaraokeSessionDelegate`, and makes `stop()` idempotent with a `hasActiveClient` flag.

- [ ] **Step 4: Run tests and commit**

Expected: state, cleanup, forwarding, token failure, and error-copy tests pass.

```bash
git add Demo/Demo/App/Session/KaraokeError.swift Demo/Demo/App/Session/KaraokeSession.swift \
  Demo/DemoTests/KaraokeSessionTests.swift Demo/DemoTests/KaraokeErrorTests.swift Demo/Demo.xcodeproj
git commit -m "feat: add karaoke session state machine"
```

### Task 6: Adapt The Agora SDK Into KaraokeClientProtocol

**Files:**
- Create: `Demo/Demo/App/Session/AgoraKaraokeClient.swift`
- Create: `Demo/DemoTests/AgoraKaraokeClientMappingTests.swift`

- [ ] **Step 1: Write failing status mapping tests**

Extract pure mapping functions and test these cases:

```swift
XCTAssertEqual(AgoraKaraokeClient.mapPreloadError(.errorPermissionAndResource), .songUnavailable)
XCTAssertEqual(AgoraKaraokeClient.mapDownloadFailure(), .lyrics)
XCTAssertEqual(AgoraKaraokeClient.mapPlayerError(rawValue: 7), .playback(code: 7))
```

- [ ] **Step 2: Verify failure**

Expected: missing `AgoraKaraokeClient`.

- [ ] **Step 3: Implement preparation and callbacks**

`prepare` must perform this exact order:

```swift
let config = AgoraRtcEngineConfig()
config.appId = credentials.appId
config.audioScenario = .chorus
config.channelProfile = .liveBroadcasting
engine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
engine.enableAudioVolumeIndication(50, smooth: 3, reportVad: true)
engine.enableAudio()
engine.setClientRole(.broadcaster)

let options = AgoraRtcChannelMediaOptions()
options.clientRoleType = .broadcaster
let joinCode = engine.joinChannel(byToken: access.rtcToken,
                                  channelId: access.channelName,
                                  uid: access.uid,
                                  mediaOptions: options)
guard joinCode == 0 else { fail(.playback(code: Int(joinCode))); return }

let mccConfig = AgoraMusicContentCenterConfig()
mccConfig.rtcEngine = engine
mccConfig.mccUid = Int(access.uid)
mccConfig.token = access.mccToken
mccConfig.appId = credentials.appId
contentCenter = AgoraMusicContentCenter.sharedContentCenter(config: mccConfig)
contentCenter.register(self)
player = contentCenter.createMusicPlayer(delegate: self)
contentCenter.preload(songCode: song.id)
```

On preload `.OK`, request `.xml` lyrics. On lyric URL success, start `LyricsFileDownloader`. Parse completed data with `KaraokeView.parseLyricData`; send `didLoad`, then call `player.openMedia(songCode:startPos:)`. On `.openCompleted`, call `play`, start a 50 ms main-queue timer, and send `clientDidStartPlayback`. Each timer tick reads `player.getPosition()` and forwards non-negative values. On `.playBackCompleted` or `.playBackAllLoopsCompleted`, invalidate the timer and send `clientDidFinishPlayback`. On `.failed`, forward `.playback(code: error.rawValue)`. RTC pitch callbacks forward `voicePitch` only while playing.

Pause, resume, seek, and audio-track toggle call the corresponding player APIs and convert nonzero return codes to `.playback(code:)`. Track index `1` is original and `0` is accompaniment.

`cleanup()` must invalidate the timer, cancel the active lyric request, stop the player, unregister MCC, leave the channel, destroy the media player, nil all delegates/references, and be safe on repeat calls. Dispatch every delegate callback to the main queue.

- [ ] **Step 4: Run mapping tests and compile the adapter**

Run all `DemoTests`; then run:

```bash
xcodebuild build -workspace Demo/Demo.xcworkspace -scheme Demo \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

Expected: tests pass and the complete Agora adapter compiles.

- [ ] **Step 5: Commit**

```bash
git add Demo/Demo/App/Session/AgoraKaraokeClient.swift Demo/DemoTests/AgoraKaraokeClientMappingTests.swift Demo/Demo.xcodeproj
git commit -m "feat: connect karaoke session to Agora SDK"
```

### Task 7: Build Credential Configuration And Permission Handling

**Files:**
- Create: `Demo/Demo/App/Credentials/ConfigurationViewController.swift`
- Create: `Demo/Demo/App/Permissions/MicrophonePermissionProvider.swift`
- Create: `Demo/DemoTests/MicrophonePermissionProviderTests.swift`

- [ ] **Step 1: Add permission-state tests**

Test the pure mapping from `AVAudioSession.RecordPermission` to `MicrophonePermissionState`: `.granted -> .granted`, `.denied -> .denied`, `.undetermined -> .undetermined`.

- [ ] **Step 2: Implement the permission provider**

```swift
protocol MicrophonePermissionProviding {
    var state: MicrophonePermissionState { get }
    func request(_ completion: @escaping (MicrophonePermissionState) -> Void)
}

final class MicrophonePermissionProvider: MicrophonePermissionProviding {
    var state: MicrophonePermissionState { Self.map(AVAudioSession.sharedInstance().recordPermission) }
    func request(_ completion: @escaping (MicrophonePermissionState) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async { completion(granted ? .granted : .denied) }
        }
    }
}
```

- [ ] **Step 3: Implement the configuration form**

Build a programmatic, scroll-safe vertical form containing title `Agora 配置`, App ID field, secure App Certificate field, an eye system-icon button with accessibility label `显示或隐藏证书`, the internal-demo warning, inline validation label, and `保存并继续` button. Expose:

```swift
var onSave: ((AgoraCredentials) -> Void)?
var onClear: (() -> Void)?

func populate(_ credentials: AgoraCredentials?)
```

On Save, construct `AgoraCredentials`; map validation errors to `App ID 必须是 32 位十六进制字符` or `App Certificate 必须是 32 位十六进制字符`. In settings mode show a destructive `清除配置` button that asks for confirmation before invoking `onClear`.

- [ ] **Step 4: Run tests, build, and commit**

Expected: permission tests pass and the form compiles on iOS 13.

```bash
git add Demo/Demo/App/Credentials/ConfigurationViewController.swift Demo/Demo/App/Permissions \
  Demo/DemoTests/MicrophonePermissionProviderTests.swift Demo/Demo.xcodeproj
git commit -m "feat: add secure Agora configuration flow"
```

### Task 8: Build Song Selection And Complete App Navigation

**Files:**
- Create: `Demo/Demo/App/Songs/SongListViewController.swift`
- Modify: `Demo/Demo/App/AppCoordinator.swift`
- Modify: `Demo/DemoTests/ProjectSmokeTests.swift`

- [ ] **Step 1: Extend the coordinator smoke tests**

With a fake store, verify no credentials starts on `ConfigurationViewController`, saved credentials start on `SongListViewController`, clearing credentials returns to configuration, and selecting a song calls the karaoke factory with that exact `Song`.

- [ ] **Step 2: Implement the song list**

Use an inset-grouped `UITableView` with one row per `SongCatalog.songs`, the song name, disclosure indicator, title `选择歌曲`, and a gear system-icon navigation item with accessibility label `Agora 配置`. Expose `onSelectSong` and `onOpenSettings` closures.

- [ ] **Step 3: Replace the coordinator placeholder**

Inject `CredentialsStoring`, `TokenProviding`, a `MicrophonePermissionProviding`, and a `KaraokeClientProtocol` factory. `start()` loads Keychain credentials and chooses configuration or song list. Saving writes Keychain before showing songs. Clearing removes Keychain and resets the navigation stack. Selecting a song pushes `KaraokeViewController`; the concrete production initializer uses `KeychainCredentialsStore`, `LocalTokenProvider`, `MicrophonePermissionProvider`, `AgoraKaraokeClient`, and a `KaraokeSession` exposed as `KaraokeSessionControlling`.

- [ ] **Step 4: Run tests and commit**

Expected: coordinator and song catalog tests pass.

```bash
git add Demo/Demo/App/AppCoordinator.swift Demo/Demo/App/Songs/SongListViewController.swift \
  Demo/DemoTests/ProjectSmokeTests.swift Demo/Demo.xcodeproj
git commit -m "feat: add song selection navigation"
```

### Task 9: Build And Bind The Karaoke Screen

**Files:**
- Create: `Demo/Demo/App/Karaoke/KaraokeContentView.swift`
- Create: `Demo/Demo/App/Karaoke/KaraokeViewController.swift`
- Create: `Demo/DemoTests/KaraokeViewControllerTests.swift`

- [ ] **Step 1: Write controller behavior tests**

Use fake permission/session objects to verify: granted permission starts once; denied permission does not start and exposes the Settings action; pause/resume buttons call the matching session operation; Next stops the old session and emits the next song; `viewWillDisappear` stops the session.

- [ ] **Step 2: Build the content view**

Create a programmatic view with `KaraokeView` filling the flexible main area, a compact score row (`本句 --`, `总分 0`), and a bottom horizontal control row. Use symbol icons plus titles for `跳过前奏`, `暂停`, and `下一首`; keep buttons at a stable 48-point height. Configure:

```swift
karaokeView.backgroundImage = UIImage(named: "ktv_top_bgIcon")
karaokeView.scoringView.viewHeight = 100
karaokeView.scoringView.topSpaces = 64
karaokeView.lyricsView.draggable = false
karaokeView.lyricsView.showDebugView = false
karaokeView.backgroundColor = .black
```

Add an in-view loading/error overlay with activity indicator, message, Retry, Back to Songs, and optional Open Settings actions. It must constrain to the safe area and never resize the karaoke view when state changes.

- [ ] **Step 3: Bind the controller**

The controller receives song, credentials, `KaraokeSessionControlling`, permission provider, and closures for next/back. Set the navigation title to the song, provide an original/accompaniment toggle in the right bar item, and start only after microphone permission is granted. Implement `KaraokeSessionDelegate` as follows:

```swift
func session(_ session: KaraokeSessionControlling, didLoad lyrics: LyricModel) {
    contentView.karaokeView.setLyricData(data: lyrics, usingInternalScoring: true)
}

func session(_ session: KaraokeSessionControlling, didUpdateProgress milliseconds: Int) {
    contentView.karaokeView.setProgress(progress: milliseconds)
}

func session(_ session: KaraokeSessionControlling, didUpdatePitch pitch: Double) {
    contentView.karaokeView.setPitch(speakerPitch: pitch, progressInMs: 0)
}
```

Implement `KaraokeDelegate.didFinishLineWith` to update the line and cumulative score labels. Skip Prelude seeks to `max(lyrics.preludeEndPosition - 1000, 0)`. Loading maps to `.preparing`; retry calls `stop()` then starts the same song; back and next always stop first. On microphone denial, show `需要麦克风权限才能检测音高` with Open Settings using `UIApplication.openSettingsURLString`.

- [ ] **Step 4: Run tests and UI builds**

Run all tests, then Debug and Release simulator builds:

```bash
xcodebuild build -workspace Demo/Demo.xcworkspace -scheme Demo -configuration Debug \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
xcodebuild build -workspace Demo/Demo.xcworkspace -scheme Demo -configuration Release \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

Expected: tests pass; both builds complete with no old Demo controller in Sources.

- [ ] **Step 5: Commit**

```bash
git add Demo/Demo/App/Karaoke Demo/DemoTests/KaraokeViewControllerTests.swift Demo/Demo.xcodeproj
git commit -m "feat: add iPhone karaoke experience"
```

### Task 10: Document Setup And Run Final Verification

**Files:**
- Modify: `README.md`
- Modify: `Demo/Demo/Assets.xcassets/AppIcon.appiconset/Contents.json` only if Xcode reports invalid slots

- [ ] **Step 1: Replace Demo instructions in README**

Document these exact operator steps: run `cd Demo && pod install`, open `Demo.xcworkspace`, select an Apple Development Team, run on an iPhone, enter the shared App ID/App Certificate, select a licensed song, and grant microphone access. Include a boxed warning that on-device certificate storage is for internal demos only and public releases require a token server.

- [ ] **Step 2: Run static checks**

```bash
rg -n '/Volumes/|~/work|<#|rtcAppId without Token|mccCertificate' \
  Demo/Podfile Demo/Demo/App Demo/Demo.xcodeproj README.md
git diff --check
```

Expected: `rg` returns no matches and `git diff --check` is empty.

- [ ] **Step 3: Run the full automated gate**

```bash
ruby scripts/configure_iphone_demo_project.rb
cd Demo && pod install
xcodebuild test -workspace Demo.xcworkspace -scheme Demo \
  -destination 'platform=iOS Simulator,name=iPhone 14' CODE_SIGNING_ALLOWED=NO
xcodebuild build -workspace Demo.xcworkspace -scheme Demo -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
```

Expected: all tests pass; simulator tests and generic physical-device Release build succeed.

- [ ] **Step 4: Perform physical-device acceptance**

On an iPhone, verify credential persistence after relaunch, all five selection rows, one licensed song end to end, live microphone pitch, lyrics, scoring, pause/resume, prelude skip, original/accompaniment toggle, next song, back, microphone denial, offline retry, and repeated enter/exit without overlapping audio. Record unavailable song IDs as account-license limitations rather than changing the fixed catalog.

- [ ] **Step 5: Commit**

```bash
git add README.md Demo/Demo/Assets.xcassets Demo/Demo.xcodeproj Demo/Demo.xcworkspace
git commit -m "docs: add iPhone karaoke setup and verification"
```
