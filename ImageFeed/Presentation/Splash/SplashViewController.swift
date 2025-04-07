import UIKit

final class SplashViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let showAuthSegueIdentifier = "ShowAuth"
    private let tabBarViewControllerIdentifier = "TabBarViewController"
    private let oauth2Service = OAuth2Service.shared
    private let oauth2Storage = OAuth2Storage.shared
    private let profileService = ProfileService.shared
    private let profileStorage = ProfileStorage.shared
    private let profileImageService = ProfileImageService.shared
    private let profileImageStorage = ProfileImageStorage.shared
    
    // MARK: - Overrides Methods
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let token = oauth2Storage.token {
            // Проверяем наличие и свежесть данных профиля
            let needsProfileData = profileStorage.profile == nil || profileStorage.isExpired
            let needsProfileImage = profileImageStorage.profileImage == nil || profileImageStorage.isExpired
            
            if !needsProfileData && !needsProfileImage {
                // У нас уже есть актуальные данные
                switchToTabBarViewController()
            } else {
                // Нужно обновить данные
                fetchProfile(token: token)
            }
        } else {
            // Нет токена - нужно авторизоваться
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
    
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] profileResult in
            guard let self = self else { return }
            
            switch profileResult {
            case .success(let profile):
                self.profileStorage.profile = profile
                self.fetchProfileImage(token: token, username: profile.username)
                
            case .failure(_):
                UIBlockingProgressHUD.dismiss()
                self.showProfileErrorAlert()
            }
        }
    }
    
    private func fetchProfileImage(token: String, username: String) {
        profileImageService.fetchProfileImageURL(token: token, username: username) { [weak self] imageResult in
            UIBlockingProgressHUD.dismiss()
            guard let self = self else { return }
            
            switch imageResult {
            case .success(let profileImage):
                self.profileImageStorage.profileImage = profileImage
                self.switchToTabBarViewController()
                
            case .failure(_):
                self.showProfileErrorAlert()
            }
        }
    }
    
    private func switchToTabBarViewController() {
        guard let window = UIApplication.shared.windows.first else {
            fatalError("Invalid configuration, no main window found")
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
    
    private func showProfileErrorAlert() {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Не удалось загрузить данные профиля",
            preferredStyle: .alert
        )
        
        let retryAction = UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            guard let token = self?.oauth2Storage.token else { return }
            self?.fetchProfile(token: token)
        }
        
        alert.addAction(retryAction)
        
        present(alert, animated: true)
    }
}

// MARK: - AuthViewControllerDelegate

extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ viewController: AuthViewController, didAuthenticateWithCode code: String) {
        UIBlockingProgressHUD.show()
        
        oauth2Service.fetchOAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            UIBlockingProgressHUD.dismiss()
            
            switch result {
            case .success(let token):
                self.oauth2Storage.token = token
                self.fetchProfile(token: token)
            case .failure(_):
                viewController.showAuthErrorAlert()
            }
        }
    }
}
