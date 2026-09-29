import Foundation

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
        tracker.deliverIfCurrent("success") { deliveries.append("success") }
        precondition(deliveries == ["success"])
        tracker.set("old")
        tracker.set("new")
        tracker.deliverIfCurrent("old") { deliveries.append("stale") }
        precondition(deliveries == ["success"])
        tracker.deliverIfCurrent("new") { deliveries.append("error") }
        precondition(deliveries == ["success", "error"])
        print("TMEResponseTrackerTests passed")
    }
}
