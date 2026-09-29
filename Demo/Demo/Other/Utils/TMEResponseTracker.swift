import Foundation

final class TMEResponseTracker {
    private var currentRequestId: String?
    private var generation = 0

    func set(_ requestId: String) {
        generation &+= 1
        currentRequestId = requestId
    }

    func clear() {
        generation &+= 1
        currentRequestId = nil
    }

    func consume(_ requestId: String) -> Bool {
        guard currentRequestId == requestId else { return false }
        currentRequestId = nil
        return true
    }

    func deliverIfCurrent(_ requestId: String, _ deliver: (() -> Bool) -> Void) {
        guard consume(requestId) else { return }
        let acceptedGeneration = generation
        deliver { [self] in generation == acceptedGeneration }
    }
}
