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
            print("[ProfileService.fetchProfile] Error: Failed to create profile request")
            completion(.failure(NetworkError.invalidRequest))
            lastToken = nil
            return
        }
        
        let task = urlSession.data(for: request) { [weak self] result in
            guard let self = self else { return }
            
            defer {
                self.task = nil
                self.lastToken = nil
            }
            
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let userResult = try decoder.decode(UserResult.self, from: data)
                    
                    let profileImage = self.createProfileImage(from: userResult)
                    completion(.success(profileImage))
                    
                    NotificationCenter.default.post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["profileImageURLs": profileImage]
                    )
                    
                } catch {
                    print("[ProfileService.fetchProfile] Error: Failed to decode profile response - \(error)")
                    completion(.failure(NetworkError.decodingError(error)))
                }
                
            case .failure(let error):
                print("[ProfileService.fetchProfile] Error: Network error while fetching profile - \(error)")
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
    
    private func createProfileImage(from userResult: UserResult) -> ProfileImage {
        return ProfileImage(
            small: userResult.profileImage.small,
            medium: userResult.profileImage.medium,
            large: userResult.profileImage.large
        )
    }
}
