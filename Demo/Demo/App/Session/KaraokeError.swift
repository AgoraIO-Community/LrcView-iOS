enum KaraokeRecovery: Equatable {
    case settings
    case systemSettings
    case retry
    case songList
}

enum KaraokeError: Error, Equatable {
    case credentials
    case microphoneDenied
    case network
    case songUnavailable
    case lyrics
    case playback(code: Int)

    var title: String {
        switch self {
        case .credentials:
            return "配置不可用"
        case .microphoneDenied:
            return "需要麦克风权限"
        case .network:
            return "网络连接失败"
        case .songUnavailable:
            return "歌曲不可用"
        case .lyrics:
            return "歌词加载失败"
        case .playback:
            return "播放失败"
        }
    }

    var message: String {
        switch self {
        case .credentials:
            return "请检查 App ID 和 App Certificate。"
        case .microphoneDenied:
            return "需要麦克风权限才能检测音高。"
        case .network:
            return "请检查网络后重试。"
        case .songUnavailable:
            return "歌曲未授权或已下架，请选择其他歌曲。"
        case .lyrics:
            return "无法下载或解析歌词，请重试。"
        case let .playback(code):
            return "播放器错误（\(code)），请重试。"
        }
    }

    var recovery: KaraokeRecovery {
        switch self {
        case .credentials:
            return .settings
        case .microphoneDenied:
            return .systemSettings
        case .songUnavailable:
            return .songList
        case .network, .lyrics, .playback:
            return .retry
        }
    }
}
