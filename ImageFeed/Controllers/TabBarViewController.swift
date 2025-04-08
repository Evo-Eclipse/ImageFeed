import UIKit

final class TabBarViewController: UITabBarController {
    
    // MARK: - Overrides Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabBar()
        setupViewControllers()
    }
    
    // MARK: - Private Methods
    
    private func setupTabBar() {
        tabBar.tintColor = .ypWhite
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .ypBlack
            
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        } else {
            tabBar.barTintColor = .ypBlack
            tabBar.isTranslucent = false
        }
    }
    
    private func setupViewControllers() {
        let imagesListViewController = ImagesListViewController()
        imagesListViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab.editorial.active"),
            tag: 0
        )
        
        let profileViewController = ProfileViewController()
        profileViewController.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab.profile.active"),
            tag: 1
        )
        
        self.viewControllers = [imagesListViewController, profileViewController]
    }
}
