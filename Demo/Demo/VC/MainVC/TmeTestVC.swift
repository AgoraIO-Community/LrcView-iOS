import UIKit

final class TmeTestVC: UIViewController {
    private let manager = TmeManager()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let statusLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let playPauseButton = UIButton(type: .system)
    private var songs: [TmeSong] = []
    private var selectedRow: Int?
    private lazy var retryButton = UIBarButtonItem(barButtonSystemItem: .refresh,
                                                   target: self,
                                                   action: #selector(retry))

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TME测试"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = retryButton
        setupViews()
        manager.delegate = self
        manager.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent { manager.stop() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        manager.delegate = self
        if selectedRow != nil {
            selectedRow = nil
            tableView.reloadData()
            playPauseButton.isEnabled = false
            statusLabel.text = "请选择歌曲"
            activityIndicator.stopAnimating()
        }
    }

    private func setupViews() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 64
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        statusLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 2
        statusLabel.text = "正在连接 RTC"

        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.accessibilityLabel = "继续播放"
        playPauseButton.isEnabled = false
        playPauseButton.addTarget(self, action: #selector(togglePlayback), for: .touchUpInside)
        playPauseButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
        playPauseButton.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let controls = UIStackView(arrangedSubviews: [activityIndicator, statusLabel, playPauseButton])
        controls.axis = .horizontal
        controls.alignment = .center
        controls.spacing = 12
        controls.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        controls.isLayoutMarginsRelativeArrangement = true
        view.addSubview(controls)

        [tableView, controls].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: controls.topAnchor),
            controls.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controls.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            controls.heightAnchor.constraint(greaterThanOrEqualToConstant: 64)
        ])
        activityIndicator.startAnimating()
    }

    @objc private func retry() {
        retryButton.isEnabled = false
        activityIndicator.startAnimating()
        manager.start()
    }

    @objc private func togglePlayback() {
        manager.togglePlayback()
    }
}

extension TmeTestVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        songs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "tmeSong"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        let song = songs[indexPath.row]
        cell.textLabel?.text = song.name
        cell.detailTextLabel?.text = song.artist
        cell.textLabel?.lineBreakMode = .byTruncatingTail
        cell.accessoryType = selectedRow == indexPath.row ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedRow = indexPath.row
        tableView.reloadData()
        let song = songs[indexPath.row]
        let singing = TmeSingingVC(song: song, manager: manager)
        manager.delegate = singing
        navigationController?.pushViewController(singing, animated: true)
        manager.select(song)
    }
}

extension TmeTestVC: TmeManagerDelegate {
    func tmeManager(_ manager: TmeManager, didLoad songs: [TmeSong]) {
        self.songs = songs
        selectedRow = nil
        tableView.reloadData()
        activityIndicator.stopAnimating()
        retryButton.isEnabled = true
    }

    func tmeManager(_ manager: TmeManager, didUpdate status: String) {
        statusLabel.text = status
        if status == "请选择歌曲" || status == "暂无歌曲" || status == "正在播放"
            || status == "已暂停" || status == "播放结束" {
            activityIndicator.stopAnimating()
            retryButton.isEnabled = true
        } else {
            activityIndicator.startAnimating()
        }
    }

    func tmeManager(_ manager: TmeManager, didFail message: String) {
        statusLabel.text = message
        activityIndicator.stopAnimating()
        retryButton.isEnabled = true
    }

    func tmeManager(_ manager: TmeManager, didChangePlayback isPlaying: Bool) {
        playPauseButton.isEnabled = manager.canTogglePlayback
        playPauseButton.setImage(UIImage(systemName: isPlaying ? "pause.fill" : "play.fill"),
                                 for: .normal)
        playPauseButton.accessibilityLabel = isPlaying ? "暂停播放" : "继续播放"
        if !isPlaying { activityIndicator.stopAnimating() }
    }
}
