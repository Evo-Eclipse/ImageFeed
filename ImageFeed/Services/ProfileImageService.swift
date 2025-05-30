import UIKit

final class ProfileImageService {
    static let shared = ProfileImageService()
    private init() {}
    
    // MARK: - Public Properties
    
    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")
    
    // MARK: - Private Properties
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastToken: String?
    
    // MARK: - Structures
    
    struct UserResult: Decodable {
        let profileImage: ProfileImageURLs
        
        enum CodingKeys: String, CodingKey {
            case profileImage = "profile_image"
        }
        
        struct ProfileImageURLs: Codable {
            let small: String
            let medium: String
            let large: String
        }
    }
    
    // MARK: - Public Methods
    
    func fetchProfileImageURL(token: String, username: String, completion: @escaping (Result<ProfileImage, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        guard lastToken != token else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        task?.cancel()
        lastToken = token
        
        guard let request = makeUserRequest(token: token, username: username) else {
            print("[ProfileImageService.fetchProfileImageURL] Error: Failed to create profile image request")
            completion(.failure(NetworkError.invalidRequest))
            lastToken = nil
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            guard let self = self else { return }
            print("[ProfileImageService.fetchProfileImageURL] Network: Request completed")
            
            defer {
                self.task = nil
                self.lastToken = nil
            }
            
            switch result {
            case .success(let userResult):
                let profileImage = self.createProfileImage(from: userResult)
                completion(.success(profileImage))
                
                NotificationCenter.default.post(
                    name: ProfileImageService.didChangeNotification,
                    object: self,
                    userInfo: ["profileImageURLs": profileImage]
                )
                
            case .failure(let error):
                print("[ProfileImageService.fetchProfileImageURL]: Error - \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        self.task = task
        task.resume()
    }
    
    // MARK: - Network Methods
    
    private func makeUserRequest(token: String, username: String) -> URLRequest? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.unsplash.com"
        components.path = "/users/\(username)"
        
        guard let url = components.url else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    // MARK: - Private Methods
    
    private func createProfileImage(from result: UserResult) -> ProfileImage {
        return ProfileImage(
            small: result.profileImage.small,
            medium: result.profileImage.medium,
            large: result.profileImage.large
        )
    }
}
