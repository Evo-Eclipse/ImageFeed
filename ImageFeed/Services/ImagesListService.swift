import Foundation

final class ImagesListService {
    static let shared = ImagesListService()
    private init() {}
    
    // MARK: - Public Properties
    
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    static let newPhotosUserInfoKey = "newPhotos"
    static let didFailToLoadPhotosNotification = Notification.Name("ImagesListServiceFailedToLoad")
    static let errorUserInfoKey = "error"
    
    // MARK: - Private Properties
    
    private let urlSession = URLSession.shared
    private let photoCacheService = PhotoCacheService.shared
    private var task: URLSessionTask?
    private var lastLoadedPage = 0
    private let token = OAuth2Storage.shared.token
    
    private let itemsPerPage = 20
    private var isInitialLoadCompleted = false
    
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
        
        if !isInitialLoadCompleted {
            performInitialLoad()
        } else {
            loadNextPage()
        }
    }
    
    func changeLikeStatus(photoId: String, isLike: Bool, completion: @escaping (Result<Photo, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        guard let token = token else {
            print("[ImagesListService.changeLikeStatus] Error: No token available")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        guard let request = makeLikeRequest(token: token, photoId: photoId, isLike: isLike) else {
            print("[ImagesListService.changeLikeStatus] Error: Failed to create like request")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        let likeTask = urlSession.objectTask(for: request) { [weak self] (result: Result<LikePhotoResult, Error>) in
            guard let self = self else { return }
            print("[ImagesListService.changeLikeStatus] Network: Request completed")
            
            switch result {
            case .success(let likeResult):
                if let photo = self.createPhoto(from: likeResult.photo) {
                    self.photoCacheService.updatePhotoLikeStatus(photoId: photoId, isLiked: photo.isLiked)
                    completion(.success(photo))
                } else {
                    completion(.failure(NetworkError.decodingError(NSError(domain: "ImagesListService", code: -1))))
                }
                
            case .failure(let error):
                print("[ImagesListService.changeLikeStatus]: Error - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        likeTask.resume()
    }
    
    func reset() {
        task?.cancel()
        task = nil
        lastLoadedPage = 0
        isInitialLoadCompleted = false
    }
    
    func clearCache() {
        photoCacheService.clearCache()
        reset()
    }
    
    // MARK: - Private Methods
    
    private func performInitialLoad() {
        if photoCacheService.needsCacheRefresh() {
            print("[ImagesListService] Cache needs refresh, checking for new photos")
            checkForNewPhotosAndUpdate()
        } else {
            print("[ImagesListService] Cache is valid, loading from cache")
            loadFromCache()
        }
    }
    
    private func loadFromCache() {
        let cachedPhotos = photoCacheService.fetchAllCachedPhotos()
        
        if !cachedPhotos.isEmpty {
            let totalCached = photoCacheService.getCachedPhotosCount()
            lastLoadedPage = (totalCached - 1) / itemsPerPage + 1
            isInitialLoadCompleted = true
            
            NotificationCenter.default.post(
                name: ImagesListService.didChangeNotification,
                object: self,
                userInfo: [ImagesListService.newPhotosUserInfoKey: cachedPhotos]
            )
        } else {
            checkForNewPhotosAndUpdate()
        }
    }
    
    private func checkForNewPhotosAndUpdate() {
        guard let token = token else {
            print("[ImagesListService.checkForNewPhotosAndUpdate] Error: No token available")
            postFailureNotification()
            return
        }
        
        guard let request = makePhotoRequest(token: token, page: 1, perPage: itemsPerPage) else {
            print("[ImagesListService.checkForNewPhotosAndUpdate] Error: Failed to create photo request")
            postFailureNotification()
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }
            print("[ImagesListService.checkForNewPhotosAndUpdate] Network: Request completed for page 1")
            
            defer {
                self.task = nil
            }
            
            switch result {
            case .success(let photoResults):
                let newFirstPagePhotos = photoResults.compactMap { self.createPhoto(from: $0) }
                self.handleFirstPagePhotos(newFirstPagePhotos)
                
            case .failure(let error):
                print("[ImagesListService.checkForNewPhotosAndUpdate]: Error - \(error.localizedDescription)")
                self.postFailureNotification()
            }
        }
        
        self.task = task
        task.resume()
    }
    
    private func handleFirstPagePhotos(_ newFirstPagePhotos: [Photo]) {
        let cachedPhotos = photoCacheService.fetchAllCachedPhotos()
        
        if cachedPhotos.isEmpty {
            print("[ImagesListService] No cache, saving first page")
            photoCacheService.savePhotos(newFirstPagePhotos, startingFromPosition: 0)
            lastLoadedPage = 1
            isInitialLoadCompleted = true
            
            NotificationCenter.default.post(
                name: ImagesListService.didChangeNotification,
                object: self,
                userInfo: [ImagesListService.newPhotosUserInfoKey: newFirstPagePhotos]
            )
            return
        }
        
        let cachedPhotoIds = Set(cachedPhotos.map { $0.id })
        let newPhotosList = newFirstPagePhotos.filter { !cachedPhotoIds.contains($0.id) }
        
        if newPhotosList.isEmpty {
            print("[ImagesListService] No new photos detected, using cache")
            lastLoadedPage = (cachedPhotos.count - 1) / itemsPerPage + 1
            isInitialLoadCompleted = true
            
            NotificationCenter.default.post(
                name: ImagesListService.didChangeNotification,
                object: self,
                userInfo: [ImagesListService.newPhotosUserInfoKey: cachedPhotos]
            )
        } else {
            print("[ImagesListService] Found \(newPhotosList.count) new photos, updating cache")
            
            let newPhotosCount = newPhotosList.count
            
            photoCacheService.shiftCachedPhotosPositions(by: newPhotosCount)
            photoCacheService.savePhotos(newPhotosList, startingFromPosition: 0)
            
            let updatedCachedPhotos = photoCacheService.fetchAllCachedPhotos()
            
            lastLoadedPage = (updatedCachedPhotos.count - 1) / itemsPerPage + 1
            isInitialLoadCompleted = true
            
            NotificationCenter.default.post(
                name: ImagesListService.didChangeNotification,
                object: self,
                userInfo: [ImagesListService.newPhotosUserInfoKey: updatedCachedPhotos]
            )
        }
    }
    
    private func loadNextPage() {
        guard let token = token else {
            print("[ImagesListService.loadNextPage] Error: No token available")
            postFailureNotification()
            return
        }
        
        let nextPage = lastLoadedPage + 1
        let startPosition = (nextPage - 1) * itemsPerPage
        
        let cachedPagePhotos = photoCacheService.getCachedPhotos(from: startPosition, count: itemsPerPage)
        if !cachedPagePhotos.isEmpty {
            lastLoadedPage = nextPage
            
            NotificationCenter.default.post(
                name: ImagesListService.didChangeNotification,
                object: self,
                userInfo: [ImagesListService.newPhotosUserInfoKey: cachedPagePhotos]
            )
            return
        }
        
        guard let request = makePhotoRequest(token: token, page: nextPage, perPage: itemsPerPage) else {
            print("[ImagesListService.loadNextPage] Error: Failed to create photo request")
            postFailureNotification()
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }
            print("[ImagesListService.loadNextPage] Network: Request completed for page \(nextPage)")
            
            defer {
                self.task = nil
            }
            
            switch result {
            case .success(let photoResults):
                let newPhotos = photoResults.compactMap { self.createPhoto(from: $0) }
                
                self.photoCacheService.savePhotos(newPhotos, startingFromPosition: startPosition)
                
                self.lastLoadedPage = nextPage
                
                NotificationCenter.default.post(
                    name: ImagesListService.didChangeNotification,
                    object: self,
                    userInfo: [ImagesListService.newPhotosUserInfoKey: newPhotos]
                )
                
            case .failure(let error):
                print("[ImagesListService.loadNextPage]: Error - \(error.localizedDescription)")
                self.postFailureNotification()
            }
        }
        
        self.task = task
        task.resume()
    }
    
    private func postFailureNotification() {
        NotificationCenter.default.post(
            name: ImagesListService.didFailToLoadPhotosNotification,
            object: self,
            userInfo: [ImagesListService.errorUserInfoKey: "Failed to load photos"]
        )
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
    
    private func createPhoto(from result: PhotoResult) -> Photo? {
        guard
            let smallURL = URL(string: result.urls.small),
            let regularURL = URL(string: result.urls.regular),
            let fullURL = URL(string: result.urls.full)
        else {
            assertionFailure("Invalid URL format")
            return nil
        }
        
        let createdAt = Photo.dateFormatter.date(from: result.createdAt)
        
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
