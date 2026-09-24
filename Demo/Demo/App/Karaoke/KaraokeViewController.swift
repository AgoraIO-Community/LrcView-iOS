import UIKit

final class KaraokeViewController: UIViewController {
    let song: Song
    let credentials: AgoraCredentials
    let session: KaraokeSessionControlling
    let permissionProvider: MicrophonePermissionProviding
    let onNext: (Song) -> Void
    let onBack: () -> Void

    init(
        song: Song,
        credentials: AgoraCredentials,
        session: KaraokeSessionControlling,
        permissionProvider: MicrophonePermissionProviding,
        onNext: @escaping (Song) -> Void,
        onBack: @escaping () -> Void
    ) {
        self.song = song
        self.credentials = credentials
        self.session = session
        self.permissionProvider = permissionProvider
        self.onNext = onNext
        self.onBack = onBack
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = song.name
        view.backgroundColor = .black
        navigationItem.largeTitleDisplayMode = .never
    }
}
