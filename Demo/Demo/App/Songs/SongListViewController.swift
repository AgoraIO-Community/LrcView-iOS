import UIKit

final class SongListViewController: UITableViewController {
    var onSelectSong: ((Song) -> Void)?
    var onOpenSettings: (() -> Void)?

    init() {
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择歌曲"
        navigationItem.largeTitleDisplayMode = .always
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SongCell")

        let settings = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(openSettings)
        )
        settings.accessibilityLabel = "Agora 配置"
        navigationItem.rightBarButtonItem = settings
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        SongCatalog.songs.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath)
        cell.textLabel?.text = SongCatalog.songs[indexPath.row].name
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = "song-\(SongCatalog.songs[indexPath.row].id)"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelectSong?(SongCatalog.songs[indexPath.row])
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }
}
