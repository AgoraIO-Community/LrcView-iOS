import UIKit

final class AppCoordinator {
    let navigationController = UINavigationController()

    func start() {
        let root = UIViewController()
        root.title = "K 歌"
        root.view.backgroundColor = .systemBackground
        navigationController.setViewControllers([root], animated: false)
    }
}
