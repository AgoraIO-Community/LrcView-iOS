import AVFoundation

enum MicrophonePermissionState: Equatable {
    case granted
    case denied
    case undetermined
}

protocol MicrophonePermissionProviding {
    var state: MicrophonePermissionState { get }
    func request(_ completion: @escaping (MicrophonePermissionState) -> Void)
}

final class MicrophonePermissionProvider: MicrophonePermissionProviding {
    var state: MicrophonePermissionState {
        Self.map(AVAudioSession.sharedInstance().recordPermission)
    }

    func request(_ completion: @escaping (MicrophonePermissionState) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted ? .granted : .denied)
            }
        }
    }

    static func map(_ permission: AVAudioSession.RecordPermission) -> MicrophonePermissionState {
        switch permission {
        case .granted:
            return .granted
        case .denied:
            return .denied
        case .undetermined:
            return .undetermined
        @unknown default:
            return .undetermined
        }
    }
}
