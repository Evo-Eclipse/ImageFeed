import UIKit

final class SingleImageViewController: UIViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet private var imageView: UIImageView!
    
    // MARK: - Public Properties
    
    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            imageView.image = image
        }
    }
    
    // MARK: - Overrides Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
    }
    
    // MARK: - IB Actions
    
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
}
