import Foundation

@main
struct TMEPlaybackGateTests {
    static func main() {
        let ready = TMEPlaybackGate()
        var modes = [TMEPlaybackGate.Mode]()
        ready.onStart = { modes.append($0) }
        ready.mediaOpened()
        precondition(modes.isEmpty)
        ready.resourcesReady()
        ready.mediaOpened()
        precondition(modes == [.playWithScoring])

        let failed = TMEPlaybackGate()
        failed.onStart = { modes.append($0) }
        failed.resourcesFailed()
        failed.mediaOpened()
        failed.resourcesReady()
        precondition(modes == [.playWithScoring, .playWithoutScoring])

        let cancelled = TMEPlaybackGate()
        cancelled.onStart = { modes.append($0) }
        cancelled.mediaOpened()
        cancelled.stop()
        cancelled.resourcesReady()
        precondition(modes.count == 2)
        print("TMEPlaybackGateTests passed")
    }
}
