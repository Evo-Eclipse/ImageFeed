import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    
    // MARK: - Public Properties
    
    var fullImageURL: URL?
    
    var image: UIImage? {
        didSet {
            guard isViewLoaded, let image else { return }
            
            // Reset zoom scale to default and set image
            scrollView.zoomScale = 1.0
            imageView.image = image
            
            // Set image view frame to image size
            imageView.frame = CGRect(origin: .zero, size: image.size)
            scrollView.contentSize = image.size
            
            adjustImageScale(animated: false)
        }
    }
    
    // MARK: - Private Properties
    
    private var isFullImageLoaded = false
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "button.backward.white"), for: .normal)
        return button
    }()
    
    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "button.sharing"), for: .normal)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .ypBlack
        
        setupViews()
        setupConstraints()
        setupActions()
        
        if let image = image {
            imageView.image = image
            imageView.frame = CGRect(origin: .zero, size: image.size)
            scrollView.contentSize = image.size
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        adjustImageScale(animated: false)
        
        if !isFullImageLoaded {
            loadFullImage()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustImageScale(animated: false)
    }
    
    // MARK: - Actions
    
    @objc private func didTapBackButton() {
        dismiss(animated: true)
    }
    
    @objc private func didTapShareButton() {
        guard let image = imageView.image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true)
    }
    
    // MARK: - Private Methods
    
    private func setupViews() {
        [scrollView, backButton, shareButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            shareButton.widthAnchor.constraint(equalToConstant: 50),
            shareButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(didTapShareButton), for: .touchUpInside)
    }
    
    private func loadFullImage() {
        guard let fullImageURL = fullImageURL else { return }
        
        UIBlockingProgressHUD.show()
        
        imageView.kf.setImage(
            with: fullImageURL,
            placeholder: imageView.image,
            options: [.transition(.fade(0.2)), .cacheOriginalImage],
            completionHandler: { [weak self] result in
                UIBlockingProgressHUD.dismiss()
                guard let self = self else { return }
                
                switch result {
                case .success(let imageResult):
                    self.isFullImageLoaded = true
                    self.image = imageResult.image
                case .failure:
                    self.showErrorAlert()
                }
            }
        )
    }
    
    private func adjustImageScale(animated: Bool) {
        guard let image = imageView.image else { return }
        
        let visibleRect = scrollView.bounds.size
        let imageSize = image.size
        
        let hScale = visibleRect.width / imageSize.width
        let vScale = visibleRect.height / imageSize.height
        let scale = min(scrollView.maximumZoomScale, max(scrollView.minimumZoomScale, max(hScale, vScale)))
        
        if scrollView.zoomScale != scale {
            scrollView.setZoomScale(scale, animated: animated)
        }
        
        if !animated {
            updateContentInsets()
            centerInitialContent()
        }
    }
    
    private func updateContentInsets() {
        let contentSize = scrollView.contentSize
        let boundsSize = scrollView.bounds.size
        
        let horizontalInset = max(0, (boundsSize.width - contentSize.width) / 2)
        let verticalInset = max(0, (boundsSize.height - contentSize.height) / 2)
        
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }
    
    private func centerInitialContent() {
        let contentSize = scrollView.contentSize
        let boundsSize = scrollView.bounds.size
        
        if contentSize.width > boundsSize.width {
            scrollView.contentOffset.x = (contentSize.width - boundsSize.width) / 2
        }
        
        if contentSize.height > boundsSize.height {
            scrollView.contentOffset.y = (contentSize.height - boundsSize.height) / 2
        }
    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Попробовать ещё раз?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.loadFullImage()
        })
        
        alert.addAction(UIAlertAction(title: "Не надо", style: .default))
        alert.preferredAction = alert.actions.first
        
        present(alert, animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateContentInsets()
    }
}
