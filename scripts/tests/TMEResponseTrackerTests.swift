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
        print("TMEResponseTrackerTests passed")
    }
}
