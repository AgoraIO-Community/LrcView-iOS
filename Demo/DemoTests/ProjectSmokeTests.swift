import XCTest
@testable import Demo

final class ProjectSmokeTests: XCTestCase {
    func testAppCoordinatorCreatesNavigationController() {
        XCTAssertTrue(AppCoordinator().navigationController.viewControllers.isEmpty)
    }
}
