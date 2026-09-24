import UIKit
import XCTest
@testable import Demo

final class ProjectSmokeTests: XCTestCase {
    private let credentials = try! AgoraCredentials(
        appId: String(repeating: "a", count: 32),
        appCertificate: String(repeating: "b", count: 32)
    )

    func testNoCredentialsStartsOnConfiguration() {
        let coordinator = makeCoordinator(store: FakeCredentialsStore())

        coordinator.start()

        XCTAssertTrue(coordinator.navigationController.topViewController is ConfigurationViewController)
    }

    func testSavedCredentialsStartOnSongList() {
        let coordinator = makeCoordinator(store: FakeCredentialsStore(credentials: credentials))

        coordinator.start()

        XCTAssertTrue(coordinator.navigationController.topViewController is SongListViewController)
    }

    func testSavingAndClearingCredentialsUpdatesNavigation() throws {
        let store = FakeCredentialsStore()
        let coordinator = makeCoordinator(store: store)
        coordinator.start()

        let configuration = try XCTUnwrap(
            coordinator.navigationController.topViewController as? ConfigurationViewController
        )
        configuration.onSave?(credentials)
        XCTAssertEqual(store.credentials, credentials)
        let songs = try XCTUnwrap(
            coordinator.navigationController.topViewController as? SongListViewController
        )

        songs.onOpenSettings?()
        let settings = try XCTUnwrap(
            coordinator.navigationController.topViewController as? ConfigurationViewController
        )
        settings.onClear?()

        XCTAssertNil(store.credentials)
        XCTAssertEqual(coordinator.navigationController.viewControllers.count, 1)
        XCTAssertTrue(coordinator.navigationController.topViewController is ConfigurationViewController)
    }

    func testSelectingSongUsesTheExactSong() throws {
        var selectedSong: Song?
        let coordinator = AppCoordinator(
            credentialsStore: FakeCredentialsStore(credentials: credentials),
            karaokeFactory: { song, _ in
                selectedSong = song
                return UIViewController()
            }
        )
        coordinator.start()
        let songs = try XCTUnwrap(
            coordinator.navigationController.topViewController as? SongListViewController
        )

        songs.onSelectSong?(SongCatalog.songs[3])

        XCTAssertEqual(selectedSong, SongCatalog.songs[3])
        XCTAssertEqual(coordinator.navigationController.viewControllers.count, 2)
    }

    private func makeCoordinator(store: FakeCredentialsStore) -> AppCoordinator {
        AppCoordinator(
            credentialsStore: store,
            karaokeFactory: { _, _ in UIViewController() }
        )
    }
}

private final class FakeCredentialsStore: CredentialsStoring {
    var credentials: AgoraCredentials?

    init(credentials: AgoraCredentials? = nil) {
        self.credentials = credentials
    }

    func load() throws -> AgoraCredentials? {
        credentials
    }

    func save(_ credentials: AgoraCredentials) throws {
        self.credentials = credentials
    }

    func clear() throws {
        credentials = nil
    }
}
