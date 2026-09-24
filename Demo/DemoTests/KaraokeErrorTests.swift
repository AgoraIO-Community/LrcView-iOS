import XCTest
@testable import Demo

final class KaraokeErrorTests: XCTestCase {
    func testUserFacingCopyAndRecovery() {
        XCTAssertError(
            .credentials,
            title: "配置不可用",
            message: "请检查 App ID 和 App Certificate。",
            recovery: .settings
        )
        XCTAssertError(
            .microphoneDenied,
            title: "需要麦克风权限",
            message: "需要麦克风权限才能检测音高。",
            recovery: .systemSettings
        )
        XCTAssertError(
            .network,
            title: "网络连接失败",
            message: "请检查网络后重试。",
            recovery: .retry
        )
        XCTAssertError(
            .songUnavailable,
            title: "歌曲不可用",
            message: "歌曲未授权或已下架，请选择其他歌曲。",
            recovery: .songList
        )
        XCTAssertError(
            .lyrics,
            title: "歌词加载失败",
            message: "无法下载或解析歌词，请重试。",
            recovery: .retry
        )
        XCTAssertError(
            .playback(code: 7),
            title: "播放失败",
            message: "播放器错误（7），请重试。",
            recovery: .retry
        )
    }

    private func XCTAssertError(
        _ error: KaraokeError,
        title: String,
        message: String,
        recovery: KaraokeRecovery,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(error.title, title, file: file, line: line)
        XCTAssertEqual(error.message, message, file: file, line: line)
        XCTAssertEqual(error.recovery, recovery, file: file, line: line)
    }
}
