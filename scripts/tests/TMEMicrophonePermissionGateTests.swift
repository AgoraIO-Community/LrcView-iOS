import Foundation

@main
struct TMEMicrophonePermissionGateTests {
    static func main() {
        var requests = 0
        let granted = TMEMicrophonePermissionGate(status: { .granted },
                                                  request: { _ in requests += 1 })
        var grantedResults = [Bool]()
        granted.authorize { grantedResults.append($0) }
        precondition(grantedResults == [true] && requests == 0)

        let denied = TMEMicrophonePermissionGate(status: { .denied },
                                                 request: { _ in requests += 1 })
        var deniedResults = [Bool]()
        denied.authorize { deniedResults.append($0) }
        precondition(deniedResults == [false] && requests == 0)

        var callback: ((Bool) -> Void)?
        let pending = TMEMicrophonePermissionGate(status: { .undetermined },
            request: { completion in requests += 1; callback = completion })
        var pendingResults = [Bool]()
        pending.authorize { pendingResults.append($0) }
        pending.authorize { _ in preconditionFailure("duplicate request") }
        precondition(requests == 1)
        let oldCallback = callback!
        pending.cancel()
        pending.authorize {
            precondition(Thread.isMainThread)
            pendingResults.append($0)
        }
        precondition(requests == 2)
        oldCallback(true)
        RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        precondition(pendingResults.isEmpty)
        callback?(false)
        RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        precondition(pendingResults == [false])
        print("TMEMicrophonePermissionGateTests passed")
    }
}
