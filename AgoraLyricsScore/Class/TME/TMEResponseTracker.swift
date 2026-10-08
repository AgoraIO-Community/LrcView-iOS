import Foundation

public final class TMEResponseTracker {
    private var currentRequestId: String?
    private var generation = 0

    public init() {}

    public func set(_ requestId: String) {
        generation &+= 1
        currentRequestId = requestId
    }

    public func clear() {
        generation &+= 1
        currentRequestId = nil
    }

    public func consume(_ requestId: String) -> Bool {
        guard currentRequestId == requestId else { return false }
        currentRequestId = nil
        return true
    }

    public func deliverIfCurrent(_ requestId: String, _ deliver: (() -> Bool) -> Void) {
        guard consume(requestId) else { return }
        let acceptedGeneration = generation
        deliver { [self] in generation == acceptedGeneration }
    }
}
