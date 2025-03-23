import UIKit

final class ProfileViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let profileImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon.user")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let profileName: UILabel = {
        let label = UILabel()
        label.text = "Екатерина Новикова"
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.textColor = .ypWhite
        return label
    }()
    
    private let profileLogin: UILabel = {
        let label = UILabel()
        label.text = "@ekaterina_nov"
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .ypWhiteAlpha50
        return label
    }()
    
    private let profileDescription: UILabel = {
        let label = UILabel()
        label.text = "Hello, world!"
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .ypWhite
        return label
    }()
    
    private let logoutButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "button.logout"), for: .normal)
        return button
    }()
    
    // MARK: - Overrides Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupConstraints()
    }
    
    // MARK: - Actions
    
    @objc private func logoutButtonTapped() {
        print("Logout button tapped")
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
}
