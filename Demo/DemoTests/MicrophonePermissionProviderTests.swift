import AVFoundation
import XCTest
@testable import Demo

final class MicrophonePermissionProviderTests: XCTestCase {
    func testMapsGrantedPermission() {
        XCTAssertEqual(MicrophonePermissionProvider.map(.granted), .granted)
    }

    func testMapsDeniedPermission() {
        XCTAssertEqual(MicrophonePermissionProvider.map(.denied), .denied)
    }

    func testMapsUndeterminedPermission() {
        XCTAssertEqual(MicrophonePermissionProvider.map(.undetermined), .undetermined)
    }
}
