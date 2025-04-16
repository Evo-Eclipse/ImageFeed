import UIKit

final class SplashViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let oauth2Service = OAuth2Service.shared
    private let oauth2Storage = OAuth2Storage.shared
    private let profileService = ProfileService.shared
    private let profileStorage = ProfileStorage.shared
    private let profileImageService = ProfileImageService.shared
    private let profileImageStorage = ProfileImageStorage.shared
    
    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo.launch.screen")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    // MARK: - Overrides Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .ypBlack
        
        setupViews()
        setupConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let token = oauth2Storage.token {
            // Check profile data existence and freshness
            let needsProfileData = profileStorage.profile == nil || profileStorage.isExpired
            let needsProfileImage = profileImageStorage.profileImage == nil || profileImageStorage.isExpired
            
            if !needsProfileData && !needsProfileImage {
                // We already have up-to-date data
                switchToTabBarViewController()
            } else {
                // We need to update the data
                fetchProfile(token: token)
            }
        } else {
            // No token - need to authorize
            presentAuthViewController()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupViews() {
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -36)
        ])
    }
    
    private func presentAuthViewController() {
        let authViewController = AuthViewController()
        authViewController.delegate = self
        
        let navigationController = UINavigationController(rootViewController: authViewController)
        navigationController.modalPresentationStyle = .fullScreen
        
        present(navigationController, animated: true)
    }
    
    private func fetchProfile(token: String) {
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] profileResult in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }
            
            switch profileResult {
            case .success(let profile):
                self.profileStorage.profile = profile
                self.fetchProfileImage(token: token, username: profile.username)
                
            case .failure:
                self.showProfileErrorAlert()
            }
        }
    }
    
    private func fetchProfileImage(token: String, username: String) {
        UIBlockingProgressHUD.show()
        
        profileImageService.fetchProfileImageURL(token: token, username: username) { [weak self] imageResult in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }
            
            switch imageResult {
            case .success(let profileImage):
                self.profileImageStorage.profileImage = profileImage
                self.switchToTabBarViewController()
                
            case .failure:
                self.showProfileErrorAlert()
            }
        }
    }
    
    private func switchToTabBarViewController() {
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid configuration, no main window found")
            return
        }
        
        let tabBarViewController = TabBarViewController()
        
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
            title: "Что-то пошло не так(",
            message: "Не удалось получить профиль",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            guard let token = self?.oauth2Storage.token else { return }
            self?.fetchProfile(token: token)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - AuthViewControllerDelegate

extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ viewController: AuthViewController, didAuthenticateWithCode code: String) {
        UIBlockingProgressHUD.show()
        
        oauth2Service.fetchOAuthToken(code) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self else { return }
            
            switch result {
            case .success(let token):
                self.oauth2Storage.token = token
                self.fetchProfile(token: token)
            case .failure:
                viewController.showAuthErrorAlert()
            }
        }
    }
}
