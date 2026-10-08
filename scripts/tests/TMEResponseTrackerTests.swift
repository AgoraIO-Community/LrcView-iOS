import Foundation
import AgoraLyricsScore

@main
struct TMEResponseTrackerTests {
    static func main() {
        let tracker = TMEResponseTracker()
        tracker.set("old")
        tracker.set("new")
        precondition(!tracker.consume("old"))
        precondition(!tracker.consume("old"))
        precondition(tracker.consume("new"))
        precondition(!tracker.consume("new"))
        tracker.set("cancelled")
        tracker.clear()
        precondition(!tracker.consume("cancelled"))

        var deliveries: [String] = []
        tracker.set("success")
        tracker.deliverIfCurrent("success") { _ in deliveries.append("success") }
        precondition(deliveries == ["success"])
        tracker.set("old")
        tracker.set("new")
        tracker.deliverIfCurrent("old") { _ in deliveries.append("stale") }
        precondition(deliveries == ["success"])
        tracker.deliverIfCurrent("new") { _ in deliveries.append("error") }
        precondition(deliveries == ["success", "error"])

        tracker.set("reentrant")
        tracker.deliverIfCurrent("reentrant") { isStillCurrent in
            deliveries.append("load")
            tracker.set("retry")
            if isStillCurrent() { deliveries.append("old-status") }
        }
        precondition(deliveries == ["success", "error", "load"])
        tracker.set("stopping")
        tracker.deliverIfCurrent("stopping") { isStillCurrent in
            tracker.clear()
            precondition(!isStillCurrent())
        }
        print("TMEResponseTrackerTests passed")
    }
}
