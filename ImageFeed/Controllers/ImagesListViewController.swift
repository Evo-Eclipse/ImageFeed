import UIKit

final class ImagesListViewController: UIViewController {
    
    // MARK: - Private Properties
    
    private var photos: [Photo] = []
    private let imagesListService = ImagesListService.shared
    private var imagesListServiceObserver: NSObjectProtocol?
    private var imagesListServiceErrorObserver: NSObjectProtocol?
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Initializers
    
    deinit {
        if let observer = imagesListServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let errorObserver = imagesListServiceErrorObserver {
            NotificationCenter.default.removeObserver(errorObserver)
        }
    }
    
    // MARK: - Overrides Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .ypBlack
        
        setupViews()
        setupConstraints()
        
        imagesListServiceObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let self,
                let newPhotos = notification.userInfo?[ImagesListService.newPhotosUserInfoKey] as? [Photo]
            else { return }
            
            self.updateTableViewAnimated(with: newPhotos)
        }
        
        imagesListServiceErrorObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didFailToLoadPhotosNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            
            self.showPhotosLoadErrorAlert()
        }
        
        imagesListService.fetchPhotosNextPage()
    }
    
    // MARK: - Private Methods
    
    private func setupViews() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateTableViewAnimated(with newPhotos: [Photo]) {
        let startIndex = photos.count
        let newCount = newPhotos.count
        
        guard newCount > 0 else { return }
        
        if photos.isEmpty {
            photos = newPhotos
            tableView.reloadData()
        } else {
            let indexPaths = (startIndex..<(startIndex + newCount)).map { IndexPath(row: $0, section: 0) }
            
            tableView.performBatchUpdates {
                photos.append(contentsOf: newPhotos)
                tableView.insertRows(at: indexPaths, with: .automatic)
            }
        }
    }
    
    private func updatePhotoLikeStatus(_ updatedPhoto: Photo) {
        guard let index = photos.firstIndex(where: { $0.id == updatedPhoto.id }) else {
            return
        }
        
        photos[index] = updatedPhoto
        
        let indexPath = IndexPath(row: index, section: 0)
        
        if let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell {
            cell.setIsLiked(updatedPhoto.isLiked)
        }
    }
    
    private func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        let dateText: String
        
        if let createdAt = photo.createdAt {
            dateText = dateFormatter.string(from: createdAt)
        } else {
            dateText = ""
        }
        
        cell.configure(with: nil, date: dateText, isLiked: photo.isLiked, photoId: photo.id)
        cell.delegate = self
        
        cell.loadImage(from: photo.urls.small)
    }
    
    private func showPhotosLoadErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось загрузить фотографии",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true)
    }
    
    private func showLikeErrorAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось изменить статус лайка",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true)
    }
    
    private func showSingleImageViewController(with image: UIImage, fullImageURL: URL) {
        let viewController = SingleImageViewController()
        viewController.image = image
        viewController.fullImageURL = fullImageURL
        viewController.modalPresentationStyle = .fullScreen
        viewController.modalTransitionStyle = .crossDissolve
        present(viewController, animated: true)
    }
}

// MARK: - UITableViewDelegate

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < photos.count else { return }
        
        let photo = photos[indexPath.row]
        
        if let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell, let image = cell.getImage() {
            showSingleImageViewController(with: image, fullImageURL: photo.urls.full)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < photos.count else { return 0 }
        
        let photo = photos[indexPath.row]
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        
        let tableViewWidth = tableView.bounds.width - (imageInsets.left + imageInsets.right)
        let imageAspectRatio = CGFloat(photo.size.height / photo.size.width)
        let imageViewHeight = tableViewWidth * imageAspectRatio
        
        let cellHeight = imageViewHeight + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }
}

// MARK: - UITableViewDataSource

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
}

// MARK: - ImagesListCellDelegate

extension ImagesListViewController: ImagesListCellDelegate {
    func imagesListCell(_ cell: ImagesListCell, didTapLikeButton photoId: String, isLiked: Bool) {
        UIBlockingProgressHUD.show()
        
        imagesListService.changeLikeStatus(photoId: photoId, isLike: !isLiked) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self = self else { return }
            
            switch result {
            case .success(let updatedPhoto):
                self.updatePhotoLikeStatus(updatedPhoto)
            case .failure:
                self.showLikeErrorAlert()
            }
        }
    }
}
