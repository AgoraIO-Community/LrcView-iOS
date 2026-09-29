import Foundation

final class TMEResponseTracker {
    private var currentRequestId: String?

    func set(_ requestId: String) {
        currentRequestId = requestId
    }

    func clear() {
        currentRequestId = nil
    }

    func consume(_ requestId: String) -> Bool {
        guard currentRequestId == requestId else { return false }
        currentRequestId = nil
        return true
    }
}
