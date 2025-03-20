import UIKit

final class SingleImageViewController: UIViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet var scrollView: UIScrollView!
    
    // MARK: - Public Properties
    
    var image: UIImage? {
        didSet {
            guard isViewLoaded, let image else { return }
            
            imageView.image = image
            imageView.frame.size = image.size
            updateZoomAndCenterImage(animated: false)
        }
    }
    
    // MARK: - Private Properties
    
    private func updateZoomAndCenterImage(animated: Bool) {
        guard let image = imageView.image else { return }
        
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        
        let scale = min(scrollView.maximumZoomScale, max(scrollView.minimumZoomScale, max(hScale, vScale)))
        
        if scrollView.zoomScale != scale {
            scrollView.setZoomScale(scale, animated: animated)
        }
        
        let contentSize = scrollView.contentSize
        let scrollViewSize = scrollView.bounds.size
        
        if contentSize.width > scrollViewSize.width {
            scrollView.contentOffset.x = (contentSize.width - scrollViewSize.width) / 2
        }
        
        if contentSize.height > scrollViewSize.height {
            scrollView.contentOffset.y = (contentSize.height - scrollViewSize.height) / 2
        }
    }
    
    private func centerScrollViewContents() {
        let contentSize = scrollView.contentSize
        let scrollViewSize = scrollView.bounds.size
        
        var horizontalInset: CGFloat = 0
        var verticalInset: CGFloat = 0
        
        if contentSize.width < scrollViewSize.width {
            horizontalInset = (scrollViewSize.width - contentSize.width) / 2
        }
        
        if contentSize.height < scrollViewSize.height {
            verticalInset = (scrollViewSize.height - contentSize.height) / 2
        }
        
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }
    
    // MARK: - Overrides Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        
        guard let image else { return }
        imageView.image = image
        imageView.frame.size = image.size
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateZoomAndCenterImage(animated: false)
    }
    
    // MARK: - IB Actions
    
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func didTapShareButton(_ sender: Any) {
        guard let image = imageView.image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true, completion: nil)
    }
}

// MARK: - UIScrollViewDelegate

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerScrollViewContents()
    }
}
