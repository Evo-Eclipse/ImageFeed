import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let profileLogoutService = ProfileLogoutService.shared
    private let profileStorage = ProfileStorage.shared
    private let profileImageStorage = ProfileImageStorage.shared
    private var profileImageServiceObserver: NSObjectProtocol?
    
    private lazy var profileImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon.user")
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 35
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var profileName: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.textColor = .ypWhite
        return label
    }()
    
    private lazy var profileLogin: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .ypWhiteAlpha50
        return label
    }()
    
    private lazy var profileDescription: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .ypWhite
        return label
    }()
    
    private lazy var logoutButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "button.logout"), for: .normal)
        return button
    }()
    
    // MARK: - Initializers
    
    deinit {
        if let observer = profileImageServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Overrides Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .ypBlack
        
        setupViews()
        setupConstraints()
        setupActions()
        
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.updateAvatar()
            }
        
        updateProfileDetails()
        updateAvatar()
    }
    
    // MARK: - Actions
    
    @objc private func logoutButtonTapped() {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Да", style: .default) { [weak self] _ in
            guard let self else { return }
            self.profileLogoutService.logout()
        })
        
        alert.addAction(UIAlertAction(title: "Нет", style: .default))
        
        alert.preferredAction = alert.actions.last
        
        present(alert, animated: true)
    }
    
    // MARK: - Private Methods
    
    private func setupViews() {
        [profileImage, profileName, profileLogin, profileDescription, logoutButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            profileImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            profileImage.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            profileImage.widthAnchor.constraint(equalToConstant: 70),
            profileImage.heightAnchor.constraint(equalToConstant: 70),
            
            profileName.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 8),
            profileName.leadingAnchor.constraint(equalTo: profileImage.leadingAnchor),
            profileName.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            profileLogin.topAnchor.constraint(equalTo: profileName.bottomAnchor, constant: 8),
            profileLogin.leadingAnchor.constraint(equalTo: profileName.leadingAnchor),
            profileLogin.trailingAnchor.constraint(equalTo: profileName.trailingAnchor),
            
            profileDescription.topAnchor.constraint(equalTo: profileLogin.bottomAnchor, constant: 8),
            profileDescription.leadingAnchor.constraint(equalTo: profileName.leadingAnchor),
            profileDescription.trailingAnchor.constraint(equalTo: profileName.trailingAnchor),
            
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            logoutButton.centerYAnchor.constraint(equalTo: profileImage.centerYAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupActions() {
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
    }
    
    private func updateProfileDetails() {
        guard let profile = profileStorage.profile else {
            return
        }
        
        profileName.text = profile.name
        profileLogin.text = profile.loginName
        profileDescription.text = profile.bio
    }
    
    private func updateAvatar() {
        guard let profileImage = profileImageStorage.profileImage,
              let url = URL(string: profileImage.medium) else {
            return
        }
        
        self.profileImage.kf.indicatorType = .activity
        self.profileImage.kf.setImage(
            with: url,
            placeholder: UIImage(named: "icon.user"),
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ]
        )
    }
}
