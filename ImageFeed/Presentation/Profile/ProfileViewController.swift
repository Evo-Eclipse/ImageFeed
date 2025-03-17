import UIKit

final class ProfileViewController: UIViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet private var userIconImage: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var loginNameLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var logoutButton: UIButton!
    
    // MARK: - IB Actions
    
    @IBAction private func didTapLogoutButton(_ sender: Any) {
    }
}
