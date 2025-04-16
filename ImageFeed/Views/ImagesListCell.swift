import UIKit
import Kingfisher

protocol ImagesListCellDelegate: AnyObject {
    func imagesListCell(_ cell: ImagesListCell, didTapLikeButton photoId: String, isLiked: Bool)
}

final class ImagesListCell: UITableViewCell {
    
    // MARK: - Public Properties
    
    static let reuseIdentifier = "ImagesListCell"
    weak var delegate: ImagesListCellDelegate?
    
    // MARK: - Private Properties
    
    private var currentImageURL: URL?
    private var photoId: String?
    private var isLiked: Bool = false
    
    private lazy var cellImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var gradientView: GradientView = {
        let view = GradientView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var likeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "button.like.inactive"), for: .normal)
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .ypWhite
        return label
    }()
    
    // MARK: - Initializers
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides Methods
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        cellImageView.kf.cancelDownloadTask()
        
        cellImageView.image = nil
        dateLabel.text = nil
        photoId = nil
    }
    
    // MARK: - Actions
    
    @objc private func likeButtonTapped() {
        guard let photoId = photoId else { return }
        delegate?.imagesListCell(self, didTapLikeButton: photoId, isLiked: isLiked)
    }
    
    // MARK: - Public Methods
    
    func configure(with image: UIImage?, date: String, isLiked: Bool, photoId: String) {
        if let image = image {
            cellImageView.image = image
        }
        
        self.photoId = photoId
        self.isLiked = isLiked
        dateLabel.text = date
        
        updateLikeButtonImage()
    }
    
    func loadImage(from url: URL) {
        cellImageView.kf.cancelDownloadTask()
        currentImageURL = url
        
        cellImageView.kf.indicatorType = .activity
        cellImageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "placeholder.feed"),
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ]
        )  { [weak self] result in
            guard let self = self, self.currentImageURL == url else {
                print("[ImagesListCell] Duplicate image load: \(url.absoluteString)")
                return
            }
            
            switch result {
            case .success:
                break
            case .failure(let error):
                print("[ImagesListCell] Error loading image: \(error.localizedDescription)")
            }
        }
    }
    
    func getImage() -> UIImage? {
        return cellImageView.image
    }
    
    func setIsLiked(_ isLiked: Bool) {
        self.isLiked = isLiked
        updateLikeButtonImage()
    }
    
    // MARK: - Private Methods
    
    private func setupViews() {
        backgroundColor = .clear
        selectionStyle = .none
        
        [cellImageView, gradientView, likeButton, dateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        // likeButton.accessibilityIdentifier = "Like" For some reason this is not working
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cellImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cellImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cellImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cellImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            gradientView.leadingAnchor.constraint(equalTo: cellImageView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: cellImageView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: cellImageView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 30),
            
            likeButton.topAnchor.constraint(equalTo: cellImageView.topAnchor),
            likeButton.trailingAnchor.constraint(equalTo: cellImageView.trailingAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 44),
            likeButton.heightAnchor.constraint(equalToConstant: 44),
            
            dateLabel.leadingAnchor.constraint(equalTo: cellImageView.leadingAnchor, constant: 8),
            dateLabel.bottomAnchor.constraint(equalTo: cellImageView.bottomAnchor, constant: -8),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: cellImageView.trailingAnchor, constant: -8)
        ])
    }
    
    private func updateLikeButtonImage() {
        let likeImage = isLiked ? UIImage(named: "button.like.active") : UIImage(named: "button.like.inactive")
        likeButton.accessibilityIdentifier = isLiked ? "Unlike" : "Like"
        likeButton.setImage(likeImage, for: .normal)
    }
}
