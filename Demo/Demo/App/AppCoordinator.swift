import UIKit

final class AppCoordinator {
    typealias KaraokeFactory = (Song, AgoraCredentials) -> UIViewController

    let navigationController = UINavigationController()

    private let credentialsStore: CredentialsStoring
    private let tokenProvider: TokenProviding
    private let permissionProvider: MicrophonePermissionProviding
    private let karaokeClientFactory: () -> KaraokeClientProtocol
    private let injectedKaraokeFactory: KaraokeFactory?
    private var credentials: AgoraCredentials?

    init(
        credentialsStore: CredentialsStoring = KeychainCredentialsStore(),
        tokenProvider: TokenProviding = LocalTokenProvider(),
        permissionProvider: MicrophonePermissionProviding = MicrophonePermissionProvider(),
        karaokeClientFactory: @escaping () -> KaraokeClientProtocol = { AgoraKaraokeClient() },
        karaokeFactory: KaraokeFactory? = nil
    ) {
        self.credentialsStore = credentialsStore
        self.tokenProvider = tokenProvider
        self.permissionProvider = permissionProvider
        self.karaokeClientFactory = karaokeClientFactory
        injectedKaraokeFactory = karaokeFactory
        navigationController.navigationBar.prefersLargeTitles = true
    }

    func start() {
        do {
            credentials = try credentialsStore.load()
            if credentials == nil {
                showConfiguration(asRoot: true)
            } else {
                showSongList()
            }
        } catch {
            credentials = nil
            showConfiguration(asRoot: true)
            showStorageError()
        }
    }

    private func showSongList() {
        let controller = SongListViewController()
        controller.onSelectSong = { [weak self] song in
            self?.showKaraoke(for: song)
        }
        controller.onOpenSettings = { [weak self] in
            self?.showConfiguration(asRoot: false)
        }
        navigationController.setViewControllers([controller], animated: false)
    }

    private func showConfiguration(asRoot: Bool) {
        let controller = ConfigurationViewController()
        controller.populate(credentials)
        controller.onSave = { [weak self, weak controller] credentials in
            guard let self else { return }
            do {
                try self.credentialsStore.save(credentials)
                self.credentials = credentials
                self.showSongList()
            } catch {
                controller?.presentStorageError()
            }
        }
        controller.onClear = { [weak self, weak controller] in
            guard let self else { return }
            do {
                try self.credentialsStore.clear()
                self.credentials = nil
                self.showConfiguration(asRoot: true)
            } catch {
                controller?.presentStorageError()
            }
        }

        if asRoot {
            navigationController.setViewControllers([controller], animated: false)
        } else {
            navigationController.pushViewController(controller, animated: shouldAnimateNavigation)
        }
    }

    private func showKaraoke(for song: Song) {
        guard let credentials else {
            showConfiguration(asRoot: true)
            return
        }
        let controller: UIViewController
        if let injectedKaraokeFactory {
            controller = injectedKaraokeFactory(song, credentials)
        } else {
            let session = KaraokeSession(client: karaokeClientFactory(), tokenProvider: tokenProvider)
            controller = KaraokeViewController(
                song: song,
                credentials: credentials,
                session: session,
                permissionProvider: permissionProvider,
                onNext: { [weak self] nextSong in
                    self?.replaceKaraoke(with: nextSong)
                },
                onBack: { [weak self] in
                    self?.navigationController.popToRootViewController(animated: true)
                }
            )
        }
        navigationController.pushViewController(controller, animated: shouldAnimateNavigation)
    }

    private func replaceKaraoke(with song: Song) {
        guard navigationController.viewControllers.count > 1 else {
            showKaraoke(for: song)
            return
        }
        navigationController.popViewController(animated: false)
        showKaraoke(for: song)
    }

    private var shouldAnimateNavigation: Bool {
        navigationController.viewIfLoaded?.window != nil
    }

    private func showStorageError() {
        navigationController.topViewController?.presentStorageError()
    }
}

private extension UIViewController {
    func presentStorageError() {
        let alert = UIAlertController(
            title: "无法访问配置",
            message: "请稍后重试，或重新输入 Agora 配置。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}
