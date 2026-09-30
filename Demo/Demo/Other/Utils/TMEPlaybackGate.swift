import Foundation

final class TMEPlaybackGate {
    enum Mode: Equatable {
        case playWithScoring, playWithoutScoring
    }

    var onStart: ((Mode) -> Void)?

    private var opened = false
    private var result: Mode?
    private var fired = false
    private var stopped = false

    func mediaOpened() {
        opened = true
        startIfReady()
    }

    func resourcesReady() {
        if result == nil { result = .playWithScoring }
        startIfReady()
    }

    func resourcesFailed() {
        if result == nil { result = .playWithoutScoring }
        startIfReady()
    }

    func stop() {
        stopped = true
        onStart = nil
    }

    private func startIfReady() {
        guard opened, let result = result, !stopped, !fired else { return }
        fired = true
        onStart?(result)
    }
}
