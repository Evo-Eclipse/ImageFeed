import UIKit

final class ProfileViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private let profileImage = UIImageView()
    private let profileName = UILabel()
    private let profileLogin = UILabel()
    private let profileDescription = UILabel()
    
    // MARK: - Overrides Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupProfileImage()
        setupProfileName()
        setupProfileLogin()
        setupProfileDescription()
        setupLogoutButton()
    }
    
    // MARK: - Private Methods
    
    private func setupProfileImage() {
        profileImage.image = UIImage(named: "icon.user")
        profileImage.contentMode = .scaleAspectFit
        profileImage.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(profileImage)
        
        NSLayoutConstraint.activate([
            profileImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            profileImage.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            
            profileImage.widthAnchor.constraint(equalToConstant: 70),
            profileImage.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private func setupProfileName() {
        profileName.text = "Екатерина Новикова"
        profileName.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        profileName.textColor = .ypWhite
        profileName.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(profileName)
        
        NSLayoutConstraint.activate([
            profileName.topAnchor.constraint(equalTo: profileImage.bottomAnchor, constant: 8),
            profileName.leadingAnchor.constraint(equalTo: profileImage.leadingAnchor),
            profileName.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupProfileLogin() {
        profileLogin.text = "@ekaterina_nov"
        profileLogin.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        profileLogin.textColor = .ypWhiteAlpha50
        profileLogin.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(profileLogin)
        
        NSLayoutConstraint.activate([
            profileLogin.topAnchor.constraint(equalTo: profileName.bottomAnchor, constant: 8),
            profileLogin.leadingAnchor.constraint(equalTo: profileName.leadingAnchor),
            profileLogin.trailingAnchor.constraint(equalTo: profileName.trailingAnchor)
        ])
    }
    
    private func setupProfileDescription() {
        profileDescription.text = "Hello, world!"
        profileDescription.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        profileDescription.textColor = .ypWhite
        profileDescription.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(profileDescription)
        
        NSLayoutConstraint.activate([
            profileDescription.topAnchor.constraint(equalTo: profileLogin.bottomAnchor, constant: 8),
            profileDescription.leadingAnchor.constraint(equalTo: profileName.leadingAnchor),
            profileDescription.trailingAnchor.constraint(equalTo: profileName.trailingAnchor)
        ])
    }
    
    private func setupLogoutButton() {
        let logoutButton = UIButton(type: .custom)
        logoutButton.setImage(UIImage(named: "button.logout"), for: .normal)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            logoutButton.centerYAnchor.constraint(equalTo: profileImage.centerYAnchor),
            
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}
