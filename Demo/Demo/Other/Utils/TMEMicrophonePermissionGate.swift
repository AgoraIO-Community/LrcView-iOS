import Foundation

final class TMEMicrophonePermissionGate {
    enum Status { case granted, undetermined, denied }

    private let status: () -> Status
    private let request: (@escaping (Bool) -> Void) -> Void
    private var generation = 0
    private var awaiting = false

    init(status: @escaping () -> Status,
         request: @escaping (@escaping (Bool) -> Void) -> Void) {
        self.status = status
        self.request = request
    }

    func authorize(_ completion: @escaping (Bool) -> Void) {
        precondition(Thread.isMainThread)
        guard !awaiting else { return }
        switch status() {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            awaiting = true
            let current = generation
            request { [weak self] allowed in
                DispatchQueue.main.async {
                    guard let self = self, self.generation == current,
                          self.awaiting else { return }
                    self.awaiting = false
                    completion(allowed)
                }
            }
        }
    }

    func cancel() {
        precondition(Thread.isMainThread)
        generation += 1
        awaiting = false
    }
}
