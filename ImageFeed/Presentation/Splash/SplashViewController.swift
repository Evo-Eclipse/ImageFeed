import UIKit

final class SplashViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let showAuthSegueIdentifier = "ShowAuth"
    private let tabBarViewControllerIdentifier = "TabBarViewController"
    private let oauth2Service = OAuth2Service.shared
    private let oauth2TokenStorage = OAuth2TokenStorage.shared
    
    // MARK: - Overrides Methods
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if oauth2TokenStorage.token != nil {
            switchToTabBarViewController()
        } else {
            performSegue(withIdentifier: showAuthSegueIdentifier, sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showAuthSegueIdentifier {
            guard
                let navigationController = segue.destination as? UINavigationController,
                let viewController = navigationController.topViewController as? AuthViewController
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            
            viewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    // MARK: - Private Methods
    
    private func switchToTabBarViewController() {
        guard let window = UIApplication.shared.windows.first else {
            fatalError("SplashViewController :: Invalid configuration, no main window found")
        }
        
        let tabBarViewController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: tabBarViewControllerIdentifier)
        
        window.rootViewController = tabBarViewController
        window.makeKeyAndVisible()
        
        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil,
            completion: nil
        )
    }
}

// MARK: - AuthViewControllerDelegate

extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ viewController: AuthViewController, didAuthenticateWithCode code: String) {
        dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.fetchOAuthToken(with: code)
        }
    }
    
    private func fetchOAuthToken(with code: String) {
        oauth2Service.fetchOAuthToken(code) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                self.switchToTabBarViewController()
            case .failure(let error):
                print("SplashViewController :: Ошибка получения токена: \(error)")
            }
        }
    }
}
