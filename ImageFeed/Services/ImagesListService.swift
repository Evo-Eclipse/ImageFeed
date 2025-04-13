import Foundation

final class ImagesListService {
    static let shared = ImagesListService()
    private init() {}
    
    // MARK: - Public Properties
    
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    static let newPhotosUserInfoKey = "newPhotos"
    
    static let didChangeLikeStatusNotification = Notification.Name("ImagesListServiceDidChangeLikeStatus")
    static let likedPhotoUserInfoKey = "likedPhoto"
    
    // MARK: - Private Properties
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastLoadedPage = 0
    private let token = OAuth2Storage.shared.token
    
    // Adaptive pagination parameters
    
    private var itemsPerPage = 10
    private var requestDurations: [TimeInterval] = []
    private let requestHistoryLimit = 5
    private let targetRequestDuration: TimeInterval = 0.5
    private let minItemsPerPage = 10
    private let maxItemsPerPage = 100 // API Maximum seems to be 30
    private let sensitivityFactor = 5.0
    
    //    private var averageRequestDuration: TimeInterval = 0
    //    private let smoothingFactor: Double = 0.2
    //    private var requestCount: Int = 0
    
    // MARK: - Structures
    
    struct PhotoResult: Decodable {
        let id: String
        let createdAt: String
        let width: Int
        let height: Int
        let color: String
        let likes: Int
        let likedByUser: Bool?
        let description: String?
        let urls: PhotoURLs
        
        enum CodingKeys: String, CodingKey {
            case id
            case createdAt = "created_at"
            case width
            case height
            case color
            case likes
            case likedByUser = "liked_by_user"
            case description
            case urls
        }
        
        struct PhotoURLs: Decodable {
            let raw: String
            let full: String
            let regular: String
            let small: String
            let thumb: String
        }
    }
    
    struct LikePhotoResult: Decodable {
        let photo: PhotoResult
    }
    
    // MARK: - Public Methods
    
    func fetchPhotosNextPage() {
        assert(Thread.isMainThread)
        
        guard task == nil else { return }
        
        guard let token else {
            print("[ImagesListService.fetchPhotosNextPage] Error: No token available")
            return
        }
        
        let nextPage = lastLoadedPage + 1
        let startTime = Date()
        
        guard let request = makePhotoRequest(token: token, page: nextPage, perPage: itemsPerPage) else {
            print("[ImagesListService.fetchPhotosNextPage] Error: Failed to create photo request")
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }
            print("[ImagesListService.fetchPhotosNextPage] Network: Request completed")
            
            let requestDuration = Date().timeIntervalSince(startTime)
            self.adaptRequestSize(requestDuration: requestDuration)
            
            defer {
                self.task = nil
            }
            
            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.compactMap { self.createPhoto(from: $0) }
                
                self.lastLoadedPage = nextPage
                
                NotificationCenter.default.post(
                    name: ImagesListService.didChangeNotification,
                    object: self,
                    userInfo: [ImagesListService.newPhotosUserInfoKey: newPhotos]
                )
                
            case .failure(let error):
                print("[ImagesListService.fetchPhotosNextPage]: Error - \(error.localizedDescription)")
            }
        }
        
        self.task = task
        task.resume()
    }
    
    func changeLikeStatus(photoId: String, isLike: Bool) {
        assert(Thread.isMainThread)
        
        guard let token = token else {
            print("[ImagesListService.changeLikeStatus] Error: No token available")
            return
        }
        
        guard let request = makeLikeRequest(token: token, photoId: photoId, isLike: isLike) else {
            print("[ImagesListService.changeLikeStatus] Error: Failed to create like request")
            return
        }
        
        let likeTask = urlSession.objectTask(for: request) { [weak self] (result: Result<LikePhotoResult, Error>) in
            guard let self = self else { return }
            print("[ImagesListService.changeLikeStatus] Network: Request completed")
            
            switch result {
            case .success(let likeResult):
                if let photo = self.createPhoto(from: likeResult.photo) {
                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeLikeStatusNotification,
                        object: self,
                        userInfo: [ImagesListService.likedPhotoUserInfoKey: photo]
                    )
                }
                
            case .failure(let error):
                print("[ImagesListService.changeLikeStatus]: Error - \(error.localizedDescription)")
            }
        }
        
        likeTask.resume()
    }
    
    // MARK: - Network Methods
    
    private func makePhotoRequest(token: String, page: Int, perPage: Int) -> URLRequest? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.unsplash.com"
        components.path = "/photos"
        
        components.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]
        
        guard let url = components.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    private func makeLikeRequest(token: String, photoId: String, isLike: Bool) -> URLRequest? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.unsplash.com"
        components.path = "/photos/\(photoId)/like"
        
        guard let url = components.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    // MARK: - Private Methods
    
    private func adaptRequestSize(requestDuration: TimeInterval) {
        if requestDurations.count >= requestHistoryLimit {
            requestDurations.removeFirst()
        }
        requestDurations.append(requestDuration)
        
        guard !requestDurations.isEmpty else { return }
        
        let averageDuration = requestDurations.reduce(0, +) / Double(requestDurations.count)
        let deviationRatio = targetRequestDuration / averageDuration
        
        let adjustmentFactor = sqrt(abs(deviationRatio)) * sensitivityFactor
        
        if deviationRatio > 1.0 {
            itemsPerPage = min(maxItemsPerPage, Int(Double(itemsPerPage) * adjustmentFactor))
            print("[ImagesListService] Increasing per_page to \(itemsPerPage) due to fast requests (avg \(averageDuration)s)")
        } else {
            itemsPerPage = max(minItemsPerPage, Int(Double(itemsPerPage) / adjustmentFactor))
            print("[ImagesListService] Decreasing per_page to \(itemsPerPage) due to slow requests (avg \(averageDuration)s)")
        }
    }
    
    /*
     private func adaptRequestSize(requestDuration: TimeInterval) {
     requestCount += 1
     if requestCount == 1 {
     averageRequestDuration = requestDuration
     return
     }
     
     // newAvg = α × currentValue + (1 - α) × previousAvg
     averageRequestDuration = smoothingFactor * requestDuration + (1 - smoothingFactor) * averageRequestDuration
     
     let deviationRatio = targetRequestDuration / averageRequestDuration
     let adjustmentFactor = sqrt(abs(deviationRatio)) * sensitivityFactor
     let previousItemsPerPage = itemsPerPage
     
     if deviationRatio > 1.0 {
     itemsPerPage = min(maxItemsPerPage, Int(Double(itemsPerPage) * adjustmentFactor))
     print("[ImagesListService] Decreasing per_page to \(itemsPerPage) due to slow requests (avg \(averageDuration)s)")
     }
     } else {
     itemsPerPage = max(minItemsPerPage, Int(Double(itemsPerPage) / adjustmentFactor))
     print("[ImagesListService] Increasing per_page to \(itemsPerPage) due to fast requests (avg \(averageDuration)s)")
     }
     }
     */
    
    private func createPhoto(from result: PhotoResult) -> Photo? {
        guard let createdAt = Photo.dateFormatter.date(from: result.createdAt) else {
            assertionFailure("Invalid date format")
            return nil
        }
        
        guard
            let smallURL = URL(string: result.urls.small),
            let regularURL = URL(string: result.urls.regular),
            let fullURL = URL(string: result.urls.full)
        else {
            assertionFailure("Invalid URL format")
            return nil
        }
        
        return Photo(
            id: result.id,
            createdAt: createdAt,
            size: CGSize(width: result.width, height: result.height),
            color: result.color,
            isLiked: result.likedByUser ?? false,
            description: result.description ?? "",
            urls: Photo.PhotoURLs(
                small: smallURL,
                regular: regularURL,
                full: fullURL
            )
        )
    }
}
