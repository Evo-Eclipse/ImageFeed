import UIKit

final class SplashViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let showAuthViewIdentifier = "AuthViewController"
    private let tabBarViewControllerIdentifier = "TabBarViewController"
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
        imageView.translatesAutoresizingMaskIntoConstraints = false
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
        view.addSubview(logoImageView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -36)
        ])
    }
    
    private func presentAuthViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let authViewController = storyboard.instantiateViewController(withIdentifier: showAuthViewIdentifier) as? AuthViewController else {
            assertionFailure("Failed to instantiate AuthViewController from Main storyboard")
            return
        }
        
        authViewController.delegate = self
        authViewController.modalPresentationStyle = .fullScreen
        
        present(authViewController, animated: true)
    }
    
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
